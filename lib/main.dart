import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui; // Modified import

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vibration/vibration.dart';
import 'package:equatable/equatable.dart';
import 'package:smooth_corner/smooth_corner.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:url_launcher/url_launcher.dart';

// Hardcoded current app version
const String currentAppVersion = '0.140.0'; // Update this with each release

// region 0. Application Configuration (Constants and Models)

// endregion

// region 1. Providers (Riverpod State Management)

// --- Currency Unit Provider ---
enum CurrencyUnit { toman, usd, eur }

final currencyUnitProvider =
    StateNotifierProvider<CurrencyUnitNotifier, CurrencyUnit>((ref) {
  return CurrencyUnitNotifier();
});

class CurrencyUnitNotifier extends StateNotifier<CurrencyUnit> {
  CurrencyUnitNotifier() : super(CurrencyUnit.toman) {
    // Default to Toman
    _loadCurrencyUnitPreference();
  }

  Future<void> _loadCurrencyUnitPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final unitString = prefs.getString('currencyUnit');
    if (unitString != null) {
      state = CurrencyUnit.values.firstWhere(
        (e) => e.toString() == unitString,
        orElse: () => CurrencyUnit.toman,
      );
    }
  }

  Future<void> setCurrencyUnit(CurrencyUnit unit) async {
    state = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currencyUnit', unit.toString());
  }
}

// --- Favorites Provider ---
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>(
  (ref) {
    return FavoritesNotifier();
  },
);

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super({}) {
    _loadFavorites();
  }

  static const _favoritesKey = 'favorite_assets';

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteList = prefs.getStringList(_favoritesKey);
    if (favoriteList != null) {
      state = favoriteList.toSet();
    }
  }

  Future<void> toggleFavorite(String assetId) async {
    final newFavorites = Set<String>.from(state);
    if (newFavorites.contains(assetId)) {
      newFavorites.remove(assetId);
    } else {
      newFavorites.add(assetId);
    }
    state = newFavorites;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, newFavorites.toList());

    // Haptic feedback
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100);
    }
  }

  bool isFavorite(String assetId) => state.contains(assetId);
}

// --- API Service Provider ---
final dioProvider = Provider<Dio>((ref) => Dio());

final apiServiceProvider = Provider<ApiService>((ref) {
  final dio = ref.watch(dioProvider);
  final config = ref.watch(appConfigProvider).asData?.value;
  if (config == null) {
    // This should ideally not happen if appConfigProvider is handled correctly at app start
    throw Exception("AppConfig not available for ApiService");
  }
  return ApiService(dio, config.apiEndpoints);
});

