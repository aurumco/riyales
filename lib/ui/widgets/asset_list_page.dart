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
// import '../../config/app_config.dart'; // For AppConfig access - Removed as AppConfig is not directly used here after recent refactors
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
  // String _lastSearchQuery = ''; // Unused field

  // Internal flag to manage if search filtering logic is active.
  // widget.isSearchActive is from parent and controls UI elements like search bar visibility.
  // bool _internalIsSearchActive = false; // Unused field

  // List<T> _fullSearchResults = []; // Removed, filtering is now in build
  // List<T> _paginatedSearchResults = []; // Removed, pagination for search handled in build
  final bool _isLoadingMoreSearchResults =
      false; // Made final as it's not reassigned

  // List<T> _sortedWidgetItems = []; // Removed, sorting is now in build
  FavoritesNotifier? _favoritesNotifierCache; // Kept for sorting
  bool _didInitialFill = false;

  // --- Added for crypto search pagination ---
  int _searchPage = 1;
  static const int _searchPageSizeCrypto = 24;
  static const int _minSearchChars = 3;
  String _lastSearchQuery = '';
  List<T> _currentFilteredResults = [];

  // Added from old code for pull-to-refresh smoothness effect
  static const double _maxRadiusDelta = 13.5;
  static const double _maxSmoothnessDelta = 0.75;
  double _defaultRadius = 21.0; // Default, will be updated from Notifier
  double _defaultSmoothness = 0.7; // Default, will be updated from Notifier

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _favoritesNotifierCache =
            Provider.of<FavoritesNotifier>(context, listen: false);
        final settings = context.read<CardCornerSettingsNotifier>().settings;
        _defaultRadius = settings.radius;
        _defaultSmoothness = settings.smoothness;

        // Initial data fetch is handled by the parent DataNotifier's onInitialize callback.
        if (widget.items.isEmpty && !widget.isSearchActive) {
          // isSearchActive from parent
          widget.onInitialize();
        }
      }
    });
  }

  List<T> _sortList(List<T> listToSort, FavoritesNotifier? favoritesNotifier) {
    // Updated to accept favoritesNotifier as a parameter.
    if (favoritesNotifier == null) {
      return List<T>.from(listToSort);
    }

    final favorites = favoritesNotifier.favorites;
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
        final favoriteItems =
            listToSort.where((item) => favorites.contains(item.id)).toList();
        final nonFavoriteItems =
            listToSort.where((item) => !favorites.contains(item.id)).toList();
        sortedList = [...favoriteItems, ...nonFavoriteItems];
    }
    return sortedList;
  }

  @override
  void didUpdateWidget(covariant AssetListPage<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // final currentSearchQuery = Provider.of<SearchQueryNotifier>(context).query; // No longer needed here
    bool needsStateUpdate = false;

    if (_favoritesNotifierCache == null && mounted) {
      // Cache favoritesNotifier if not already done.
      _favoritesNotifierCache =
          Provider.of<FavoritesNotifier>(context, listen: false);
    }

    // 1. Handle changes in the source list (widget.items)
    //    This is important if the underlying data provider fetches new data
    //    and we are NOT in a search state.
    //    The build method will handle sorting and displaying these items.
    if (widget.items != oldWidget.items) {
      // If items changed and we are not searching, we might need a rebuild if sort order is important
      // or if other derived state depends on widget.items directly.
      // However, since filtering/sorting is in build, this might just be for _didInitialFill or similar.
      needsStateUpdate = true;
    }

    // 2. Handle changes in the full list used for searching
    //    This is crucial for rebuilding _searchableStrings.
    if (widget.fullItemsListForSearch.length != _lastFullDataLength ||
        widget.fullItemsListForSearch != oldWidget.fullItemsListForSearch) {
      _lastFullDataLength = widget.fullItemsListForSearch.length;
      _rebuildSearchableStrings();
      // No need to re-filter here, build() will do it.
      needsStateUpdate = true;
    }

    // 3. Search query changes are handled by context.watch in build method directly.
    //    No need for specific logic here to handle query changes.

    if (needsStateUpdate && mounted) {
      setState(() {});
    }
  }

  void _rebuildSearchableStrings() {
    _searchableStrings = widget.fullItemsListForSearch.map((asset) {
      var text =
          '${asset.name.toLowerCase()} ${asset.symbol.toLowerCase()} ${asset.id.toLowerCase()}';
      if (asset is models.CurrencyAsset) {
        if (asset.nameEn.isNotEmpty &&
            asset.nameEn.toLowerCase() != asset.name.toLowerCase()) {
          text += ' ${asset.nameEn.toLowerCase()}';
        }
      } else if (asset is models.GoldAsset) {
        if (asset.nameEn.isNotEmpty &&
            asset.nameEn.toLowerCase() != asset.name.toLowerCase()) {
          text += ' ${asset.nameEn.toLowerCase()}';
        }
      } else if (asset is models.CryptoAsset) {
        if (asset.nameFa.isNotEmpty &&
            asset.nameFa.toLowerCase() != asset.name.toLowerCase()) {
          text += ' ${asset.nameFa.toLowerCase()}';
        }
      } else if (asset is models.StockAsset) {
        if (asset.l30.isNotEmpty &&
            asset.l30.toLowerCase() != asset.name.toLowerCase()) {
          text += ' ${asset.l30.toLowerCase()}';
        }
      }
      return text.replaceAll(RegExp(r'\s+'), ' ').trim();
    }).toList();
  }

  // _filterAndPaginateSearchResults removed as filtering is in build.
  // Pagination for crypto search results is also handled in build.

  // _resetSearchState removed as it's implicitly handled by build method
  // when search query is empty.

  void _onScroll() {
    final pos = _scrollController.position.pixels;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final searchQueryRaw =
        Provider.of<SearchQueryNotifier>(context, listen: false).query;
    final bool searchActive = searchQueryRaw.length >= _minSearchChars;

    if (pos >= maxScroll * 0.85) {
      if (!searchActive) {
        // Normal list pagination
        if (!_isLoadingMoreSearchResults) {
          widget.onLoadMore();
        }
      } else if (widget.assetType == AssetType.crypto) {
        // Pagination for crypto search results
        if (_currentFilteredResults.length >
            _searchPage * _searchPageSizeCrypto) {
          setState(() {
            _searchPage++;
          });
        }
      }
    }

    // Logic for pull-to-refresh smoothness effect (from old code)
    if (mounted) {
      final settingsNotifier = context.read<CardCornerSettingsNotifier>();
      if (pos < 0) {
        // User is pulling down
        final factor = (-pos / 100).clamp(0.0, 1.0); // Normalize pull distance
        final newSmooth = _defaultSmoothness + _maxSmoothnessDelta * factor;
        final newRadius = _defaultRadius + _maxRadiusDelta * factor;
        settingsNotifier
            .updateSmoothness(newSmooth.clamp(0.0, 1.0)); // Clamp smoothness
        settingsNotifier.updateRadius(
            newRadius.clamp(0.0, 100.0)); // Clamp radius (adjust max as needed)
      } else {
        // Reset to default when not pulling or scrolling normally
        if (settingsNotifier.settings.smoothness != _defaultSmoothness) {
          settingsNotifier.updateSmoothness(_defaultSmoothness);
        }
        if (settingsNotifier.settings.radius != _defaultRadius) {
          settingsNotifier.updateRadius(_defaultRadius);
        }
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
    if (width < 600 && orientation == Orientation.portrait) {
      return baseAspectRatio;
    }
    return math.max(0.75, baseAspectRatio * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    // Ensure _favoritesNotifierCache is initialized
    _favoritesNotifierCache ??=
        Provider.of<FavoritesNotifier>(context, listen: false);

    final favoritesNotifier =
        context.watch<FavoritesNotifier>(); // Watch for sorting changes
    final searchQueryNotifier = context
        .watch<SearchQueryNotifier>(); // Ensures build re-runs on query change
    final l10n = AppLocalizations.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localeNotifier = context.watch<LocaleNotifier>();
    final isRTL = localeNotifier.locale.languageCode == 'fa';
    final alertProvider = context.watch<AlertProvider>();

    final String currentSearchQuery = searchQueryNotifier.query;

    // Reset pagination when query changes
    if (currentSearchQuery != _lastSearchQuery) {
      _lastSearchQuery = currentSearchQuery;
      _searchPage = 1;
    }

    final bool isCurrentlySearching = currentSearchQuery.length >= _minSearchChars;

    List<T> itemsToDisplay;

    if (isCurrentlySearching) {
      if (_searchableStrings == null &&
          widget.fullItemsListForSearch.isNotEmpty) {
        // This should ideally be built in didUpdateWidget or initState if fullItemsListForSearch is available then.
        // Building it here might be slightly inefficient if build is called frequently for other reasons.
        _rebuildSearchableStrings();
      }
      if (_searchableStrings != null) {
        final queryLower = currentSearchQuery.toLowerCase();
        List<T> filteredResults = [];
        for (int i = 0; i < _searchableStrings!.length; i++) {
          if (_searchableStrings![i].contains(queryLower)) {
            filteredResults.add(widget.fullItemsListForSearch[i]);
          }
        }
        // Sort once
        List<T> sortedFiltered = _sortList(filteredResults, favoritesNotifier);

        if (widget.assetType == AssetType.crypto) {
          _currentFilteredResults = sortedFiltered;
          final int end = math.min(
              _searchPage * _searchPageSizeCrypto, _currentFilteredResults.length);
          itemsToDisplay = _currentFilteredResults.sublist(0, end);
        } else {
          itemsToDisplay = sortedFiltered;
        }
      } else {
        itemsToDisplay =
            []; // Should not happen if fullItemsListForSearch is populated
      }
    } else {
      itemsToDisplay = _sortList(List<T>.from(widget.items), favoritesNotifier);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This logic is for filling the last row if not searching.
      if (mounted &&
          !_didInitialFill &&
          !widget.isLoading &&
          !isCurrentlySearching &&
          itemsToDisplay.isNotEmpty) {
        _didInitialFill = true;
        final columnCount = _getOptimalColumnCount(context);
        final remainder = itemsToDisplay.length % columnCount;
        // Check against widget.fullItemsListForSearch or a similar source for "has more"
        if (widget.fullItemsListForSearch.length > itemsToDisplay.length &&
            remainder != 0) {
          widget.onLoadMore();
        }
      }
    });

    final alert = (widget.assetType == AssetType.currency &&
            alertProvider.alert != null &&
            alertProvider.alert!.show &&
            alertProvider.isVisible)
        ? alertProvider.alert
        : null;

    if (widget.error != null &&
        !widget.error!.toLowerCase().contains('offline')) {
      _errorRetryTimer?.cancel();
      _errorRetryTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) widget.onRefresh();
      });
    } else {
      _errorRetryTimer?.cancel();
    }

    if (widget.isLoading && itemsToDisplay.isEmpty) {
      // Check itemsToDisplay
      return const Center(child: CupertinoActivityIndicator());
    }

    if (widget.error != null && itemsToDisplay.isEmpty) {
      // Check itemsToDisplay
      final isConnectionError =
          widget.error!.toLowerCase().contains('offline') ||
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
          child: Text("${l10n.errorGeneric}: ${widget.error}",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black87)),
        ),
      );
    }

    // List<T> finalDisplayList; // Renamed to itemsToDisplay and calculated above
    // if (_internalIsSearchActive) {
    //   finalDisplayList = (widget.assetType == AssetType.crypto)
    //       ? _paginatedSearchResults
    //       : _fullSearchResults;
    // } else {
    //   finalDisplayList = _sortedWidgetItems;
    // }

    if (itemsToDisplay.isEmpty && !widget.isLoading) {
      return Center(
        child: Text(
          isCurrentlySearching ? l10n.searchNoResults : l10n.listNoData,
          style: TextStyle(
              fontFamily: isRTL ? 'Vazirmatn' : 'SF-Pro',
              fontSize: 16,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
        ),
      );
    }

    final columnCount = _getOptimalColumnCount(context);
    final aspectRatio = _getCardAspectRatio(context);

    final searchBar = AnimatedContainer(
      duration: widget.showSearchBar
          ? const Duration(milliseconds: 400)
          : const Duration(milliseconds: 300),
      curve: Curves.easeInOutQuart,
      height: widget.showSearchBar ? 48.0 : 0.0,
      margin: widget.showSearchBar
          ? const EdgeInsets.only(top: 10.0, bottom: 4.0)
          : EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: AnimatedOpacity(
        opacity: widget.showSearchBar ? 1.0 : 0.0,
        duration: widget.showSearchBar
            ? const Duration(milliseconds: 300)
            : const Duration(milliseconds: 200),
        child:
            widget.isSearchActive // This is widget.isSearchActive (from parent)
                ? const ShimmeringSearchField()
                : const SizedBox(),
      ),
    );

    Widget scrollableContent = CustomScrollView(
      controller: _scrollController,
      physics: (kIsWeb &&
              (defaultTargetPlatform == TargetPlatform.macOS ||
                  defaultTargetPlatform == TargetPlatform.windows ||
                  defaultTargetPlatform == TargetPlatform.linux))
          ? const NeverScrollableScrollPhysics() // WebSmoothScroll handles physics
          : const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        CupertinoSliverRefreshControl(
          refreshTriggerPullDistance: 80.0,
          refreshIndicatorExtent: 70.0,
          builder: (BuildContext context,
              RefreshIndicatorMode refreshState,
              double pulledExtent,
              double refreshTriggerPullDistance,
              double refreshIndicatorExtent) {
            final bool showIndicator =
                refreshState == RefreshIndicatorMode.refresh ||
                    refreshState == RefreshIndicatorMode.armed ||
                    (refreshState == RefreshIndicatorMode.drag &&
                        pulledExtent > 40.0);
            // final settingsNotifier = context.read<CardCornerSettingsNotifier>(); // Unused variable
            // const double defaultSmooth = 0.7; // Unused variable
            // const double maxSmooth = 0.9; // Unused variable
            // double targetSmooth; // Unused variable
            // if (refreshState == RefreshIndicatorMode.refresh) {
            //   targetSmooth = maxSmooth;
            // } else if (refreshState == RefreshIndicatorMode.armed || refreshState == RefreshIndicatorMode.drag) {
            //   final double pullRatio = math.min(1.0, pulledExtent / refreshTriggerPullDistance);
            //   targetSmooth = defaultSmooth + (maxSmooth - defaultSmooth) * pullRatio;
            // } else {
            //   targetSmooth = defaultSmooth;
            // }
            // WidgetsBinding.instance.addPostFrameCallback((_) { // Removed: smoothness is now handled by _onScroll
            //   if(mounted) settingsNotifier.updateSmoothness(targetSmooth);
            // });
            return Container(
              height: pulledExtent,
              alignment: Alignment.bottomCenter,
              padding:
                  EdgeInsets.only(top: widget.topPadding + 30.0, bottom: 30.0),
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
                  child: SizeTransition(
                      sizeFactor: animation, axisAlignment: -1.0, child: child),
                );
              },
              child:
                  !isCurrentlySearching // Use isCurrentlySearching based on query
                      ? AlertCard(
                          key: ValueKey(alert.color),
                          alert: alert,
                          onAction: (action) {
                            ActionHandler.handle(
                                context, action, widget.tabController);
                          },
                        )
                      : const SizedBox.shrink(key: ValueKey('alert_hidden')),
            ),
          ),
        if (itemsToDisplay.isNotEmpty)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(8.0,
                !isCurrentlySearching && alert != null ? 2.0 : 8.0, 8.0, 8.0),
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
                    final asset = itemsToDisplay[index]; // Use itemsToDisplay
                    // Added ValueKey for better list item management
                    // Limit expensive per-card animations to the first 40 visible items
                    if (widget.useCardAnimation && index < 40) {
                      return AnimatedCardBuilder(
                        index: index,
                        child: AssetCard(
                          asset: asset,
                          assetType: widget.assetType,
                        ),
                      );
                    } else {
                      return AssetCard(
                        asset: asset,
                        assetType: widget.assetType,
                      );
                    }
                  },
                  childCount: itemsToDisplay.length, // Use itemsToDisplay
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
                  isCurrentlySearching
                      ? l10n.searchNoResults
                      : l10n.listNoData, // Use isCurrentlySearching
                  style: TextStyle(
                      fontFamily: isRTL ? 'Vazirmatn' : 'SF-Pro',
                      fontSize: 16,
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
        scrollSpeed: 1.35, // Keep the adjusted speed
        scrollAnimationLength: 930,
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
    // No need to manually sort here, build method will re-sort.
    if (mounted) {
      setState(() {}); // Trigger rebuild to apply new sort mode.
    }
  }
}
