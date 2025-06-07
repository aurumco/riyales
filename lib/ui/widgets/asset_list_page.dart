import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:web_smooth_scroll/web_smooth_scroll.dart';
import 'package:smooth_corner/smooth_corner.dart';

import '../../models/asset_models.dart' as models;
import '../../providers/locale_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/search_provider.dart';
// import '../../providers/card_corner_settings_provider.dart'; // Removed unused import
import '../../localization/app_localizations.dart';
import '../../services/connection_service.dart';
import '../../utils/helpers.dart';
import './asset_card.dart';
import './common/animated_card_builder.dart';
import './common/error_placeholder.dart';

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

  bool _searchIndexBuilt = false;
  final Map<String, Set<int>> _bigramIndex = {};
  final Map<String, Set<int>> _trigramIndex = {};
  int _lastFullDataLength = 0;
  SortMode _sortMode = SortMode.defaultOrder;

  bool _didInitialFill = false;

  // _getDataNotifier, _fetchDataForCurrentType, _loadMoreDataForCurrentType removed as actions are now passed via callbacks.

  void _buildSearchIndex(List<T> assets) {
    _bigramIndex.clear();
    _trigramIndex.clear();
    for (int i = 0; i < assets.length; i++) {
      final asset = assets[i];
      String text =
          '${asset.name.toLowerCase()} ${asset.symbol.toLowerCase()} ${asset.id.toLowerCase()}';
      if (asset is models.CurrencyAsset) {
        text += ' ${asset.nameEn.toLowerCase()}';
      } else if (asset is models.GoldAsset) {
        text += ' ${asset.nameEn.toLowerCase()}';
      } else if (asset is models.CryptoAsset) {
        text += ' ${asset.nameFa.toLowerCase()}';
      } else if (asset is models.StockAsset) {
        text += ' ${asset.l30.toLowerCase()} ${asset.isin.toLowerCase()}';
      }
      text = text.replaceAll(RegExp(r'\s+'), ' ');
      for (int j = 0; j <= text.length - 2; j++) {
        _bigramIndex
            .putIfAbsent(text.substring(j, j + 2), () => <int>{})
            .add(i);
      }
      for (int j = 0; j <= text.length - 3; j++) {
        _trigramIndex
            .putIfAbsent(text.substring(j, j + 3), () => <int>{})
            .add(i);
      }
    }
  }

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
      _searchIndexBuilt = false;
      _lastFullDataLength = widget.fullItemsListForSearch.length;
    }
  }

  void _onScroll() {
    final pos = _scrollController.position.pixels;
    if (pos >= _scrollController.position.maxScrollExtent * 0.85) {
      widget.onLoadMore();
    }

    if (mounted) {
      // final settingsNotifier = context.read<CardCornerSettingsNotifier>();
      // The dynamic update of card corner settings based on scroll position has been removed
      // to optimize scrolling performance.
      // _defaultRadius and _defaultSmoothness are initialized in initState's post-frame callback.
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
      return baseAspectRatio;
    }
    if (width < 900 && orientation == Orientation.landscape) {
      return baseAspectRatio * 0.8;
    }
    if (width < 900 && orientation == Orientation.portrait) {
      return baseAspectRatio * 0.9;
    }
    if (width < 1200) {
      return baseAspectRatio * 0.9;
    }
    return baseAspectRatio * 0.9;
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
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localeNotifier = context.watch<LocaleNotifier>();
    final isRTL = localeNotifier.locale.languageCode == 'fa';
    // AppConfig is not directly watched here anymore; it's assumed to be stable or handled by parent.

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
      if (!_searchIndexBuilt && widget.fullItemsListForSearch.isNotEmpty) {
        _buildSearchIndex(widget.fullItemsListForSearch);
        _searchIndexBuilt = true;
      }
      final queryLower = searchQueryNotifier.query.toLowerCase();
      List<T> filtered = [];
      if (queryLower.length == 2) {
        final indices = _bigramIndex[queryLower] ?? <int>{};
        final sortedIdx = indices.toList()..sort();
        if (widget.fullItemsListForSearch.isNotEmpty) {
          filtered = sortedIdx
              .where((i) => i < widget.fullItemsListForSearch.length)
              .map((i) => widget.fullItemsListForSearch[i])
              .toList();
        }
      } else {
        Set<int>? resultSet;
        for (int k = 0; k <= queryLower.length - 3; k++) {
          final gram = queryLower.substring(k, k + 3);
          final gramSet = _trigramIndex[gram] ?? <int>{};
          if (resultSet == null) {
            resultSet = gramSet.toSet();
          } else {
            resultSet = resultSet.intersection(gramSet);
          }
          if (resultSet.isEmpty) {
            break;
          }
        }
        if (resultSet != null &&
            resultSet.isNotEmpty &&
            widget.fullItemsListForSearch.isNotEmpty) {
          final sortedIdx = resultSet.toList()..sort();
          filtered = sortedIdx
              .where((i) => i < widget.fullItemsListForSearch.length)
              .map((i) => widget.fullItemsListForSearch[i])
              .toList();
        }
      }
      dataToProcess = filtered; // Update dataToProcess with filtered results
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
        // TODO: Consider if original API sort order should be preserved within these groups
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
            ? Builder(builder: (context) {
                final searchText = searchQueryNotifier.query;
                final isRTL = localeNotifier.locale.languageCode == 'fa' ||
                    containsPersian(searchText);
                final textColor =
                    isDarkMode ? Colors.grey[300] : Colors.grey[700];
                final placeholderColor =
                    isDarkMode ? Colors.grey[600] : Colors.grey[500];
                final iconColor =
                    isDarkMode ? Colors.grey[400] : Colors.grey[600];
                final fontFamily = isRTL ? 'Vazirmatn' : 'SF-Pro';
                return Container(
                  decoration: ShapeDecoration(
                    color: isDarkMode ? const Color(0xFF161616) : Colors.white,
                    shape: SmoothRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        smoothness: 0.7),
                  ),
                  child: CupertinoTextField(
                    controller: TextEditingController(text: searchText)
                      ..selection = TextSelection.fromPosition(
                          TextPosition(offset: searchText.length)),
                    onChanged: (v) =>
                        context.read<SearchQueryNotifier>().query = v,
                    placeholder: l10n.searchPlaceholder,
                    placeholderStyle: TextStyle(
                        color: placeholderColor, fontFamily: fontFamily),
                    prefix: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 18),
                        child: Icon(CupertinoIcons.search,
                            size: 20, color: iconColor)),
                    suffix: searchText.isNotEmpty
                        ? CupertinoButton(
                            padding: const EdgeInsetsDirectional.only(end: 18),
                            minSize: 30,
                            child: Icon(CupertinoIcons.clear,
                                size: 18, color: iconColor),
                            onPressed: () =>
                                context.read<SearchQueryNotifier>().query = '',
                          )
                        : null,
                    textAlign: isRTL ? TextAlign.right : TextAlign.left,
                    padding: EdgeInsetsDirectional.only(
                        start: 9,
                        end: searchText.isNotEmpty ? 28 : 12,
                        top: 11,
                        bottom: 11),
                    style: TextStyle(color: textColor, fontFamily: fontFamily),
                    cursorColor:
                        isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    decoration: null,
                  ),
                );
              })
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
        SliverToBoxAdapter(
          child: SizedBox(height: widget.topPadding),
        ),
        // Always include the search bar sliver to allow height animation
        SliverToBoxAdapter(child: searchBar),
        CupertinoSliverRefreshControl(
          refreshTriggerPullDistance: 100.0,
          refreshIndicatorExtent: 60.0,
          onRefresh: widget.onRefresh,
        ),
        SliverPadding(
          padding: const EdgeInsets.all(8.0),
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
                  return AnimatedCardBuilder(
                    index: index,
                    child: AssetCard(
                      asset: asset,
                      assetType: widget.assetType,
                    ),
                  );
                },
                childCount: sortedDisplayData.length,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
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