// --- Data Providers for each asset type ---
// --- Data Fetching Notifiers ---
// Generic Data Fetcher Notifier
abstract class DataFetcherNotifier<T extends models.Asset>
    extends StateNotifier<AsyncValue<List<T>>> {
  final ApiService _apiService;
  final String _cacheKey;
  final config.AppConfig _appConfig;
  final String _initialUrl;
  bool _initialized = false;
  List<T> _fullDataList = [];
  int _currentlyLoadedCount = 0;
  Timer? _updateTimer;

  DataFetcherNotifier(
    this._apiService,
    this._cacheKey,
    this._appConfig,
    this._initialUrl,
  ) : super(const AsyncValue.loading()) {
    _currentlyLoadedCount = _appConfig.initialItemsToLoad;
    // Data will load when initialize() is called.
  }

  Future<void> initialize() async {
    if (!_initialized) {
      _initialized = true;

      // Check connection before trying to fetch data
      final connectionService = ConnectionService();
      final isOnline = await connectionService.checkConnection(_initialUrl);

      if (isOnline) {
        await fetchData(_initialUrl);
        _startAutoRefresh(_initialUrl);
      } else {
        // Load cached data if available
        final cachedData = await _loadCachedData();
        if (cachedData.isNotEmpty) {
          _fullDataList = cachedData;
          state = AsyncValue.data(
            _fullDataList.take(_currentlyLoadedCount).toList(),
          );
        } else {
          // Show offline error
          state = const AsyncValue.error("Offline", StackTrace.empty);
        }
      }
    } else {
      // Already initialized, just ensure state is refreshed with current data
      if (_fullDataList.isNotEmpty) {
        state = AsyncValue.data(
          _fullDataList.take(_currentlyLoadedCount).toList(),
        );
      }
    }
  }

  Future<void> refresh() async {
    await fetchData(_initialUrl, isRefresh: true);
  }

  Future<void> fetchData(String url, {bool isRefresh = false}) async {
    if (!isRefresh) {
      state = const AsyncValue.loading();
    }

    // Check connection first
    final connectionService = ConnectionService();
    final isConnected = await connectionService.checkConnection(url);

    if (!isConnected) {
      final cachedData = await _loadCachedData();
      if (cachedData.isNotEmpty) {
        _fullDataList = cachedData;
        state = AsyncValue.data(
          _fullDataList.take(_currentlyLoadedCount).toList(),
        );
        return;
      }

      // No cached data, show offline state
      return;
    }

    try {
      final List<T> previousData = state.asData?.value ?? [];
      final fetchedData = await _fetchAndParse(url);

      // Store the complete fetched data
      _fullDataList = _applyPriority(_sortData(fetchedData));

      // Debug log - verify we're getting all items
      print(
        "DEBUG: Fetched ${_fullDataList.length} items for ${url.split('/').last}",
      );

      // Compare with previous for change indication (simplified)
      final List<T> updatedDisplayList =
          _fullDataList.take(_currentlyLoadedCount).map((newItem) {
        final oldItem = previousData.firstWhere(
          (old) => old.id == newItem.id,
          orElse: () => newItem,
        );
        return newItem; // Assuming API data already has change %
      }).toList();

      state = AsyncValue.data(updatedDisplayList);
      await _cacheData(_fullDataList); // Cache the full list
    } catch (e, s) {
      final cachedData = await _loadCachedData();
      if (cachedData.isNotEmpty) {
        _fullDataList = cachedData;
        state = AsyncValue.data(
          _fullDataList.take(_currentlyLoadedCount).toList(),
        );
      } else {
        state = AsyncValue.error(e, s);
      }
    }
  }

  List<T> _sortData(List<T> data) {
    // Default sort: could be by name or market cap if available
    // For now, API order is preserved, or implement custom sort logic here
    return data;
  }

  List<T> _applyPriority(List<T> data) {
    // Placeholder for priority sorting based on priority_assets.json
    // This needs fetching and parsing priority_assets.json
    // For now, returns data as is.
    return data;
  }

  Future<List<T>> _fetchAndParse(String url); // To be implemented by subclasses

  void loadMore() {
    if (_currentlyLoadedCount < _fullDataList.length) {
      // Store old index for animation
      final oldCount = _currentlyLoadedCount;
      _currentlyLoadedCount = math.min(
        _fullDataList.length,
        _currentlyLoadedCount + _appConfig.itemsPerLazyLoad,
      );

      // Add a slight delay before showing new items to ensure smooth animation
      Future.delayed(const Duration(milliseconds: 100), () {
        state = AsyncValue.data(
          _fullDataList.take(_currentlyLoadedCount).toList(),
        );
      });
    }
  }

  Future<void> _cacheData(List<T> data) async {
    // Simple caching using SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonDataList = data.map((item) {
        if (item is CurrencyAsset) {
          return {
            'id': item.id,
            'name': item.name,
            'symbol': item.symbol,
            'price': item.price,
          };
        } else if (item is GoldAsset) {
          return {
            'id': item.id,
            'name': item.name,
            'symbol': item.symbol,
            'price': item.price,
          };
        } else if (item is CryptoAsset) {
          return {
            'id': item.id,
            'name': item.name,
            'symbol': item.symbol,
            'price': item.price,
          };
        } else if (item is StockAsset) {
          return {
            'id': item.id,
            'name': item.name,
            'symbol': item.symbol,
            'price': item.price,
          };
        }
        return {};
      }).toList();

      await prefs.setString('cache_$_cacheKey', jsonEncode(jsonDataList));
    } catch (e) {
      // Ignore cache errors
    }
  }

  Future<List<T>> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('cache_$_cacheKey');

      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonDataList = jsonDecode(jsonString);
        // Here we'd need type-specific deserialization based on T
        // This is a simplified version
        return jsonDataList.map((item) {
          if (T == CurrencyAsset) {
            return CurrencyAsset(
              id: item['id'],
              name: item['name'],
              nameEn: item['name'],
              symbol: item['symbol'],
              price: item['price'].toDouble(),
              unit: 'تومان',
            ) as T;
          } else if (T == GoldAsset) {
            return GoldAsset(
              id: item['id'],
              name: item['name'],
              nameEn: item['name'],
              symbol: item['symbol'],
              price: item['price'].toDouble(),
              unit: 'تومان',
            ) as T;
          } else if (T == CryptoAsset) {
            return CryptoAsset(
              id: item['id'],
              name: item['name'],
              nameFa: item['name'],
              symbol: item['symbol'],
              price: item['price'].toDouble(),
              priceToman: item['price'].toString(),
            ) as T;
          } else if (T == StockAsset) {
            return StockAsset(
              item['id'],
              item['price'].toDouble(),
              id: item['id'],
              name: item['name'],
              l30: item['name'],
              symbol: item['symbol'],
              price: item['price'].toDouble(),
            ) as T;
          }
          throw Exception('Unsupported type');
        }).toList();
      }
    } catch (e) {
      // Ignore cache errors
    }
    return [];
  }

  void _startAutoRefresh(String url) {
    _updateTimer?.cancel();
    // Use priceUpdateIntervalMinutes instead of updateIntervalMs which is inconsistently defined
    final updateIntervalMs = _appConfig.priceUpdateIntervalMinutes * 60 * 1000;
    print(
      "DEBUG: Setting auto-refresh interval to ${_appConfig.priceUpdateIntervalMinutes} minutes",
    );
    _updateTimer = Timer.periodic(Duration(milliseconds: updateIntervalMs), (
      timer,
    ) {
      fetchData(url, isRefresh: true);
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
}

// Specific Notifiers
class CurrencyNotifier extends DataFetcherNotifier<models.CurrencyAsset> {
  CurrencyNotifier(ApiService apiService, config.AppConfig appConfig)
      : super(
          apiService,
          'currency_cache',
          appConfig,
          appConfig.apiEndpoints.currencyUrl,
        );

  @override
  Future<List<models.CurrencyAsset>> _fetchAndParse(String url) async {
    final responseData = await _apiService.fetchData(url);
    List<models.CurrencyAsset> assets = [];
    if (responseData is Map && responseData.containsKey('currency')) {
      assets = (responseData['currency'] as List)
          .map(
            (item) =>
                models.CurrencyAsset.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }
    // Load priority list for currency
    List<String> priorityList = [];
    try {
      final dyn = await _apiService.fetchData(
        _appConfig.apiEndpoints.priorityAssetsUrl,
      );
      if (dyn is Map<String, dynamic>) {
        priorityList = List<String>.from(
          dyn['currency'] as List<dynamic>? ?? [],
        );
      }
    } catch (_) {}
    // Apply priority: items in priorityList first, then others
    final priorityAssets = <models.CurrencyAsset>[];
    final otherAssets = <models.CurrencyAsset>[];
    for (final symbol in priorityList) {
      priorityAssets.addAll(assets.where((a) => a.symbol == symbol));
    }
    for (final asset in assets) {
      if (!priorityAssets.contains(asset)) {
        otherAssets.add(asset);
      }
    }
    return [...priorityAssets, ...otherAssets];
  }
}

final currencyProvider = StateNotifierProvider<CurrencyNotifier,
    AsyncValue<List<models.CurrencyAsset>>>((
  ref,
) {
  final apiService = ref.watch(apiServiceProvider);
  final appConfig = ref.watch(appConfigProvider).asData!.value;
  return CurrencyNotifier(apiService, appConfig);
});

class GoldNotifier extends DataFetcherNotifier<models.GoldAsset> {
  GoldNotifier(ApiService apiService, config.AppConfig appConfig)
      : super(
          apiService,
          'gold_cache',
          appConfig,
          appConfig.apiEndpoints.goldUrl,
        );

  @override
  Future<List<models.GoldAsset>> _fetchAndParse(String url) async {
    // Fetch local gold prices
    final List<models.GoldAsset> goldAssets = [];
    final goldResponseData = await _apiService.fetchData(url);
    if (goldResponseData is Map && goldResponseData.containsKey('gold')) {
      goldAssets.addAll(
        (goldResponseData['gold'] as List)
            .map((item) =>
                models.GoldAsset.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    }
    // Fetch commodity data: precious metals, base metals, and energy
    final List<models.GoldAsset> commodityAssets = [];
    final commodityUrl = _appConfig.apiEndpoints.commodityUrl;
    if (commodityUrl.isNotEmpty) {
      final commodityResponseData = await _apiService.fetchData(commodityUrl);
      if (commodityResponseData is Map) {
        final preciousList =
            commodityResponseData['metal_precious'] as List<dynamic>? ?? [];
        final baseList =
            commodityResponseData['metal_base'] as List<dynamic>? ?? [];
        final energyList =
            commodityResponseData['energy'] as List<dynamic>? ?? [];
        commodityAssets.addAll(
          preciousList
              .map(
                (item) => models.GoldAsset.fromJson(
                  item as Map<String, dynamic>,
                  isCommodity: true,
                ),
              )
              .toList(),
        );
        commodityAssets.addAll(
          baseList
              .map(
                (item) => models.GoldAsset.fromJson(
                  item as Map<String, dynamic>,
                  isCommodity: true,
                ),
              )
              .toList(),
        );
        commodityAssets.addAll(
          energyList
              .map(
                (item) => models.GoldAsset.fromJson(
                  item as Map<String, dynamic>,
                  isCommodity: true,
                ),
              )
              .toList(),
        );
      }
    }
    // Combine gold and commodity assets, avoiding duplicates by symbol
    final List<models.GoldAsset> combinedAssets = [];
    final Set<String> seen = {};
    for (final asset in goldAssets) {
      if (seen.add(asset.id)) {
        combinedAssets.add(asset);
      }
    }
    for (final asset in commodityAssets) {
      if (seen.add(asset.id)) {
        combinedAssets.add(asset);
      }
    }
    // Load priority lists for gold and commodity
    List<String> goldPriorityList = [];
    List<String> commodityPriorityList = [];
    try {
      final dyn = await _apiService.fetchData(
        _appConfig.apiEndpoints.priorityAssetsUrl,
      );
      if (dyn is Map<String, dynamic>) {
        goldPriorityList = List<String>.from(
          dyn['gold'] as List<dynamic>? ?? [],
        );
        commodityPriorityList = List<String>.from(
          dyn['commodity'] as List<dynamic>? ?? [],
        );
      }
    } catch (_) {}
    // Apply priority: gold first, then commodity, then others
    final goldPriorityAssets = <models.GoldAsset>[];
    final remainingAssets = <models.GoldAsset>[];
    for (final symbol in goldPriorityList) {
      goldPriorityAssets.addAll(
        combinedAssets.where((a) => a.symbol == symbol),
      );
    }
    for (final asset in combinedAssets) {
      if (!goldPriorityAssets.contains(asset)) {
        remainingAssets.add(asset);
      }
    }
    final commodityPriorityAssets = <models.GoldAsset>[];
    final otherAssets = <models.GoldAsset>[];
    for (final symbol in commodityPriorityList) {
      commodityPriorityAssets.addAll(
        remainingAssets.where(
          (a) => a.symbol.toLowerCase() == symbol.toLowerCase(),
        ),
      );
    }
    for (final asset in remainingAssets) {
      if (!commodityPriorityAssets.contains(asset)) {
        otherAssets.add(asset);
      }
    }
    return [...goldPriorityAssets, ...commodityPriorityAssets, ...otherAssets];
  }
}

final goldProvider =
    StateNotifierProvider<GoldNotifier, AsyncValue<List<models.GoldAsset>>>((
  ref,
) {
  final apiService = ref.watch(apiServiceProvider);
  final appConfig = ref.watch(appConfigProvider).asData!.value;
  return GoldNotifier(apiService, appConfig);
});

class CryptoNotifier extends DataFetcherNotifier<models.CryptoAsset> {
  CryptoNotifier(ApiService apiService, config.AppConfig appConfig)
      : super(
          apiService,
          'crypto_cache',
          appConfig,
          appConfig.apiEndpoints.cryptoUrl,
        );

  @override
  Future<List<models.CryptoAsset>> _fetchAndParse(String url) async {
    final responseData = await _apiService.fetchData(url);
    if (responseData is List) {
      // Parse all crypto assets
      final assets = responseData
          .map((item) =>
              models.CryptoAsset.fromJson(item as Map<String, dynamic>))
          .toList();
      // Load priority list for crypto
      List<String> priorityList = [];
      try {
        final dyn = await _apiService.fetchData(
          _appConfig.apiEndpoints.priorityAssetsUrl,
        );
        if (dyn is Map<String, dynamic>) {
          priorityList = List<String>.from(
            dyn['crypto'] as List<dynamic>? ?? <dynamic>[],
          );
        }
      } catch (_) {}
      // Partition assets into iconed (custom icons) and non-iconed
      final iconed = <models.CryptoAsset>[];
      final nonIconed = <models.CryptoAsset>[];
      for (final asset in assets) {
        if (_cryptoIconMap.containsKey(asset.name.toLowerCase())) {
          iconed.add(asset);
        } else {
          nonIconed.add(asset);
        }
      }
      // Within iconed, order by priorityList, then others
      final iconedPriority = <models.CryptoAsset>[];
      final iconedOthers = <models.CryptoAsset>[];
      for (final name in priorityList) {
        final matches = iconed.where((a) => a.name == name);
        iconedPriority.addAll(matches);
      }
      for (final a in iconed) {
        if (!iconedPriority.contains(a)) iconedOthers.add(a);
      }
      // Within non-iconed, order priorityList, then others
      final nonIconedPriority = <models.CryptoAsset>[];
      final nonIconedOthers = <models.CryptoAsset>[];
      for (final name in priorityList) {
        final matches = nonIconed.where((a) => a.name == name);
        nonIconedPriority.addAll(matches);
      }
      for (final a in nonIconed) {
        if (!nonIconedPriority.contains(a)) nonIconedOthers.add(a);
      }
      // Combine lists: iconed priority, iconed others, non-iconed priority, non-iconed others
      return <models.CryptoAsset>[
        ...iconedPriority,
        ...iconedOthers,
        ...nonIconedPriority,
        ...nonIconedOthers,
      ];
    }
    return <models.CryptoAsset>[];
  }
}

final cryptoProvider = StateNotifierProvider<CryptoNotifier,
    AsyncValue<List<models.CryptoAsset>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final appConfig = ref.watch(appConfigProvider).asData!.value;
  return CryptoNotifier(apiService, appConfig);
});

// Stock Notifiers (one for each sub-category)
class StockTseIfbNotifier extends DataFetcherNotifier<models.StockAsset> {
  StockTseIfbNotifier(ApiService apiService, config.AppConfig appConfig)
      : super(
          apiService,
          'stock_tse_ifb_cache',
          appConfig,
          appConfig.apiEndpoints.stockTseIfbSymbolsUrl,
        );
  @override
  Future<List<models.StockAsset>> _fetchAndParse(String url) async {
    final responseData = await _apiService.fetchData(url);
    if (responseData is List) {
      final assets = responseData
          .map((item) =>
              models.StockAsset.fromJson(item as Map<String, dynamic>))
          .toList();
      // Load priority list for TSE/IFB symbols
      List<String> priorityList = [];
      try {
        final dyn = await _apiService.fetchData(
          _appConfig.apiEndpoints.priorityAssetsUrl,
        );
        if (dyn is Map<String, dynamic>) {
          priorityList = List<String>.from(
            dyn['stock_tse_ifb_symbols'] as List<dynamic>? ?? [],
          );
        }
      } catch (_) {}
      // Apply priority: items in priorityList first, then others
      final priorityAssets = <models.StockAsset>[];
      final otherAssets = <models.StockAsset>[];
      for (final symbol in priorityList) {
        priorityAssets.addAll(assets.where((a) => a.symbol == symbol));
      }
      for (final asset in assets) {
        if (!priorityAssets.contains(asset)) {
          otherAssets.add(asset);
        }
      }
      return [...priorityAssets, ...otherAssets];
    }
    return [];
  }
}

final stockTseIfbProvider = StateNotifierProvider<StockTseIfbNotifier,
    AsyncValue<List<models.StockAsset>>>((
  ref,
) {
  final apiService = ref.watch(apiServiceProvider);
  final appConfig = ref.watch(appConfigProvider).asData!.value;
  return StockTseIfbNotifier(apiService, appConfig);
});

class StockDebtSecuritiesNotifier
    extends DataFetcherNotifier<models.StockAsset> {
  StockDebtSecuritiesNotifier(
    ApiService apiService,
    config.AppConfig appConfig,
  ) : super(
          apiService,
          'stock_debt_cache',
          appConfig,
          appConfig.apiEndpoints.stockDebtSecuritiesUrl,
        );
  @override
  Future<List<models.StockAsset>> _fetchAndParse(String url) async {
    final responseData = await _apiService.fetchData(url);
    if (responseData is List) {
      final assets = responseData
          .map((item) =>
              models.StockAsset.fromJson(item as Map<String, dynamic>))
          .toList();
      // Load priority list for debt securities
      List<String> priorityList = [];
      try {
        final dyn = await _apiService.fetchData(
          _appConfig.apiEndpoints.priorityAssetsUrl,
        );
        if (dyn is Map<String, dynamic>) {
          priorityList = List<String>.from(
            dyn['stock_debt_securities'] as List<dynamic>? ?? [],
          );
        }
      } catch (_) {}
      // Apply priority: items in priorityList first, then others
      final priorityAssets = <models.StockAsset>[];
      final otherAssets = <models.StockAsset>[];
      for (final symbol in priorityList) {
        priorityAssets.addAll(assets.where((a) => a.symbol == symbol));
      }
      for (final asset in assets) {
        if (!priorityAssets.contains(asset)) {
          otherAssets.add(asset);
        }
      }
      return [...priorityAssets, ...otherAssets];
    }
    return [];
  }
}

final stockDebtSecuritiesProvider = StateNotifierProvider<
    StockDebtSecuritiesNotifier, AsyncValue<List<models.StockAsset>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final appConfig = ref.watch(appConfigProvider).asData!.value;
  return StockDebtSecuritiesNotifier(apiService, appConfig);
});

class StockFuturesNotifier extends DataFetcherNotifier<models.StockAsset> {
  StockFuturesNotifier(ApiService apiService, config.AppConfig appConfig)
      : super(
          apiService,
          'stock_futures_cache',
          appConfig,
          appConfig.apiEndpoints.stockFuturesUrl,
        );
  @override
  Future<List<models.StockAsset>> _fetchAndParse(String url) async {
    final responseData = await _apiService.fetchData(url);
    if (responseData is List) {
      final assets = responseData
          .map((item) =>
              models.StockAsset.fromJson(item as Map<String, dynamic>))
          .toList();
      // Load priority list for futures
      List<String> priorityList = [];
      try {
        final dyn = await _apiService.fetchData(
          _appConfig.apiEndpoints.priorityAssetsUrl,
        );
        if (dyn is Map<String, dynamic>) {
          priorityList = List<String>.from(
            dyn['stock_futures'] as List<dynamic>? ?? [],
          );
        }
      } catch (_) {}
      // Apply priority: items in priorityList first, then others
      final priorityAssets = <models.StockAsset>[];
      final otherAssets = <models.StockAsset>[];
      for (final symbol in priorityList) {
        priorityAssets.addAll(assets.where((a) => a.symbol == symbol));
      }
      for (final asset in assets) {
        if (!priorityAssets.contains(asset)) {
          otherAssets.add(asset);
        }
      }
      return [...priorityAssets, ...otherAssets];
    }
    return [];
  }
}

final stockFuturesProvider = StateNotifierProvider<StockFuturesNotifier,
    AsyncValue<List<models.StockAsset>>>((
  ref,
) {
  final apiService = ref.watch(apiServiceProvider);
  final appConfig = ref.watch(appConfigProvider).asData!.value;
  return StockFuturesNotifier(apiService, appConfig);
});

class StockHousingFacilitiesNotifier
    extends DataFetcherNotifier<models.StockAsset> {
  StockHousingFacilitiesNotifier(
    ApiService apiService,
    config.AppConfig appConfig,
  ) : super(
          apiService,
          'stock_housing_cache',
          appConfig,
          appConfig.apiEndpoints.stockHousingFacilitiesUrl,
        );
  @override
  Future<List<models.StockAsset>> _fetchAndParse(String url) async {
    final responseData = await _apiService.fetchData(url);
    if (responseData is List) {
      final assets = responseData
          .map((item) =>
              models.StockAsset.fromJson(item as Map<String, dynamic>))
          .toList();
      // Load priority list for housing facilities
      List<String> priorityList = [];
      try {
        final dyn = await _apiService.fetchData(
          _appConfig.apiEndpoints.priorityAssetsUrl,
        );
        if (dyn is Map<String, dynamic>) {
          priorityList = List<String>.from(
            dyn['stock_housing_facilities'] as List<dynamic>? ?? [],
          );
        }
      } catch (_) {}
      // Apply priority: items in priorityList first, then others
      final priorityAssets = <models.StockAsset>[];
      final otherAssets = <models.StockAsset>[];
      for (final symbol in priorityList) {
        priorityAssets.addAll(assets.where((a) => a.symbol == symbol));
      }
      for (final asset in assets) {
        if (!priorityAssets.contains(asset)) {
          otherAssets.add(asset);
        }
      }
      return [...priorityAssets, ...otherAssets];
    }
    return [];
  }
}

final stockHousingFacilitiesProvider = StateNotifierProvider<
    StockHousingFacilitiesNotifier, AsyncValue<List<models.StockAsset>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final appConfig = ref.watch(appConfigProvider).asData!.value;
  return StockHousingFacilitiesNotifier(apiService, appConfig);
});

