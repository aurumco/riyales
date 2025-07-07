import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:web_smooth_scroll/web_smooth_scroll.dart';

import '../../models/asset_models.dart' as models;
import '../../providers/locale_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/alert_provider.dart';
import '../../providers/card_corner_settings_provider.dart';
import '../../localization/l10n_utils.dart';
import '../../services/connection_service.dart';
import '../../services/action_handler.dart';
import './asset_card.dart';
import './common/animated_card_builder.dart';
import './common/error_placeholder.dart';
import './common/alert_card.dart';
import './search/shimmering_search_field.dart';
import '../../config/app_config.dart'; // For AppConfig access
// import '../../providers/data_providers/crypto_data_provider.dart'; // Removed unused import

enum AssetType { currency, gold, crypto, stock }

enum SortMode { defaultOrder, highestPrice, lowestPrice }

class AssetListPage<T extends models.Asset> extends StatefulWidget {
  final AssetType assetType;
  final List<T> items;
  final List<T> fullItemsListForSearch;
  final bool isLoading;
  final String? error;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final Future<void> Function() onInitialize;
  final double topPadding;
  final bool showSearchBar;
  final bool isSearchActive; // This is from parent (HomeScreen)
  final TabController? tabController;
  final bool useCardAnimation;

  const AssetListPage({
    super.key,
    required this.assetType,
    required this.items,
    required this.fullItemsListForSearch,
    required this.isLoading,
    this.error,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onInitialize,
    this.topPadding = 0.0,
    this.showSearchBar = false,
    this.isSearchActive = false, // Default value
    this.tabController,
    this.useCardAnimation = true,
  });

  @override
  AssetListPageState<T> createState() => AssetListPageState<T>();
}

