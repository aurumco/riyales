import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// TODO: Add other necessary imports after moving files
// e.g., import '../common/animated_card_builder.dart';
// e.g., import '../asset_card.dart';
import '../../models/asset_models.dart' as models;
import '../../providers/app_config_provider.dart' as config_provider;
import '../../config/app_config.dart' as config;
import '../../providers/locale_provider.dart';
import '../../providers/currency_unit_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/card_corner_settings_provider.dart';
import '../../providers/data_providers/data_providers.dart'; // Assuming this will be the new path for data fetchers
import '../../localization/app_localizations.dart';
import '../../services/connection_service.dart';
import '../../utils/helpers.dart';
import 'asset_card.dart'; // Will be created later
import '../widgets/common/animated_card_builder.dart'; // Will be created later
import '../widgets/common/error_placeholder.dart'; // Will be created later


enum AssetType { currency, gold, crypto, stock }

// Insert SortMode enum for long-press sorting
enum SortMode { defaultOrder, highestPrice, lowestPrice }

class AssetListPage<T extends models.Asset> extends ConsumerStatefulWidget {
  final StateNotifierProvider<DataFetcherNotifier<T>, AsyncValue<List<T>>>
      provider;
  final AssetType assetType;

  const AssetListPage({
    super.key,
    required this.provider,
    required this.assetType,
  });

  @override
  _AssetListPageState<T> createState() => _AssetListPageState<T>();
}