// Search Query Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// --- Card Corner Settings Provider ---
class CardCornerSettings {
  final double radius;
  final double smoothness;

  CardCornerSettings({required this.radius, required this.smoothness});

  CardCornerSettings copyWith({double? radius, double? smoothness}) {
    return CardCornerSettings(
      radius: radius ?? this.radius,
      smoothness: smoothness ?? this.smoothness,
    );
  }
}

final cardCornerSettingsProvider =
    StateNotifierProvider<CardCornerSettingsNotifier, config.CardCornerSettings>(
        (ref) {
  final appConfig = ref.watch(appConfigProvider).asData?.value ??
      config.AppConfig.defaultConfig();
  return CardCornerSettingsNotifier(
    config.CardCornerSettings(
      radius: appConfig.themeOptions.light.cardBorderRadius,
      smoothness: appConfig.themeOptions.light.cardCornerSmoothness,
    ),
  );
});

class CardCornerSettingsNotifier
    extends StateNotifier<config.CardCornerSettings> {
  CardCornerSettingsNotifier(super.initial) {
    _loadSettings();
  }

  static const _radiusKey = 'card_corner_radius';
  static const _smoothnessKey = 'card_corner_smoothness';

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final radius = prefs.getDouble(_radiusKey);
      final smoothness = prefs.getDouble(_smoothnessKey);

      if (radius != null && smoothness != null) {
        state =
            config.CardCornerSettings(radius: radius, smoothness: smoothness);
      }
    } catch (e) {
      // Fallback to default if loading fails
    }
  }

  Future<void> updateRadius(double radius) async {
    state = state.copyWith(radius: radius);
    _saveSettings();
  }

  Future<void> updateSmoothness(double smoothness) async {
    state = state.copyWith(smoothness: smoothness);
    _saveSettings();
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_radiusKey, state.radius);
      await prefs.setDouble(_smoothnessKey, state.smoothness);
    } catch (e) {
      // Handle error
    }
  }
}
// endregion