class AssetListPageState<T extends models.Asset>
    extends State<AssetListPage<T>> {
  final ScrollController _scrollController = ScrollController();
  Timer? _errorRetryTimer;

  int _lastFullDataLength = 0;
  SortMode _sortMode = SortMode.defaultOrder;
  List<String>? _searchableStrings;
  String _lastSearchQuery = '';

  // Internal flag to manage if search filtering logic is active.
  // widget.isSearchActive is from parent and controls UI elements like search bar visibility.
  bool _internalIsSearchActive = false;

  List<T> _fullSearchResults = [];
  List<T> _paginatedSearchResults = [];
  bool _isLoadingMoreSearchResults = false;

  List<T> _sortedWidgetItems = [];
  FavoritesNotifier? _favoritesNotifierCache;
  bool _didInitialFill = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _favoritesNotifierCache = Provider.of<FavoritesNotifier>(context, listen: false);
        if (widget.items.isEmpty && !widget.isSearchActive) {
          widget.onInitialize();
        } else {
          _sortedWidgetItems = _sortList(List<T>.from(widget.items));
           if (mounted) setState(() {});
        }
      }
    });
  }

  List<T> _sortList(List<T> listToSort) {
    if (_favoritesNotifierCache == null && mounted) {
      _favoritesNotifierCache = Provider.of<FavoritesNotifier>(context, listen: false);
    }
    if (_favoritesNotifierCache == null) {
      return List<T>.from(listToSort);
    }

    final favorites = _favoritesNotifierCache!.favorites;
    List<T> sortedList;

    switch (_sortMode) {
      case SortMode.highestPrice:
        sortedList = List<T>.from(listToSort)
          ..sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortMode.lowestPrice:
        sortedList = List<T>.from(listToSort)
          ..sort((a, b) => a.price.compareTo(b.price));
        break;
      default:
        final favoriteItems = listToSort
            .where((item) => favorites.contains(item.id))
            .toList();
        final nonFavoriteItems = listToSort
            .where((item) => !favorites.contains(item.id))
            .toList();
        sortedList = [...favoriteItems, ...nonFavoriteItems];
    }
    return sortedList;
  }

  @override
  void didUpdateWidget(covariant AssetListPage<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentSearchQuery = Provider.of<SearchQueryNotifier>(context, listen: false).query;
    bool needsStateUpdate = false;

    if (_favoritesNotifierCache == null && mounted) {
      _favoritesNotifierCache = Provider.of<FavoritesNotifier>(context, listen: false);
    }

    // 1. Handle changes in the source list for non-search display
    if (widget.items != oldWidget.items && !_internalIsSearchActive) {
      _sortedWidgetItems = _sortList(List<T>.from(widget.items));
      needsStateUpdate = true;
    }

    // 2. Handle changes in the full list used for searching
    if (widget.fullItemsListForSearch.length != _lastFullDataLength ||
        widget.fullItemsListForSearch != oldWidget.fullItemsListForSearch) {
      _lastFullDataLength = widget.fullItemsListForSearch.length;
      _rebuildSearchableStrings();
      // If a search is currently active, re-apply it to the new full list
      if (_internalIsSearchActive) {
        _filterAndPaginateSearchResults(currentSearchQuery, isNewQuery: true);
        // This method calls setState, so further setState in this didUpdateWidget might be redundant for this path
      } else {
        needsStateUpdate = true; // Data changed, might affect non-search view if items also changed
      }
    }

    // 3. Handle changes in the search query itself
    if (currentSearchQuery != _lastSearchQuery) {
      _lastSearchQuery = currentSearchQuery;
      bool newSearchActiveState = currentSearchQuery.length >= 2;

      if (_internalIsSearchActive != newSearchActiveState || newSearchActiveState) {
        _internalIsSearchActive = newSearchActiveState;
        if (_internalIsSearchActive) {
          if (_searchableStrings == null) { // Ensure searchable strings are available
             _rebuildSearchableStrings();
          }
          _filterAndPaginateSearchResults(currentSearchQuery, isNewQuery: true);
        } else {
          _resetSearchState(); // Resets and calls setState
        }
      }
      // If query changed, sub-methods (_filterAndPaginateSearchResults or _resetSearchState)
      // already call setState. So, no explicit 'needsStateUpdate = true' here for query change alone.
    }
    // This 'else if' block is removed to simplify. The primary driver for search UI
    // should be the query text. Parent's `widget.isSearchActive` controls search bar visibility.
    // If search bar is hidden by parent, it should also clear the query in SearchQueryNotifier.
    /* else if (widget.isSearchActive != oldWidget.isSearchActive) {
        // ... complex syncing logic removed for simplification ...
    } */

    if (needsStateUpdate && mounted) {
      setState(() {});
    }
  }

  void _rebuildSearchableStrings() {
    _searchableStrings = widget.fullItemsListForSearch.map((asset) {
      var text =
          '${asset.name.toLowerCase()} ${asset.symbol.toLowerCase()} ${asset.id.toLowerCase()}';
      if (asset is models.CurrencyAsset) {
        // Base 'text' has asset.name (Persian for CurrencyAsset) and asset.symbol.
        // Add asset.nameEn. ID is asset.symbol.
        if (asset.nameEn.isNotEmpty && asset.nameEn.toLowerCase() != asset.name.toLowerCase()) {
          text += ' ${asset.nameEn.toLowerCase()}';
        }
      } else if (asset is models.GoldAsset) {
        // Base 'text' has asset.name (Persian for GoldAsset) and asset.symbol.
        // Add asset.nameEn. ID is asset.symbol.
         if (asset.nameEn.isNotEmpty && asset.nameEn.toLowerCase() != asset.name.toLowerCase()) {
          text += ' ${asset.nameEn.toLowerCase()}';
        }
      } else if (asset is models.CryptoAsset) {
        // Base 'text' has asset.name (English for CryptoAsset), asset.symbol, and asset.id (derived from English name).
        // Only need to add asset.nameFa if it's different and not empty.
        if (asset.nameFa.isNotEmpty && asset.nameFa.toLowerCase() != asset.name.toLowerCase()) {
          text += ' ${asset.nameFa.toLowerCase()}';
        }
      } else if (asset is models.StockAsset) {
        // Base 'text' has asset.name (short name l18) and asset.symbol (also l18).
        // Add l30 (full name) and isin. ID is isin.
        if (asset.l30.isNotEmpty && asset.l30.toLowerCase() != asset.name.toLowerCase()) {
          text += ' ${asset.l30.toLowerCase()}';
        }
        // ISIN is already part of asset.id for StockAsset, but explicit add if needed for direct search on ISIN term
        // if (asset.isin.isNotEmpty && !text.contains(asset.isin.toLowerCase())) {
        //   text += ' ${asset.isin.toLowerCase()}';
        // }
      }
      return text.replaceAll(RegExp(r'\s+'), ' ').trim();
    }).toList();
  }

  void _filterAndPaginateSearchResults(String query, {bool isNewQuery = false}) {
    if (_searchableStrings == null && widget.fullItemsListForSearch.isNotEmpty) {
      _rebuildSearchableStrings();
    }
    if (_searchableStrings == null || (_isLoadingMoreSearchResults && !isNewQuery)) return;


    if (isNewQuery) {
      final queryLower = query.toLowerCase();
      List<T> tempFullResults = [];
      for (int i = 0; i < _searchableStrings!.length; i++) {
        if (_searchableStrings![i].contains(queryLower)) {
          tempFullResults.add(widget.fullItemsListForSearch[i]);
        }
      }
      _fullSearchResults = _sortList(tempFullResults);
      _paginatedSearchResults = [];
    }

    if (widget.assetType == AssetType.crypto) {
      _isLoadingMoreSearchResults = true;
      final appConfig = Provider.of<AppConfig>(context, listen: false);
      final int itemsToLoad = (isNewQuery || _paginatedSearchResults.isEmpty)
          ? appConfig.initialItemsToLoad
          : appConfig.itemsPerLazyLoad;
      final currentLength = _paginatedSearchResults.length;
      final int end = math.min(currentLength + itemsToLoad, _fullSearchResults.length);

      if (currentLength < end) {
        _paginatedSearchResults.addAll(_fullSearchResults.sublist(currentLength, end));
      }
      _isLoadingMoreSearchResults = false;
    } else {
      _paginatedSearchResults = List<T>.from(_fullSearchResults);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _resetSearchState() {
    _fullSearchResults = [];
    _paginatedSearchResults = [];
    _internalIsSearchActive = false;
    _sortedWidgetItems = _sortList(List<T>.from(widget.items));
    if (mounted) {
      setState(() {});
    }
  }

  void _onScroll() {
    final pos = _scrollController.position.pixels;
    final maxScroll = _scrollController.position.maxScrollExtent;

    if (pos >= maxScroll * 0.85 && !_isLoadingMoreSearchResults) {
      if (_internalIsSearchActive && widget.assetType == AssetType.crypto) {
        // Handling pagination for active search results in crypto tab
        if (_paginatedSearchResults.length < _fullSearchResults.length) {
          _filterAndPaginateSearchResults(_lastSearchQuery, isNewQuery: false);
        }
      } else if (!_internalIsSearchActive) {
        // Handling pagination for normal list view (no search active)
        // The specific check for CryptoDataNotifier.hasMoreScrollableItems is removed
        // as the notifier itself now correctly limits loading to its full list.
        widget.onLoadMore();
      }
    }
  }

  @override
  void dispose() {
    _errorRetryTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  int _getOptimalColumnCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final orientation = MediaQuery.of(context).orientation;
    if (width < 600 && orientation == Orientation.portrait) return 2;
    if (width < 900 && orientation == Orientation.landscape) return 4;
    if (width < 900 && orientation == Orientation.portrait) return 5;
    if (width < 1200 && orientation == Orientation.landscape) return 5;
    if (width < 1600) return 8;
    return 9;
  }

  double _getCardAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final orientation = MediaQuery.of(context).orientation;
    const double baseAspectRatio = 0.8;
    if (width < 600 && orientation == Orientation.portrait) return baseAspectRatio;
    return math.max(0.75, baseAspectRatio * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_didInitialFill && !widget.isLoading && (_sortedWidgetItems.isNotEmpty || _paginatedSearchResults.isNotEmpty) ) {
        _didInitialFill = true;
        final itemsCurrentlyConsidered = _internalIsSearchActive ? _paginatedSearchResults : _sortedWidgetItems;
        final fullListConsidered = _internalIsSearchActive ? _fullSearchResults : widget.fullItemsListForSearch;

        final columnCount = _getOptimalColumnCount(context);
        final remainder = itemsCurrentlyConsidered.length % columnCount;
        if (fullListConsidered.length > itemsCurrentlyConsidered.length && remainder != 0) {
          if (_internalIsSearchActive && widget.assetType == AssetType.crypto) {
             if (!_isLoadingMoreSearchResults && _paginatedSearchResults.length < _fullSearchResults.length) {
                _filterAndPaginateSearchResults(_lastSearchQuery, isNewQuery: false);
             }
          } else if (!_internalIsSearchActive) {
            widget.onLoadMore();
          }
        }
      }
    });

    context.watch<SearchQueryNotifier>(); // Ensures build re-runs on query change for UI updates
    final l10n = AppLocalizations.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localeNotifier = context.watch<LocaleNotifier>();
    final isRTL = localeNotifier.locale.languageCode == 'fa';
    final alertProvider = context.watch<AlertProvider>();

    // _internalIsSearchActive is now primarily managed by didUpdateWidget.
    // The build method just uses its current value.

    final alert = (widget.assetType == AssetType.currency &&
            alertProvider.alert != null &&
            alertProvider.alert!.show &&
            alertProvider.isVisible)
        ? alertProvider.alert
        : null;

    if (widget.error != null && !widget.error!.toLowerCase().contains('offline')) {
      _errorRetryTimer?.cancel();
      _errorRetryTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) widget.onRefresh();
      });
    } else {
      _errorRetryTimer?.cancel();
    }

    final bool noItemsToDisplay = _internalIsSearchActive ? _paginatedSearchResults.isEmpty : _sortedWidgetItems.isEmpty;

    if (widget.isLoading && noItemsToDisplay) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (widget.error != null && noItemsToDisplay) {
      final isConnectionError = widget.error!.toLowerCase().contains('offline') ||
                                widget.error!.toLowerCase().contains('dioexception') ||
                                widget.error!.toLowerCase().contains('socketexception');
      if (isConnectionError) {
        final status = widget.error!.toLowerCase().contains('offline') &&
                       !widget.error!.toLowerCase().contains('dioexception')
            ? ConnectionStatus.internetDown
            : ConnectionStatus.serverDown;
        return Center(child: ErrorPlaceholder(status: status));
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text("${l10n.errorGeneric}: ${widget.error}", textAlign: TextAlign.center,
              style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87)),
        ),
      );
    }

    List<T> finalDisplayList;
    if (_internalIsSearchActive) {
      finalDisplayList = (widget.assetType == AssetType.crypto)
          ? _paginatedSearchResults
          : _fullSearchResults;
    } else {
      finalDisplayList = _sortedWidgetItems;
    }

    if (finalDisplayList.isEmpty && !widget.isLoading) {
      return Center(
        child: Text(
          _internalIsSearchActive ? l10n.searchNoResults : l10n.listNoData,
          style: TextStyle(fontFamily: isRTL ? 'Vazirmatn' : 'SF-Pro', fontSize: 16,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
        ),
      );
    }

    final columnCount = _getOptimalColumnCount(context);
    final aspectRatio = _getCardAspectRatio(context);

    final searchBar = AnimatedContainer(
      duration: widget.showSearchBar ? const Duration(milliseconds: 400) : const Duration(milliseconds: 300),
      curve: Curves.easeInOutQuart,
      height: widget.showSearchBar ? 48.0 : 0.0,
      margin: widget.showSearchBar ? const EdgeInsets.only(top: 10.0, bottom: 4.0) : EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: AnimatedOpacity(
        opacity: widget.showSearchBar ? 1.0 : 0.0,
        duration: widget.showSearchBar ? const Duration(milliseconds: 300) : const Duration(milliseconds: 200),
        child: widget.isSearchActive
            ? const ShimmeringSearchField()
            : const SizedBox(),
      ),
    );

    Widget scrollableContent = CustomScrollView(
      controller: _scrollController,
      physics: (kIsWeb && (defaultTargetPlatform == TargetPlatform.macOS ||
                           defaultTargetPlatform == TargetPlatform.windows ||
                           defaultTargetPlatform == TargetPlatform.linux))
          ? const NeverScrollableScrollPhysics() // WebSmoothScroll handles physics
          : const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        CupertinoSliverRefreshControl(
          refreshTriggerPullDistance: 80.0,
          refreshIndicatorExtent: 70.0,
          builder: (BuildContext context, RefreshIndicatorMode refreshState, double pulledExtent,
              double refreshTriggerPullDistance, double refreshIndicatorExtent) {
            final bool showIndicator = refreshState == RefreshIndicatorMode.refresh ||
                                      refreshState == RefreshIndicatorMode.armed ||
                                      (refreshState == RefreshIndicatorMode.drag && pulledExtent > 40.0);
            final settingsNotifier = context.read<CardCornerSettingsNotifier>();
            const double defaultSmooth = 0.7;
            const double maxSmooth = 0.9;
            double targetSmooth;
            if (refreshState == RefreshIndicatorMode.refresh) {
              targetSmooth = maxSmooth;
            } else if (refreshState == RefreshIndicatorMode.armed || refreshState == RefreshIndicatorMode.drag) {
              final double pullRatio = math.min(1.0, pulledExtent / refreshTriggerPullDistance);
              targetSmooth = defaultSmooth + (maxSmooth - defaultSmooth) * pullRatio;
            } else {
              targetSmooth = defaultSmooth;
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if(mounted) settingsNotifier.updateSmoothness(targetSmooth);
            });
            return Container(
              height: pulledExtent,
              alignment: Alignment.bottomCenter,
              padding: EdgeInsets.only(top: widget.topPadding + 30.0, bottom: 30.0),
              child: AnimatedOpacity(
                opacity: showIndicator ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Container(
                  height: 60.0,
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: const CupertinoActivityIndicator(radius: 10.0),
                ),
              ),
            );
          },
          onRefresh: widget.onRefresh,
        ),
        SliverToBoxAdapter(child: SizedBox(height: widget.topPadding)),
        SliverToBoxAdapter(child: searchBar),
        if (alert != null)
          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutQuint,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SizeTransition(sizeFactor: animation, axisAlignment: -1.0, child: child),
                );
              },
              child: !_internalIsSearchActive
                  ? AlertCard(
                      key: ValueKey(alert.color),
                      alert: alert,
                      onAction: (action) {
                        ActionHandler.handle(context, action, widget.tabController);
                      },
                    )
                  : const SizedBox.shrink(key: ValueKey('alert_hidden')),
            ),
          ),
        if (finalDisplayList.isNotEmpty)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(8.0, !_internalIsSearchActive && alert != null ? 2.0 : 8.0, 8.0, 8.0),
            sliver: Directionality(
              textDirection: ui.TextDirection.ltr,
              child: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columnCount,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: aspectRatio,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final asset = finalDisplayList[index];
                    final card = AssetCard(asset: asset, assetType: widget.assetType);
                    if (widget.useCardAnimation) {
                      return AnimatedCardBuilder(index: index, child: card);
                    }
                    return card;
                  },
                  childCount: finalDisplayList.length,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
                ),
              ),
            ),
          )
        else if (!widget.isLoading)
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(
                child: Text(
                  _internalIsSearchActive ? l10n.searchNoResults : l10n.listNoData,
                  style: TextStyle(fontFamily: isRTL ? 'Vazirmatn' : 'SF-Pro', fontSize: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                ),
              ),
            ),
          ),
      ],
    );

    Widget finalWidgetToReturn = scrollableContent;

    if (kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux)) {

      // WebSmoothScroll wraps the basic scrollableContent (CustomScrollView)
      Widget webSmoothScrolledContent = WebSmoothScroll(
        key: Key('${widget.assetType.name}WebScroll'),
        controller: _scrollController,
        scrollSpeed: 1.1, // Keep the adjusted speed
        scrollAnimationLength: 500,
        curve: Curves.easeOutCubic,
        child: scrollableContent,
      );

      // Then, wrap with ScrollConfiguration to hide scrollbars
      finalWidgetToReturn = ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: webSmoothScrolledContent,
      );
    }
    return finalWidgetToReturn;
  }

  ScrollController get scrollController => _scrollController;

  void setSortMode(SortMode mode) {
    if (_sortMode == mode && mounted) return;

    _sortMode = mode;

    _sortedWidgetItems = _sortList(List<T>.from(widget.items));

    if (_internalIsSearchActive && _fullSearchResults.isNotEmpty) {
      _fullSearchResults = _sortList(List<T>.from(_fullSearchResults));

      if (widget.assetType == AssetType.crypto) {
        _paginatedSearchResults = [];

        _isLoadingMoreSearchResults = true;
        final appConfig = Provider.of<AppConfig>(context, listen: false);
        final int itemsToLoad = appConfig.initialItemsToLoad;
        final int end = math.min(itemsToLoad, _fullSearchResults.length);
        if (end > 0) {
          _paginatedSearchResults.addAll(_fullSearchResults.sublist(0, end));
        }
        _isLoadingMoreSearchResults = false;

      } else {
        _paginatedSearchResults = List<T>.from(_fullSearchResults);
      }
    }

    if (mounted) {
      setState(() {});
    }
  }
}