class _AssetListPageState<T extends models.Asset>
    extends ConsumerState<AssetListPage<T>> {
  // Pull-to-refresh corner animation config: maximum changes
  static const double _maxRadiusDelta = 13.5;
  static const double _maxSmoothnessDelta = 0.75;
  final ScrollController _scrollController = ScrollController();
  late final StreamSubscription<ConnectionStatus> _connSub;
  Timer? _errorRetryTimer;
  // Default card corner settings for pull-to-refresh animation
  late final double _defaultRadius;
  late final double _defaultSmoothness;

  // Search optimization: inverted index for fast substring search
  bool _searchIndexBuilt = false;
  final Map<String, Set<int>> _bigramIndex = {};
  final Map<String, Set<int>> _trigramIndex = {};
  // Track full data length to know when to rebuild the index
  int _lastFullDataLength = 0;

  // Current sorting mode for this list
  SortMode _sortMode = SortMode.defaultOrder;

  // Build bigram and trigram indices for assets list
  void _buildSearchIndex(List<T> assets) {
    _bigramIndex.clear();
    _trigramIndex.clear();
    for (int i = 0; i < assets.length; i++) {
      final asset = assets[i];
      // Aggregate searchable text fields
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
      // Build bigrams
      for (int j = 0; j <= text.length - 2; j++) {
        final gram = text.substring(j, j + 2);
        _bigramIndex.putIfAbsent(gram, () => <int>{}).add(i);
      }
      // Build trigrams
      for (int j = 0; j <= text.length - 3; j++) {
        final gram = text.substring(j, j + 3);
        _trigramIndex.putIfAbsent(gram, () => <int>{}).add(i);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Capture default card corner settings
    final initialSettings = ref.read(cardCornerSettingsProvider);
    _defaultRadius = initialSettings.radius;
    _defaultSmoothness = initialSettings.smoothness;
    _scrollController.addListener(_onScroll);
    // Initialize data when this page is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(widget.provider.notifier).initialize();
    });
    // Auto-refresh when connection is restored
    _connSub = ConnectionService().statusStream.listen((status) {
      if (status == ConnectionStatus.connected) {
        ref.read(widget.provider.notifier).refresh();
      }
    });
  }

  void _onScroll() {
    final pos = _scrollController.position.pixels;
    if (pos >= _scrollController.position.maxScrollExtent * 0.85) {
      // Load more when near the bottom
      ref.read(widget.provider.notifier).loadMore();
    }
    // Animate card corners on pull-to-refresh overscroll
    final settingsNotifier = ref.read(cardCornerSettingsProvider.notifier);
    if (pos < 0) {
      // Normalize overscroll up to 100 px to [0,1]
      final factor = (-pos / 100).clamp(0.0, 1.0);
      // Animate smoothness by max delta, radius by max delta
      final newSmooth = _defaultSmoothness + _maxSmoothnessDelta * factor;
      final newRadius = _defaultRadius + _maxRadiusDelta * factor;
      settingsNotifier.updateSmoothness(newSmooth);
      settingsNotifier.updateRadius(newRadius);
    } else {
      // Restore to default settings
      settingsNotifier.updateSmoothness(_defaultSmoothness);
      settingsNotifier.updateRadius(_defaultRadius);
    }
  }

  @override
  void dispose() {
    _connSub.cancel();
    _errorRetryTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Get optimal number of columns based on screen width
  int _getOptimalColumnCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final orientation = MediaQuery.of(context).orientation;

    // Phone - portrait
    if (width < 600 && orientation == Orientation.portrait) return 2;
    // Phone - landscape
    if (width < 900 && orientation == Orientation.landscape) return 4;
    // Tablet - portrait
    if (width < 900 && orientation == Orientation.portrait) return 5;
    // Tablet - landscape
    if (width < 1200 && orientation == Orientation.landscape) return 5;
    // Small desktop
    if (width < 1600) return 8;
    // Extra wide desktop/TV
    return 9;
  }

  // Calculate appropriate card aspect ratio based on screen size
  double _getCardAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // final height = MediaQuery.of(context).size.height; // Not used
    final orientation = MediaQuery.of(context).orientation;

    // Base aspect ratio - slightly rectangular (width:height)
    const double baseAspectRatio =
        0.8; // Width is 80% of height for better mobile proportions

    // For phones in portrait mode
    if (width < 600 && orientation == Orientation.portrait) {
      return baseAspectRatio;
    }
    // For phones in landscape
    else if (width < 900 && orientation == Orientation.landscape) {
      return baseAspectRatio * 0.8; // Wider for landscape phone
    }
    // For tablets portrait
    else if (width < 900 && orientation == Orientation.portrait) {
      return baseAspectRatio * 0.9; // Slightly wider
    }
    // For tablets landscape and small desktop
    else if (width < 1200) {
      return baseAspectRatio * 0.9; // Even wider
    }
    // For large desktop
    else {
      return baseAspectRatio *
          0.9; // Most horizontally compact to fit more in a row
    }
  }

  @override
  Widget build(BuildContext context) {
    // Auto-retry on generic errors every 5 seconds
    ref.listen<AsyncValue<List<T>>>(widget.provider, (prev, next) {
      if (next is AsyncError<List<T>> &&
          !next.error.toString().contains('Offline')) {
        _errorRetryTimer?.cancel();
        _errorRetryTimer = Timer.periodic(
          const Duration(seconds: 5),
          (_) => ref.read(widget.provider.notifier).refresh(),
        );
      } else {
        _errorRetryTimer?.cancel();
      }
    });
    final asyncData = ref.watch(widget.provider);

    final favorites = ref.watch(favoritesProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentLocale = ref.watch(localeNotifierProvider);
    final isRTL = currentLocale.languageCode == 'fa';
    final appConfig = ref.watch(config_provider.appConfigProvider).asData?.value;

    if (appConfig == null) {
      return const Center(child: CupertinoActivityIndicator());
    }

    return asyncData.when(
      data: (data) {
        // Always use the full fetched list for search
        final notifier = ref.read(widget.provider.notifier);
        final fullDataList = notifier.getFullDataList(); // Assuming public getter after refactor
        // If the full data has changed, reset the search index
        if (fullDataList.length != _lastFullDataLength) {
          _searchIndexBuilt = false;
          _lastFullDataLength = fullDataList.length;
        }
        List<T> displayedData = data;

        // Optimized filter: start only after 2 characters
        if (searchQuery.length >= 2) {
          // Build index on the full list if needed
          if (!_searchIndexBuilt) {
            _buildSearchIndex(fullDataList);
            _searchIndexBuilt = true;
          }
          final queryLower = searchQuery.toLowerCase();
          List<T> filtered = [];
          if (queryLower.length == 2) {
            // Bigram lookup
            final indices = _bigramIndex[queryLower] ?? <int>{};
            final sortedIdx = indices.toList()..sort();
            filtered = sortedIdx.map((i) => fullDataList[i]).toList();
          } else {
            // Trigram intersection
            Set<int>? resultSet;
            for (int k = 0; k <= queryLower.length - 3; k++) {
              final gram = queryLower.substring(k, k + 3);
              final gramSet = _trigramIndex[gram] ?? <int>{};
              if (resultSet == null) {
                resultSet = gramSet.toSet();
              } else {
                resultSet = resultSet.intersection(gramSet);
              }
              if (resultSet.isEmpty) break;
            }
            if (resultSet != null && resultSet.isNotEmpty) {
              final sortedIdx = resultSet.toList()..sort();
              filtered = sortedIdx.map((i) => fullDataList[i]).toList();
            }
          }
          displayedData = filtered;
        }

        // Sort based on user-selected mode
        late final List<T> sortedData;
        switch (_sortMode) {
          case SortMode.highestPrice:
            sortedData = [...displayedData]
              ..sort((a, b) => b.price.compareTo(a.price));
            break;
          case SortMode.lowestPrice:
            sortedData = [...displayedData]
              ..sort((a, b) => a.price.compareTo(b.price));
            break;
          default:
            final favoriteItems = displayedData
                .where((item) => favorites.contains(item.id))
                .toList();
            final nonFavoriteItems = displayedData
                .where((item) => !favorites.contains(item.id))
                .toList();
            sortedData = [...favoriteItems, ...nonFavoriteItems];
        }

        if (sortedData.isEmpty) {
          return Center(
            child: Text(
              searchQuery.isNotEmpty ? l10n.searchNoResults : l10n.listNoData,
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

        return CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // iOS-style refresh control
            CupertinoSliverRefreshControl(
              refreshTriggerPullDistance: 100.0,
              refreshIndicatorExtent: 60.0,
              onRefresh: () => ref.read(widget.provider.notifier).refresh(),
            ),
            // Grid of assets
            SliverPadding(
              padding: const EdgeInsets.all(8.0),
              sliver: Directionality(
                // Always use LTR for grid layout regardless of language
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
                      final asset = sortedData[index];
                      // Add staggered animation to each card
                      return AnimatedCardBuilder(
                        index: index,
                        child: AssetCard(
                          asset: asset,
                          assetType: widget.assetType,
                        ),
                      );
                    },
                    childCount: sortedData.length,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (error, stack) {
        // Determine if this is a connection issue
        final isConnectionError = error.toString().contains('DioException') ||
            error.toString().contains('SocketException') ||
            error.toString().contains('TimeoutException');

        if (isConnectionError) {
          // For network errors, use our ErrorPlaceholder
          return const Center(
            child: ErrorPlaceholder(status: ConnectionStatus.serverDown),
          );
        }

        // For other errors, show minimal error UI
        return Center(
          child: CupertinoPopupSurface(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 25),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.exclamationmark_circle,
                    size: 32,
                    color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.errorGeneric,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: isRTL ? 'Vazirmatn' : 'SF-Pro',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CupertinoActivityIndicator(),
                      const SizedBox(width: 8),
                      Text(
                        l10n.retrying,
                        style: TextStyle(
                          fontFamily: isRTL ? 'Vazirmatn' : 'SF-Pro',
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Allow HomeScreen to change sorting mode
  void _setSortMode(SortMode mode) {
    setState(() {
      _sortMode = mode;
    });
  }
}