// region 2. API Service
class ApiService {
  final Dio _dio;
  final config.ApiEndpoints
      _apiEndpoints; // Not used directly here, but good for context

  ApiService(this._dio, this._apiEndpoints);

  Future<dynamic> fetchData(String url) async {
    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        // Check if response.data is already a Map/List or a String needing decode
        if (response.data is String) {
          return jsonDecode(response.data as String);
        }
        return response
            .data; // Assuming it's already parsed by Dio (e.g. if responseType is JSON)
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'API request failed with status code ${response.statusCode}',
        );
      }
    } on DioException {
      // Handle Dio specific errors (network, timeout, etc.)
      // print_error('DioException in ApiService for $url: ${e.message}');
      // You might want to log this error to a service
      // For self-healing: if (e.type == DioExceptionType.connectionTimeout) { searchOnline("Dio connection timeout fix"); }
      rethrow; // Rethrow to be caught by the DataFetcherNotifier
    } catch (e) {
      // Handle other errors
      // print_error('Generic error in ApiService for $url: $e');
      rethrow;
    }
  }
}
// endregion

// region 3. Main Application & Entry Point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Load saved theme preference before app start
  final prefs = await SharedPreferences.getInstance();
  final isDarkModePref = prefs.getBool('isDarkMode');
  final initialThemeMode = isDarkModePref == null
      ? null
      : (isDarkModePref ? ThemeMode.dark : ThemeMode.light);
  // Initialize ConnectionService singleton
  final connectionService = ConnectionService();

  runApp(
    ProviderScope(
      overrides: [
        if (initialThemeMode != null)
          themeNotifierProvider.overrideWithProvider(
            StateNotifierProvider<ThemeNotifier, ThemeMode>(
              (ref) => ThemeNotifier(initialThemeMode),
            ),
          ),
      ],
      child: ScrollConfiguration(
        behavior: ui_theme.SmoothScrollBehavior(),
        child: const RiyalesApp(),
      ),
    ),
  );
}

class RiyalesApp extends ConsumerStatefulWidget {
  const RiyalesApp({super.key});

  @override
  ConsumerState<RiyalesApp> createState() => _RiyalesAppState();
}

