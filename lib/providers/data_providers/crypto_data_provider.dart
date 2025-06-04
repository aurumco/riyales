import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../models/asset_models.dart';
import '../../../config/app_config.dart';
import '../../../services/api_service.dart';
import '../../../services/connection_service.dart';
import '../../../ui/widgets/asset_card.dart'; // For cryptoIconMap

class CryptoDataNotifier extends ChangeNotifier {
  final ApiService apiService;
  final AppConfig appConfig;
  final ConnectionService connectionService;

  bool isLoading = false;
  String? error;
  List<CryptoAsset> cryptoAssets = []; // Public list for current items

  int _currentlyLoadedCount = 0;
  List<CryptoAsset> _fullDataList = [];
  Timer? _updateTimer;

  // Public getter for the full data list
  List<CryptoAsset> get fullDataList => _fullDataList;
  // Public getter for the paginated/currently visible items
  List<CryptoAsset> get items => cryptoAssets;

  CryptoDataNotifier(
      {required this.apiService,
      required this.appConfig,
      required this.connectionService}) {
    _currentlyLoadedCount = appConfig.initialItemsToLoad;
    fetchInitialData();
  }

  Future<void> fetchInitialData({bool isRefresh = false}) async {
    if (!isRefresh) {
      isLoading = true;
      error = null;
      notifyListeners();
    }

    final bool isOnline = await connectionService
        .checkConnection(appConfig.apiEndpoints.cryptoUrl);
    if (!isOnline) {
      error = "Offline"; // Or a localized message
      isLoading = false;
      notifyListeners();
      // TODO: Implement loading cached data
      return;
    }

    try {
      final dynamic responseData =
          await apiService.fetchData(appConfig.apiEndpoints.cryptoUrl);
      List<CryptoAsset> fetchedAssets = [];
      if (responseData is List) {
        fetchedAssets = responseData
            .map((item) => CryptoAsset.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      List<String> priorityList = [];
      try {
        final dynamic priorityResponse = await apiService
            .fetchData(appConfig.apiEndpoints.priorityAssetsUrl);
        if (priorityResponse is Map<String, dynamic>) {
          priorityList = List<String>.from(
              priorityResponse['crypto'] as List<dynamic>? ?? []);
        }
      } catch (_) {
        // Failed to load priority list
      }

      // Icon-first sorting: bring assets with defined local icons to the top
      final List<CryptoAsset> iconAssets = [];
      for (final key in cryptoIconMap.keys) {
        iconAssets.addAll(fetchedAssets
            .where((a) => a.name.toLowerCase() == key.toLowerCase()));
      }
      final Set<String> usedAssetIds = iconAssets.map((a) => a.id).toSet();

      final List<CryptoAsset> sortedList = [];
      sortedList.addAll(iconAssets);

      // Then add priority assets (excluding those already added)
      if (priorityList.isNotEmpty) {
        for (final name in priorityList) {
          final lowerName = name.toLowerCase();
          final assets = fetchedAssets.where((a) =>
              a.name.toLowerCase() == lowerName &&
              !usedAssetIds.contains(a.id));
          for (final asset in assets) {
            sortedList.add(asset);
            usedAssetIds.add(asset.id);
          }
        }
      }

      // Finally add the remaining assets
      final remaining =
          fetchedAssets.where((a) => !usedAssetIds.contains(a.id)).toList();
      sortedList.addAll(remaining);

      _fullDataList = sortedList;

      cryptoAssets = _fullDataList.take(_currentlyLoadedCount).toList();
      error = null;
    } catch (e) {
      error = e.toString();
      // TODO: Load cached data
    } finally {
      isLoading = false;
      notifyListeners();
      if (!isRefresh) {
        _startAutoRefresh();
      }
    }
  }

  void loadMore() {
    if (_currentlyLoadedCount < _fullDataList.length) {
      _currentlyLoadedCount =
          (_currentlyLoadedCount + appConfig.itemsPerLazyLoad >
                  _fullDataList.length)
              ? _fullDataList.length
              : _currentlyLoadedCount + appConfig.itemsPerLazyLoad;
      cryptoAssets = _fullDataList.take(_currentlyLoadedCount).toList();
      notifyListeners();
    }
  }

  void _startAutoRefresh() {
    _updateTimer?.cancel();
    final updateIntervalMs = appConfig.priceUpdateIntervalMinutes * 60 * 1000;
    if (updateIntervalMs > 0) {
      _updateTimer =
          Timer.periodic(Duration(milliseconds: updateIntervalMs), (timer) {
        fetchInitialData(isRefresh: true);
      });
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
}
