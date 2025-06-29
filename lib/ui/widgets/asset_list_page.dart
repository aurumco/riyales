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
  final bool isSearchActive;
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
    this.isSearchActive = false,
    this.tabController,
    this.useCardAnimation = true,
  });

  @override
  AssetListPageState<T> createState() => AssetListPageState<T>(); // Changed
}

class AssetListPageState<T extends models.Asset>
    extends State<AssetListPage<T>> {
  // Changed: Made public
  // static const double _maxRadiusDelta = 13.5; // Removed unused field
  // static const double _maxSmoothnessDelta = 0.75; // Removed unused field
  final ScrollController _scrollController = ScrollController();
  // StreamSubscription for connection status is no longer managed here, parent handles data refresh on reconnect.
  Timer? _errorRetryTimer; // Kept for retrying non-connection errors if any

  // double _defaultRadius = 21.0; // Removed unused field
  // double _defaultSmoothness = 0.9; // Removed unused field

  int _lastFullDataLength = 0;
  SortMode _sortMode = SortMode.defaultOrder;

  bool _didInitialFill = false;
  bool _isSearchActive = false;

  // _getDataNotifier, _fetchDataForCurrentType, _loadMoreDataForCurrentType removed as actions are now passed via callbacks.

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.items.isEmpty) {
        widget.onInitialize();
      }
    });
  }

  @override
  void didUpdateWidget(covariant AssetListPage<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fullItemsListForSearch.length != _lastFullDataLength ||
        widget.fullItemsListForSearch != oldWidget.fullItemsListForSearch) {
      // Also check if list instance changed
      _lastFullDataLength = widget.fullItemsListForSearch.length;
    }
  }

  void _onScroll() {
    final pos = _scrollController.position.pixels;
    if (pos >= _scrollController.position.maxScrollExtent * 0.85) {
      widget.onLoadMore();
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
    if (width < 600 && orientation == Orientation.portrait) {
      return 2;
    }
    if (width < 900 && orientation == Orientation.landscape) {
      return 4;
    }
    if (width < 900 && orientation == Orientation.portrait) {
      return 5;
    }
    if (width < 1200 && orientation == Orientation.landscape) {
      return 5;
    }
    if (width < 1600) {
      return 8;
    }
    return 9;
  }

  double _getCardAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final orientation = MediaQuery.of(context).orientation;
    const double baseAspectRatio = 0.8;

    if (width < 600 && orientation == Orientation.portrait) {
      return baseAspectRatio; // Phone portrait
    }
    // For wider screens, prevent the card from becoming too wide (squished vertically)
    // by ensuring the aspect ratio doesn't drop too low.
    return math.max(0.75, baseAspectRatio * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    // After first build, fill up to complete last row
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_didInitialFill && !widget.isLoading && widget.items.isNotEmpty) {
        _didInitialFill = true;
        final columnCount = _getOptimalColumnCount(context);
        final remainder = widget.items.length % columnCount;
        if (widget.fullItemsListForSearch.length > widget.items.length &&
            remainder != 0) {
          // Load more to fill the row
          widget.onLoadMore();
        }
      }
    });
    final favoritesNotifier = context.watch<FavoritesNotifier>();
    final searchQueryNotifier = context.watch<SearchQueryNotifier>();
    final l10n = AppLocalizations.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localeNotifier = context.watch<LocaleNotifier>();
    final isRTL = localeNotifier.locale.languageCode == 'fa';
    final alertProvider = context.watch<AlertProvider>();

    // Update search active state based on query
    if (searchQueryNotifier.query.isNotEmpty && !_isSearchActive) {
      setState(() {
        _isSearchActive = true;
      });
    } else if (searchQueryNotifier.query.isEmpty && _isSearchActive) {
      setState(() {
        _isSearchActive = false;
      });
    }

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
        if (mounted) {
          widget.onRefresh();
        }
      });
    } else {
      _errorRetryTimer?.cancel();
    }

    if (widget.isLoading && widget.items.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (widget.error != null && widget.items.isEmpty) {
      final isConnectionError =
          widget.error!.toLowerCase().contains('offline') ||
              widget.error!.toLowerCase().contains('dioexception') ||
              widget.error!.toLowerCase().contains('socketexception');
      if (isConnectionError) {
        // Determine a more specific status if possible, or use a generic "serverDown" / "internetDown"
        final status = widget.error!.toLowerCase().contains('offline') &&
                !widget.error!.toLowerCase().contains('dioexception')
            ? ConnectionStatus.internetDown
            : ConnectionStatus.serverDown;
        return Center(child: ErrorPlaceholder(status: status));
      }
      // For other types of errors (e.g., parsing errors, unexpected issues)
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "${l10n.errorGeneric}: ${widget.error}", // Include the actual error message
            textAlign: TextAlign.center,
            style:
                TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
          ),
        ),
      );
    }

    List<T> dataToProcess =
        List<T>.from(widget.items); // Use a copy for filtering/sorting

    if (searchQueryNotifier.query.length >= 2) {
      final queryLower = searchQueryNotifier.query.toLowerCase();
      dataToProcess = widget.fullItemsListForSearch.where((asset) {
        // Concatenate all searchable fields into a single string.
        String searchableText =
            '${asset.name.toLowerCase()} ${asset.symbol.toLowerCase()} ${asset.id.toLowerCase()}';

        if (asset is models.CurrencyAsset) {
          searchableText += ' ${asset.nameEn.toLowerCase()}';
        } else if (asset is models.GoldAsset) {
          searchableText += ' ${asset.nameEn.toLowerCase()}';
        } else if (asset is models.CryptoAsset) {
          searchableText += ' ${asset.nameFa.toLowerCase()}';
        } else if (asset is models.StockAsset) {
          searchableText +=
              ' ${asset.l30.toLowerCase()} ${asset.isin.toLowerCase()}';
        }
        // Perform a simple and fast 'contains' check.
        return searchableText.contains(queryLower);
      }).toList();
    }

    // Apply sorting
    List<T> sortedDisplayData;
    switch (_sortMode) {
      case SortMode.highestPrice:
        sortedDisplayData = List<T>.from(dataToProcess)
          ..sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortMode.lowestPrice:
        sortedDisplayData = List<T>.from(dataToProcess)
          ..sort((a, b) => a.price.compareTo(b.price));
        break;
      default: // DefaultOrder (includes favorites first)
        final favorites = favoritesNotifier.favorites;
        final favoriteItems =
            dataToProcess.where((item) => favorites.contains(item.id)).toList();
        final nonFavoriteItems = dataToProcess
            .where((item) => !favorites.contains(item.id))
            .toList();
        sortedDisplayData = [...favoriteItems, ...nonFavoriteItems];
    }

    if (sortedDisplayData.isEmpty) {
      return Center(
        child: Text(
          searchQueryNotifier.query.isNotEmpty
              ? l10n.searchNoResults
              : l10n.listNoData,
          style: TextStyle(
            fontFamily: isRTL ? 'Vazirmatn' : 'SF-Pro',
            fontSize: 16,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
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
        child: widget.isSearchActive
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
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        // Pull-to-refresh control must be first to appear on overscroll
        CupertinoSliverRefreshControl(
          // Increased values to provide more space for the refresh indicator
          refreshTriggerPullDistance: 80.0,
          refreshIndicatorExtent: 70.0,
          builder: (BuildContext context,
              RefreshIndicatorMode refreshState,
              double pulledExtent,
              double refreshTriggerPullDistance,
              double refreshIndicatorExtent) {
            // Ensure the indicator is visible only during active refresh states
            final bool showIndicator =
                refreshState == RefreshIndicatorMode.refresh ||
                    refreshState == RefreshIndicatorMode.armed ||
                    (refreshState == RefreshIndicatorMode.drag &&
                        pulledExtent > 40.0);

            // Dynamic update of card corner smoothness during pull-to-refresh
            final settingsNotifier = context.read<CardCornerSettingsNotifier>();
            const double defaultSmooth = 0.7;
            const double maxSmooth = 0.9;
            double targetSmooth;
            if (refreshState == RefreshIndicatorMode.refresh) {
              targetSmooth = maxSmooth;
            } else if (refreshState == RefreshIndicatorMode.armed ||
                refreshState == RefreshIndicatorMode.drag) {
              final double pullRatio =
                  math.min(1.0, pulledExtent / refreshTriggerPullDistance);
              targetSmooth =
                  defaultSmooth + (maxSmooth - defaultSmooth) * pullRatio;
            } else {
              targetSmooth = defaultSmooth;
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              settingsNotifier.updateSmoothness(targetSmooth);
            });

            // Add extra space above and below the indicator
            return Container(
              height: pulledExtent,
              alignment: Alignment.bottomCenter,
              // Add padding to ensure indicator stays away from content
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
        SliverToBoxAdapter(
          child: SizedBox(height: widget.topPadding),
        ),
        // Always include the search bar sliver to allow height animation
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
                    sizeFactor: animation,
                    axisAlignment: -1.0,
                    child: child,
                  ),
                );
              },
              child: !widget.isSearchActive
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
        if (sortedDisplayData.isNotEmpty)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              8.0,
              !widget.isSearchActive && alert != null ? 2.0 : 8.0,
              8.0,
              8.0,
            ),
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
                    final asset = sortedDisplayData[index];
                    final card = AssetCard(
                      asset: asset,
                      assetType: widget.assetType,
                    );
                    if (widget.useCardAnimation) {
                      return AnimatedCardBuilder(
                        index: index,
                        child: card,
                      );
                    }
                    return card;
                  },
                  childCount: sortedDisplayData.length,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
                ),
              ),
            ),
          )
        else
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(
                child: Text(
                  searchQueryNotifier.query.isNotEmpty
                      ? l10n.searchNoResults
                      : l10n.listNoData,
                  style: TextStyle(
                    fontFamily: isRTL ? 'Vazirmatn' : 'SF-Pro',
                    fontSize: 16,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    // Wrap with WebSmoothScroll if on desktop web platform only
    if (kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux)) {
      return WebSmoothScroll(
        key: Key('${widget.assetType.name}Scroll'),
        controller: _scrollController,
        scrollSpeed: 0.85,
        scrollAnimationLength: 600,
        curve: Curves.linearToEaseOut,
        child: scrollableContent,
      );
    }

    return scrollableContent;
  }

  // Public getter for the ScrollController
  ScrollController get scrollController => _scrollController;

  void setSortMode(SortMode mode) {
    setState(() {
      _sortMode = mode;
    });
  }
}