class _RiyalesAppState extends ConsumerState<RiyalesApp> {
  @override
  void initState() {
    super.initState();

    // Initialize connection service after app loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appConfig = ref.read(appConfigProvider).asData?.value;
      if (appConfig != null) {
        final apiUrl = appConfig.apiEndpoints.currencyUrl;
        ConnectionService().initialize(apiUrl);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appConfigAsync = ref.watch(appConfigProvider);
    final themeMode = ref.watch(themeNotifierProvider);
    final currentLocale = ref.watch(localeNotifierProvider);

    // Apply hoverColor: Colors.transparent to all hover effects globally
    final materialTheme = Theme.of(context);
    final themeData = materialTheme.copyWith(
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );

    return Theme(
      data: themeData,
      child: appConfigAsync.when(
        data: (config) {
          final String lightFontFamily = currentLocale.languageCode == 'fa'
              ? config.fonts.persianFontFamily
              : config.fonts.englishFontFamily;
          final String darkFontFamily = currentLocale.languageCode == 'fa'
              ? config.fonts.persianFontFamily
              : config.fonts.englishFontFamily;

          // Determine the font for AppBar titles based on locale (Vazirmatn for FA, Onest otherwise)
          final String titleFontFamily =
              currentLocale.languageCode == 'fa' ? 'Vazirmatn' : 'Onest';

          final ThemeData lightTheme = ui_theme.AppTheme.getThemeData(
            config.themeOptions.light,
            lightFontFamily,
            titleFontFamily, // Pass the specific title font
            false, // isDarkMode
          );
          final ThemeData darkTheme = ui_theme.AppTheme.getThemeData(
            config.themeOptions.dark,
            darkFontFamily,
            titleFontFamily, // Pass the specific title font
            true, // isDarkMode
          );

          return MaterialApp(
            title: config.appName, // Reverted to use config.appName
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeMode,
            // Smooth theme switching with fade and curve
            builder: (context, child) {
              return AnimatedTheme(
                data: Theme.of(context),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutQuart,
                child: child!,
              );
            },
            locale: currentLocale,
            supportedLocales: config.supportedLocales.map((loc) => Locale(loc)),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            debugShowCheckedModeBanner: false,
            home: SplashScreen(config: config.splashScreen),
          );
        },
        loading: () => const MaterialApp(
          home: Scaffold(body: Center(child: CupertinoActivityIndicator())),
        ),
        error: (error, stackTrace) => MaterialApp(
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Failed to load app configuration: $error\nPlease restart the app or check your internet connection.',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// endregion

// region 4. Splash Screen
class SplashScreen extends StatefulWidget {
  final config.SplashScreenConfig config;
  const SplashScreen({super.key, required this.config});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
      Duration(milliseconds: (widget.config.durationSeconds * 1000).toInt()),
      () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    // Select SVG image based on theme
    final imagePath = isDarkMode
        ? 'assets/images/splash-screen-dark.svg'
        : 'assets/images/splash-screen-light.svg';

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF121212) // Dark theme background
          : Colors.white, // Light theme background
      body: SafeArea(
        child: Column(
          children: [
            // Top 1/3 empty space
            SizedBox(height: screenHeight * 0.15),

            // App icon in upper 1/3
            Center(
              child: SvgPicture.asset(
                imagePath,
                width: 80,
                height: 80,
              ),
            ),

            // Push loading indicator to bottom 1/3
            const Spacer(),

            // iOS-style loading indicator at bottom
            Padding(
              padding: EdgeInsets.only(bottom: screenHeight * 0.15),
              child: CupertinoActivityIndicator(
                radius: 12,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// endregion

// region 5. Home Screen & Main Tabs
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin<HomeScreen> {
  late TabController _tabController;
  final List<Tab> _mainTabs = [];
  final List<Widget> _mainTabViews = [];
  ConnectionStatus _connectionStatus = ConnectionStatus.connected;
  late StreamSubscription<ConnectionStatus> _connectionSubscription;
  bool _showSearchBar = false;
  bool _isSearchActive =
      false; // Track if search is active, separate from visibility
  bool _tabListenerAdded = false;
  // Map to store scroll controllers for each tab
  final Map<int, ScrollController?> _tabScrollControllers = {};
  // Map to store scroll listeners for each tab
  final Map<int, void Function()> _tabScrollListeners = {};
  // Global keys for tab pages
  final currencyTabKey = GlobalKey<_AssetListPageState<models.CurrencyAsset>>();
  final goldTabKey = GlobalKey<_AssetListPageState<models.GoldAsset>>();
  final cryptoTabKey = GlobalKey<_AssetListPageState<models.CryptoAsset>>();
  final stockTabKey = GlobalKey<_StockPageState>();

  // Method to set up scroll listener for auto-hiding search bar
  void _setupScrollListener(int tabIndex) {
    // Remove any existing listener first
    if (_tabScrollListeners.containsKey(tabIndex)) {
      final controller = _tabScrollControllers[tabIndex];
      if (controller != null) {
        controller.removeListener(_tabScrollListeners[tabIndex]!);
      }
      _tabScrollListeners.remove(tabIndex);
    }

    // Create and add new listener
    final controller = _findScrollController(tabIndex);
    if (controller != null && controller.hasClients) {
      void listener() {
        // Only care about scroll events when search is active
        if (_isSearchActive) {
          if (controller.offset <= 0) {
            // At the top, show search bar if it's not already visible
            if (!_showSearchBar) {
              setState(() {
                _showSearchBar = true;
              });
            }
          } else {
            // Scrolled down, hide search bar if it's visible
            if (_showSearchBar) {
              setState(() {
                _showSearchBar = false;
              });
            }
          }
        }
      }

      controller.addListener(listener);
      _tabScrollListeners[tabIndex] = listener;
    }
  }

  void _initializeTab(int index) {
    switch (index) {
      case 0:
        ref.read(currencyProvider.notifier).initialize();
        // Capture scroll controller for currency tab
        _tabScrollControllers[0] = _findScrollController(index);
        _setupScrollListener(0);
        break;
      case 1:
        ref.read(goldProvider.notifier).initialize();
        // Capture scroll controller for gold tab
        _tabScrollControllers[1] = _findScrollController(index);
        _setupScrollListener(1);
        break;
      case 2:
        ref.read(cryptoProvider.notifier).initialize();
        // Capture scroll controller for crypto tab
        _tabScrollControllers[2] = _findScrollController(index);
        _setupScrollListener(2);
        break;
      case 3:
        // Initialize the primary stock list when Stock tab is selected
        ref.read(stockTseIfbProvider.notifier).initialize();
        // Capture scroll controller for stock tab
        _tabScrollControllers[3] = _findScrollController(index);
        _setupScrollListener(3);
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Listen for connection status changes
    _connectionSubscription = ConnectionService().statusStream.listen((status) {
      setState(() {
        _connectionStatus = status;
      });
    });
    // _setupTabs();
  }

  // Add listener to locale changes
  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset listener state and scroll controllers on locale or widget change
    _tabListenerAdded = false;
    _tabScrollControllers.clear();

    // Wait for build to complete before re-initializing tabs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_tabController.hasListeners) {
        // Re-initialize the current tab
        _initializeTab(_tabController.index);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Only refresh the active tab's data when app is resumed
      final currentTabIndex = _tabController.index;
      switch (currentTabIndex) {
        case 0:
          ref.read(currencyProvider.notifier).refresh();
          break;
        case 1:
          ref.read(goldProvider.notifier).refresh();
          break;
        case 2:
          ref.read(cryptoProvider.notifier).refresh();
          break;
        case 3:
          // For the stock tab, only refresh the active stock sub-tab
          final stockPage = _mainTabViews[3] as StockPage;
          final stockState = stockPage.key as GlobalKey<_StockPageState>;
          final state = stockState.currentState;
          if (state != null) {
            // Get active stock tab index
            final activeStockTabIndex = state._stockTabController.index;
            switch (activeStockTabIndex) {
              case 0:
                ref.read(stockTseIfbProvider.notifier).refresh();
                break;
              case 1:
                ref.read(stockDebtSecuritiesProvider.notifier).refresh();
                break;
              case 2:
                ref.read(stockFuturesProvider.notifier).refresh();
                break;
              case 3:
                ref.read(stockHousingFacilitiesProvider.notifier).refresh();
                break;
            }
          }
          break;
      }
    }
  }

  // Setup tabs based on current localization
  void _setupTabs() {
    if (!mounted) return;

    _mainTabs.clear();
    _mainTabViews.clear();

    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    _mainTabs.addAll([
      Tab(text: l10n.tabCurrency),
      Tab(text: l10n.tabGold),
      Tab(text: l10n.tabCrypto),
      Tab(text: l10n.tabStock),
    ]);

    _mainTabViews.addAll([
      AssetListPage<models.CurrencyAsset>(
        key: currencyTabKey,
        provider: currencyProvider,
        assetType: AssetType.currency,
      ),
      AssetListPage<models.GoldAsset>(
        key: goldTabKey,
        provider: goldProvider,
        assetType: AssetType.gold,
      ),
      AssetListPage<models.CryptoAsset>(
        key: cryptoTabKey,
        provider: cryptoProvider,
        assetType: AssetType.crypto,
      ),
      StockPage(
        key: stockTabKey,
        showSearchBar: _showSearchBar,
        isSearchActive: _isSearchActive,
      ), // Stock page has its own internal tabs
    ]);

    // Initialize tab controller with proper null check
    try {
      if (mounted) {
        // Save current tab index if possible before reinitializing
        int currentIndex = 0;
        try {
          currentIndex = _tabController.index;
          _tabController.dispose();
        } catch (e) {
          // Ignore disposal error
        }

        _tabController = TabController(
          length: _mainTabs.length,
          vsync: this,
          initialIndex: currentIndex < _mainTabs.length ? currentIndex : 0,
        );
        // Trigger data load when tab changes
        if (!_tabListenerAdded) {
          _tabListenerAdded = true;
          _initializeTab(_tabController.index);
          _tabController.addListener(() {
            if (!_tabController.indexIsChanging) {
              _initializeTab(_tabController.index);
            }
          });
        }
      }
    } catch (e) {
      // Fallback
      _tabController = TabController(length: _mainTabs.length, vsync: this);
      if (!_tabListenerAdded) {
        _tabListenerAdded = true;
        _initializeTab(_tabController.index);
        _tabController.addListener(() {
          if (!_tabController.indexIsChanging) {
            _initializeTab(_tabController.index);
          }
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setupTabs();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectionSubscription.cancel();
    // Clean up scroll listeners
    for (final entry in _tabScrollListeners.entries) {
      final controller = _tabScrollControllers[entry.key];
      if (controller != null) {
        controller.removeListener(entry.value);
      }
    }
    _tabScrollListeners.clear();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = ref.watch(appConfigProvider).asData?.value;
    final l10n = AppLocalizations.of(context)!;

    if (appConfig == null) {
      return const Scaffold(body: Center(child: CupertinoActivityIndicator()));
    }

    // Get teal green color for tab indicator
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final tealGreen = _hexToColor(
      isDarkMode
          ? appConfig.themeOptions.dark.accentColorGreen
          : appConfig.themeOptions.light.accentColorGreen,
    );

    // Styles & backgrounds for segmented control (badge style matching currency badges)
    final themeConfig =
        isDarkMode ? appConfig.themeOptions.dark : appConfig.themeOptions.light;
    // Inactive fill: match card background
    final segmentInactiveBackground = _hexToColor(themeConfig.cardColor);
    // Active fill and text: match currency badge styling
    final segmentActiveBackground = isDarkMode
        ? tealGreen.withAlpha(38)
        : Theme.of(context).colorScheme.secondaryContainer.withAlpha(128);
    final segmentActiveTextColor = isDarkMode
        ? tealGreen.withAlpha(230)
        : Theme.of(context).colorScheme.onSecondaryContainer;
    // Get screen width for responsive text sizing
    final screenWidth = MediaQuery.of(context).size.width;
    // Reduce font size on smaller screens
    final tabFontSize = screenWidth < 360 ? 12.0 : 14.0;

    final selectedTextStyle = TextStyle(
      color: segmentActiveTextColor,
      fontSize: tabFontSize,
      fontWeight: FontWeight.w600,
    );
    final unselectedTextStyle = TextStyle(
      color: Theme.of(context).textTheme.bodyLarge?.color,
      fontSize: tabFontSize,
      fontWeight: FontWeight.w600,
    );

    // Build the main scaffold
    Widget mainScaffold = Scaffold(
      appBar: AppBar(
        // Create a custom title animation that ensures sequential transition
        title: Text(l10n.riyalesAppTitle),
        actions: [
          // 3. Add animations to the action icons based on locale
          AnimatedAlign(
            alignment: Localizations.localeOf(context).languageCode == 'fa'
                ? Alignment.centerLeft
                : Alignment.center,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutQuart,
            child: IconButton(
              // Smooth transition between search and clear icons
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  _isSearchActive
                      ? CupertinoIcons.clear
                      : CupertinoIcons.search,
                  key: ValueKey<bool>(_isSearchActive),
                  color: _showSearchBar
                      ? (isDarkMode ? Colors.grey[400] : Colors.grey[600])
                      : (isDarkMode ? Colors.white : Colors.black),
                  size: 28, // match profile icon size
                ),
              ),
              onPressed: () {
                // Already showing search bar, so hide it and clear search
                if (_isSearchActive) {
                  setState(() {
                    ref.read(searchQueryProvider.notifier).state = '';
                    _showSearchBar = false;
                    _isSearchActive = false;
                  });
                  return;
                }

                // Get current tab's scroll controller
                final currentTabIndex = _tabController.index;
                _tabScrollControllers[currentTabIndex] ??=
                    _findScrollController(currentTabIndex);
                final controller = _tabScrollControllers[currentTabIndex];

                if (controller != null && controller.hasClients) {
                  // Check if already at top
                  if (controller.offset <= 0) {
                    // Already at top, just show search bar
                    setState(() {
                      _showSearchBar = true;
                      _isSearchActive = true;
                    });
                    // Set up scroll listener if not already set
                    _setupScrollListener(currentTabIndex);
                  } else {
                    // First scroll to top, then show search bar
                    // Stop any ongoing scroll/fling
                    controller.jumpTo(controller.offset);
                    // Animate to top and then show search
                    controller
                        .animateTo(
                      0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutQuart,
                    )
                        .then((_) {
                      if (mounted) {
                        setState(() {
                          _showSearchBar = true;
                          _isSearchActive = true;
                        });
                        // Set up scroll listener if not already set
                        _setupScrollListener(currentTabIndex);
                      }
                    });
                  }
                } else {
                  // No valid scroll controller, just show search bar
                  setState(() {
                    _showSearchBar = true;
                    _isSearchActive = true;
                  });
                }
              },
              splashColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              focusColor: Colors.transparent,
              style: ButtonStyle(
                overlayColor: WidgetStateProperty.all(Colors.transparent),
              ),
            ),
          ),
          // Profile/Settings Icon
          AnimatedAlign(
            alignment: Localizations.localeOf(context).languageCode == 'fa'
                ? Alignment.centerLeft
                : Alignment.center,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutQuart,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () {
                  // Close search bar when opening settings
                  setState(() {
                    if (_isSearchActive) {
                      ref.read(searchQueryProvider.notifier).state = '';
                      _showSearchBar = false;
                      _isSearchActive = false;
                    }
                  });
                  showCupertinoModalPopup(
                    context: context,
                    builder: (_) => const SettingsSheet(),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: Icon(
                    CupertinoIcons.person_crop_circle,
                    size: 28,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(
            56.0 + 2.0,
          ), // Added 12.0 for bottom padding
          child: Padding(
            padding: const EdgeInsets.only(
              left: 8.0,
              right: 8.0,
              bottom: 2.0, // Added bottom padding, kept horizontal
            ), // Added bottom padding, kept horizontal
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final horizontalMargin =
                    isMobile ? 4.0 : 0.0; // Reduced margin for desktop/tablet
                // Use existing themeConfig for main tabs defined earlier
                final tabRadius =
                    themeConfig.cardBorderRadius * 0.7; //Tab corner radius
                return Row(
                  mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isSelected = _tabController.index == index;
                    final label = [
                      l10n.tabCurrency,
                      l10n.tabGold,
                      l10n.tabCrypto,
                      l10n.tabStock,
                    ][index];
                    void onTabTap() {
                      if (_tabController.index == index) {
                        // Scroll to top if active tab tapped
                        final controller = _tabScrollControllers[index] ??=
                            _findScrollController(index);
                        if (controller != null && controller.hasClients) {
                          controller.jumpTo(controller.offset);
                          controller.animateTo(
                            0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOutQuart,
                          );
                        }
                      } else {
                        setState(() {
                          _tabController.animateTo(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOutQuart,
                          );
                        });
                      }
                    }

                    final segment = SmoothCard(
                      smoothness: themeConfig.cardCornerSmoothness,
                      borderRadius: BorderRadius.circular(tabRadius),
                      elevation: 0,
                      color: isSelected
                          ? segmentActiveBackground
                          : segmentInactiveBackground,
                      child: Padding(
                        // bump vertical padding slightly for height
                        padding: const EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 16.0,
                        ), // Increased horizontal padding
                        child: Center(
                          child: Builder(
                            builder: (context) {
                              Widget textWidget = Text(
                                label,
                                style: isSelected
                                    ? selectedTextStyle
                                    : unselectedTextStyle,
                                textAlign: TextAlign.center,
                              );
                              // Ensure text fits within the tab
                              Widget fittedText = FittedBox(
                                fit: BoxFit.scaleDown,
                                child: textWidget,
                              );

                              // Shift light-theme active text down by 1px
                              if (isSelected && !isDarkMode) {
                                fittedText = Transform.translate(
                                  offset: const Offset(0, 1),
                                  child: fittedText,
                                );
                              }
                              return fittedText;
                            },
                          ),
                        ),
                      ),
                    );
                    final wrapped = GestureDetector(
                      onTap: onTabTap,
                      onLongPress: () {
                        // Haptic feedback
                        Vibration.vibrate(duration: 90);
                        final isFa =
                            Localizations.localeOf(context).languageCode ==
                                'fa';
                        final optionDefault = isFa ? 'پیشفرض' : 'Default';
                        final optionHigh =
                            isFa ? 'بیشترین قیمت' : 'Highest Price';
                        final optionLow = isFa ? 'کمترین قیمت' : 'Lowest Price';
                        showCupertinoModalPopup(
                          context: context,
                          builder: (_) => CupertinoTheme(
                            data: CupertinoThemeData(
                              brightness: isDarkMode
                                  ? Brightness.dark
                                  : Brightness.light,
                            ),
                            child: CupertinoActionSheet(
                              title: Text(
                                isFa ? 'مرتب‌سازی' : 'Sort By',
                                style: TextStyle(
                                  fontFamily: isFa ? 'Vazirmatn' : 'SF-Pro',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              actions: [
                                CupertinoActionSheetAction(
                                  onPressed: () {
                                    if (index == 0) {
                                      currencyTabKey.currentState
                                          ?._setSortMode(SortMode.defaultOrder);
                                    } else if (index == 1) {
                                      goldTabKey.currentState
                                          ?._setSortMode(SortMode.defaultOrder);
                                    } else if (index == 2) {
                                      cryptoTabKey.currentState
                                          ?._setSortMode(SortMode.defaultOrder);
                                    }
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(
                                    optionDefault,
                                    style: TextStyle(
                                      fontFamily: isFa ? 'Vazirmatn' : 'SF-Pro',
                                      fontSize: 17,
                                      fontWeight: FontWeight.normal,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                CupertinoActionSheetAction(
                                  onPressed: () {
                                    if (index == 0) {
                                      currencyTabKey.currentState
                                          ?._setSortMode(SortMode.highestPrice);
                                    } else if (index == 1) {
                                      goldTabKey.currentState
                                          ?._setSortMode(SortMode.highestPrice);
                                    } else if (index == 2) {
                                      cryptoTabKey.currentState
                                          ?._setSortMode(SortMode.highestPrice);
                                    }
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(
                                    optionHigh,
                                    style: TextStyle(
                                      fontFamily: isFa ? 'Vazirmatn' : 'SF-Pro',
                                      fontSize: 17,
                                      fontWeight: FontWeight.normal,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                CupertinoActionSheetAction(
                                  onPressed: () {
                                    if (index == 0) {
                                      currencyTabKey.currentState
                                          ?._setSortMode(SortMode.lowestPrice);
                                    } else if (index == 1) {
                                      goldTabKey.currentState
                                          ?._setSortMode(SortMode.lowestPrice);
                                    } else if (index == 2) {
                                      cryptoTabKey.currentState
                                          ?._setSortMode(SortMode.lowestPrice);
                                    }
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(
                                    optionLow,
                                    style: TextStyle(
                                      fontFamily: isFa ? 'Vazirmatn' : 'SF-Pro',
                                      fontSize: 17,
                                      fontWeight: FontWeight.normal,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                              cancelButton: CupertinoActionSheetAction(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(
                                  isFa ? 'انصراف' : 'Cancel',
                                  style: TextStyle(
                                    fontFamily: isFa ? 'Vazirmatn' : 'SF-Pro',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: tealGreen,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      child: segment,
                    );
                    return isMobile
                        ? Expanded(child: wrapped)
                        : Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalMargin,
                            ),
                            child: wrapped,
                          );
                  }),
                );
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_tabController.index != 3)
            AnimatedContainer(
              duration: _showSearchBar
                  ? const Duration(milliseconds: 400)
                  : const Duration(milliseconds: 300),
              curve: Curves.easeInOutQuart,
              height: _showSearchBar ? 48.0 : 0.0,
              margin: _showSearchBar
                  ? const EdgeInsets.only(
                      top: 10.0,
                      bottom: 4.0,
                    ) // Increased bottom margin by 2.0
                  : EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: AnimatedOpacity(
                opacity: _showSearchBar ? 1.0 : 0.0,
                duration: _showSearchBar
                    ? const Duration(milliseconds: 300)
                    : const Duration(milliseconds: 200),
                child:
                    _isSearchActive // Use _isSearchActive to determine if search widget should exist
                        ? Builder(
                            builder: (context) {
                              final searchText = ref.watch(searchQueryProvider);
                              final isRTL = Localizations.localeOf(context)
                                          .languageCode ==
                                      'fa' ||
                                  _containsPersian(searchText);
                              final textColor = isDarkMode
                                  ? Colors.grey[300]
                                  : Colors.grey[700];
                              final placeholderColor = isDarkMode
                                  ? Colors.grey[600]
                                  : Colors.grey[500];
                              final iconColor = isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600];
                              final fontFamily = isRTL ? 'Vazirmatn' : 'SF-Pro';

                              return CupertinoTextField(
                                controller: TextEditingController(
                                  text: searchText,
                                )..selection = TextSelection.fromPosition(
                                    TextPosition(offset: searchText.length),
                                  ),
                                onChanged: (v) => ref
                                    .read(searchQueryProvider.notifier)
                                    .state = v,
                                placeholder: l10n.searchPlaceholder,
                                placeholderStyle: TextStyle(
                                  color: placeholderColor,
                                  fontFamily: fontFamily,
                                ),
                                // Use directional padding for search icon and clear button
                                prefix: Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    start: 18,
                                  ),
                                  child: Icon(
                                    CupertinoIcons.search,
                                    size: 20,
                                    color: iconColor,
                                  ),
                                ),
                                suffix: searchText.isNotEmpty
                                    ? CupertinoButton(
                                        padding:
                                            const EdgeInsetsDirectional.only(
                                          end: 18,
                                        ),
                                        minSize: 30,
                                        child: Icon(
                                          CupertinoIcons.clear,
                                          size: 18,
                                          color: iconColor,
                                        ),
                                        onPressed: () {
                                          ref
                                              .read(
                                                searchQueryProvider.notifier,
                                              )
                                              .state = '';
                                        },
                                      )
                                    : null,
                                textAlign:
                                    isRTL ? TextAlign.right : TextAlign.left,
                                padding: EdgeInsetsDirectional.only(
                                  start: 9,
                                  end: searchText.isNotEmpty ? 28 : 12,
                                  top: 8,
                                  bottom: 8,
                                ),
                                style: TextStyle(
                                  color: textColor,
                                  fontFamily: fontFamily,
                                ),
                                cursorColor: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? const Color(0xFF2C2C2E)
                                      : const Color(0xFFE2E2E6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              );
                            },
                          )
                        : const SizedBox(),
              ),
            ),
          Expanded(
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, child) {
                final index = _tabController.index;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeInOutQuart,
                  switchOutCurve: Curves.easeInOutQuart,
                  transitionBuilder: (Widget child, Animation<double> anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: Container(
                    key: ValueKey<int>(index),
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: index == 3
                        ? StockPage(
                            key: stockTabKey,
                            showSearchBar: _showSearchBar,
                            isSearchActive: _isSearchActive,
                          )
                        : _mainTabViews[index],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    // Wrap with network awareness
    return NetworkAwareWidget(
      onlineWidget: mainScaffold,
      offlineBuilder: (status) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.riyalesAppTitle),
            actions: [
              // Only show settings in offline mode
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    // Close search bar when opening settings
                    setState(() {
                      if (_isSearchActive) {
                        ref.read(searchQueryProvider.notifier).state = '';
                        _showSearchBar = false;
                        _isSearchActive = false;
                      }
                    });
                    showCupertinoModalPopup(
                      context: context,
                      builder: (_) => const SettingsSheet(),
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Icon(
                      CupertinoIcons.person_crop_circle,
                      size: 28,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Center(child: ErrorPlaceholder(status: status)),
        );
      },
    );
  }

  // Add helper method to find scroll controllers in tab content
  ScrollController? _findScrollController(int tabIndex) {
    try {
      switch (tabIndex) {
        case 0: // Currency tab
          return currencyTabKey.currentState?._scrollController;
        case 1: // Gold tab
          return goldTabKey.currentState?._scrollController;
        case 2: // Crypto tab
          return cryptoTabKey.currentState?._scrollController;
        case 3: // Stock tab (main)
          // We have to get access to the currently active StockPage tab's controller
          // First find the StockPage state
          final stockPage = _mainTabViews[3] as StockPage;
          final stockState = stockPage.key as GlobalKey<_StockPageState>;
          final state = stockState.currentState;
          if (state != null) {
            // Get currently active sub-tab index in Stock page
            final activeStockTabIndex = state._stockTabController.index;
            // Update stock scroll controllers to ensure we have latest references
            state._updateStockScrollControllers();
            // Return the scroll controller for active Stock sub-tab
            return state._stockScrollControllers[activeStockTabIndex];
          }
          return null;
        default:
          return null;
      }
    } catch (e) {
      print('Error finding scroll controller for tab $tabIndex: $e');
      return null;
    }
  }
}

// endregion

// region 8. Localization (AppLocalizations & Delegate)
// This will be generated by `flutter gen-l10n` if you use ARB files.
// For a single file, we define it manually.

// endregion

// region 2.5 Connection Service and Error UI
class ConnectionService {
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

  bool _isOnline = false;
  bool get isOnline => _isOnline;

  final _statusController = StreamController<ConnectionStatus>.broadcast();
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  Future<void> initialize(String apiUrl) async {
    await _checkAndUpdateStatus(apiUrl);

    // Setup periodic check regardless of current status
    _startPeriodicPing(apiUrl);
  }

  Future<void> _checkAndUpdateStatus(String apiUrl) async {
    // Initial ping test
    final apiAvailable = await ping(apiUrl);
    if (apiAvailable) {
      final wasOffline = !_isOnline;
      _isOnline = true;

      // Only notify if state changed
      if (wasOffline) {
        _statusController.add(ConnectionStatus.connected);
      }
    } else {
      // Try pinging Google as fallback
      final internetAvailable = await ping('https://www.google.com');
      if (internetAvailable) {
        _isOnline = false;
        _statusController.add(ConnectionStatus.serverDown);
      } else {
        _isOnline = false;
        _statusController.add(ConnectionStatus.internetDown);
      }
    }
  }

  Timer? _pingTimer;
  void _startPeriodicPing(String apiUrl) {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _checkAndUpdateStatus(apiUrl);
    });
  }

  Future<bool> checkConnection(String apiUrl) async {
    // Use our shared check and update logic
    await _checkAndUpdateStatus(apiUrl);
    return _isOnline;
  }

  Future<bool> ping(String url) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        url,
        options: Options(
          validateStatus: (_) => true,
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode != null && response.statusCode! < 400;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _pingTimer?.cancel();
    _statusController.close();
  }
}

enum ConnectionStatus { connected, serverDown, internetDown }

// Error UI components
class ErrorPlaceholder extends ConsumerWidget {
  final ConnectionStatus status;

  const ErrorPlaceholder({required this.status, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentLocale = ref.watch(localeNotifierProvider);
    final isRTL = currentLocale.languageCode == 'fa';

    String title = '';
    String message = '';
    IconData icon = CupertinoIcons.wifi_slash;
    // Reduced vibrance for the icon, use gray instead of red
    Color iconColor = isDarkMode ? Colors.grey[500]! : Colors.grey[400]!;

    switch (status) {
      case ConnectionStatus.internetDown:
        title = l10n.errorNoInternet;
        message = l10n.errorCheckConnection;
        icon = CupertinoIcons.wifi_slash;
        break;
      case ConnectionStatus.serverDown:
        title = l10n.errorServerUnavailable;
        message = l10n.errorServerMessage;
        icon = CupertinoIcons.exclamationmark_circle;
        break;
      case ConnectionStatus.connected:
        // This shouldn't be shown, but as a fallback
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 50, // reduced size
            color: iconColor,
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18, // smaller
              fontWeight: FontWeight.w500, // lighter
              fontFamily: isRTL ? 'Vazirmatn' : 'SF-Pro',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              fontFamily: isRTL ? 'Vazirmatn' : 'SF-Pro',
            ),
          ),
          const SizedBox(height: 36),
          // iOS-style loading indicator
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CupertinoActivityIndicator(radius: 10),
              const SizedBox(width: 12),
              Text(
                l10n.retrying,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontFamily: isRTL ? 'Vazirmatn' : 'SF-Pro',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ConnectionSnackbar {
  static void show(
    BuildContext context, {
    required bool isConnected,
    required bool isRTL,
  }) {
    // Get safe area
    final safeArea = MediaQuery.of(context).padding;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Remove any existing snackbars
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Show the new snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        duration: const Duration(milliseconds: 2500), // 2.5 seconds
        behavior: SnackBarBehavior.floating,
        backgroundColor: isConnected
            ? Theme.of(context).colorScheme.secondary
            : Theme.of(context).colorScheme.error,
        margin: const EdgeInsets.only(
          bottom: 10, // Reduced margins
          left: 10,
          right: 10,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          textDirection: isRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          children: [
            Icon(
              isConnected ? CupertinoIcons.wifi : CupertinoIcons.wifi_slash,
              color: Colors.white,
              size: 20, // increased size
            ),
            const SizedBox(width: 12),
            Text(
              isConnected
                  ? AppLocalizations.of(context)!.youreBackOnline
                  : AppLocalizations.of(context)!.youreOffline,
              style: TextStyle(
                fontFamily: isRTL ? 'Vazirmatn' : 'SF-Pro',
                color: Colors.white,
              ),
            ),
          ],
        ),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }
}

// Offline indicator overlay
class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        CupertinoIcons.wifi_slash,
        size: 80,
        color: Colors.grey.withOpacity(0.2),
      ),
    );
  }
}

// Network-aware widget wrapper
class NetworkAwareWidget extends ConsumerStatefulWidget {
  final Widget onlineWidget;
  final Widget Function(ConnectionStatus)? offlineBuilder;
  final bool checkOnInit;

  const NetworkAwareWidget({
    super.key,
    required this.onlineWidget,
    this.offlineBuilder,
    this.checkOnInit = false,
  });

  @override
  ConsumerState<NetworkAwareWidget> createState() => _NetworkAwareWidgetState();
}

class _NetworkAwareWidgetState extends ConsumerState<NetworkAwareWidget> {
  late StreamSubscription<ConnectionStatus> _subscription;
  ConnectionStatus _currentStatus = ConnectionStatus.connected;
  bool _showOfflineOverlay = false;
  ConnectionService connectionService = ConnectionService();

  @override
  void initState() {
    super.initState();

    // Force check connection status on widget init
    _checkConnectionOnInit();

    // Listen for connection status changes
    _subscription = connectionService.statusStream.listen((status) {
      if (_currentStatus != status) {
        setState(() {
          _currentStatus = status;
          _showOfflineOverlay = status != ConnectionStatus.connected;
        });

        // Only show snackbar for status changes, not initial status
        if (mounted && context.mounted) {
          final locale = ref.read(localeNotifierProvider);
          final isRTL = locale.languageCode == 'fa';

          ConnectionSnackbar.show(
            context,
            isConnected: status == ConnectionStatus.connected,
            isRTL: isRTL,
          );
        }
      }
    });
  }

  void _checkConnectionOnInit() async {
    if (widget.checkOnInit) {
      final appConfig = ref.read(appConfigProvider).asData?.value;
      if (appConfig != null) {
        final apiUrl = appConfig.apiEndpoints.currencyUrl;
        await connectionService.checkConnection(apiUrl);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check connection again when widget becomes visible (e.g., tab change)
    _checkConnectionOnInit();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStatus == ConnectionStatus.connected) {
      return widget.onlineWidget;
    }

    if (widget.offlineBuilder != null) {
      return widget.offlineBuilder!(_currentStatus);
    }

    // Default offline UI with overlay
    return Stack(
      children: [
        widget.onlineWidget,
        if (_showOfflineOverlay) const OfflineIndicator(),
      ],
    );
  }
}
// endregion

// Connection helper extension for Riverpod
extension ConnectionServiceExtension on WidgetRef {
  // Helper to check connection before loading data
  Future<bool> checkConnectionBeforeLoading(String apiUrl) async {
    final connectionService = ConnectionService();
    final isConnected = await connectionService.checkConnection(apiUrl);
    return isConnected;
  }
}

// Provider to map crypto symbols to bundled asset icon paths
final localCryptoIconProvider = FutureProvider<Map<String, String>>((
  ref,
) async {
  final manifestStr = await rootBundle.loadString('AssetManifest.json');
  final manifestMap = json.decode(manifestStr) as Map<String, dynamic>;
  final regex = RegExp(r"\(([^)]+)\)");
  final map = <String, String>{};
  for (final path in manifestMap.keys) {
    if (path.startsWith('assets/icons/crypto/')) {
      final file = path.split('/').last;
      final match = regex.firstMatch(file);
      if (match != null) {
        map[match.group(1)!.toLowerCase()] = path;
      }
    }
  }
  return map;
});

// --- Terms & Conditions Provider ---
class TermsData extends Equatable {
  final String title;
  final String content;
  final String lastUpdated;

  const TermsData({
    required this.title,
    required this.content,
    required this.lastUpdated,
  });

  factory TermsData.fromJson(Map<String, dynamic> json) {
    return TermsData(
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      lastUpdated: json['last_updated'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [title, content, lastUpdated];
}

final termsProvider = FutureProvider.autoDispose.family<TermsData, String>((
  ref,
  languageCode,
) async {
  final dio = ref.watch(dioProvider);
  final appConfig = await ref.watch(appConfigProvider.future);
  final isPersian = languageCode == 'fa';

  final remoteUrl = isPersian
      ? appConfig.apiEndpoints.termsFaUrl
      : appConfig.apiEndpoints.termsEnUrl;
  final localAssetPath =
      isPersian ? 'assets/config/terms_fa.json' : 'assets/config/terms_en.json';

  try {
    if (remoteUrl.isNotEmpty) {
      final response = await dio.get(remoteUrl);
      if (response.statusCode == 200 && response.data is Map) {
          return models.TermsData.fromJson(
              response.data as Map<String, dynamic>);
      }
    }
    // Fallback to local if remote fails or URL is empty
    final localConfigString = await rootBundle.loadString(localAssetPath);
    final localConfigJson = jsonDecode(localConfigString)
        as Map<String, dynamic>; // Fixed typo here
      return models.TermsData.fromJson(localConfigJson);
  } catch (e) {
    // Fallback to local if any error occurs
    try {
      final localConfigString = await rootBundle.loadString(localAssetPath);
      final localConfigJson =
          jsonDecode(localConfigString) as Map<String, dynamic>;
        return models.TermsData.fromJson(localConfigJson);
    } catch (localError) {
      // If local also fails, provide a default error message
        return models.TermsData(
        title: isPersian ? 'خطا' : 'Error',
        content: isPersian
            ? 'قادر به بارگیری قوانین و مقررات نیستیم.'
            : 'Could not load terms and conditions.',
        lastUpdated: '',
      );
    }
  }
});

// Screen to display Terms and Conditions
class TermsAndConditionsScreen extends ConsumerWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeNotifierProvider);
    final termsAsyncValue = ref.watch(termsProvider(locale.languageCode));
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isFa = locale.languageCode == 'fa';
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;
    final fadedTextColor = isDarkMode ? Colors.grey[500] : Colors.grey[500];
    final chevronColor = isDarkMode ? Colors.grey[600] : Colors.grey[400];

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: termsAsyncValue.when(
          data: (terms) => Stack(
            children: [
              // Main content (header + scrollable terms)
              Column(
                children: [
                  // Header
                  SizedBox(
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Back icon
                        Align(
                          alignment: isFa
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.of(context).pop(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Icon(
                                isFa
                                    ? CupertinoIcons.chevron_right
                                    : CupertinoIcons.chevron_left,
                                size: 20,
                                color: fadedTextColor,
                              ),
                            ),
                          ),
                        ),
                        // Centered title
                        Center(
                          child: Text(
                            terms.title,
                            style: TextStyle(
                              fontFamily: isFa ? 'Vazirmatn' : 'SF-Pro',
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Spacing between title and content
                  const SizedBox(height: 22),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            terms.content,
                            style: TextStyle(
                              fontFamily: isFa ? 'Vazirmatn' : 'SF-Pro',
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              height: 1.8,
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.92)
                                  : Colors.black87,
                            ),
                            textAlign: isFa ? TextAlign.right : TextAlign.left,
                            textDirection: isFa
                                ? ui.TextDirection.rtl
                                : ui.TextDirection.ltr,
                          ),
                          if (terms.lastUpdated.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 16,
                                bottom: 16,
                              ),
                              child: Center(
                                child: Text(
                                  isFa
                                      ? 'بروزرسانی شده در: ${terms.lastUpdated}'
                                      : 'Last updated: ${terms.lastUpdated}',
                                  style: TextStyle(
                                    fontFamily: isFa ? 'Vazirmatn' : 'SF-Pro',
                                    fontSize: 12,
                                    color: fadedTextColor,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, stack) => Center(
            child: Text(
              isFa ? 'خطا در بارگیری قوانین.' : 'Error loading terms.',
              style: TextStyle(
                fontFamily: isFa ? 'Vazirmatn' : 'SF-Pro',
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
