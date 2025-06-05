import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../models/asset_models.dart';
import '../../../config/app_config.dart';
import '../../../services/api_service.dart';
import '../../../services/connection_service.dart';

class StockHousingFacilitiesDataNotifier extends ChangeNotifier {
  final ApiService apiService;
  final AppConfig appConfig;
  final ConnectionService connectionService;

  bool isLoading = false;
  String? error;
  List<StockAsset> stockAssets = []; // Public list for current items

  int _currentlyLoadedCount = 0;
  List<StockAsset> _fullDataList = [];
  Timer? _updateTimer;

  // Public getter for the full data list
  List<StockAsset> get fullDataList => _fullDataList;
  // Public getter for the paginated/currently visible items
  List<StockAsset> get items => stockAssets;

  StockHousingFacilitiesDataNotifier({required this.apiService, required this.appConfig, required this.connectionService}) {
    _currentlyLoadedCount = appConfig.initialItemsToLoad;
    fetchInitialData();
  }

  Future<void> fetchInitialData({bool isRefresh = false}) async {
    if (!isRefresh) {
      isLoading = true;
      error = null;
      notifyListeners();
    }

    final String apiUrl = appConfig.apiEndpoints.stockHousingFacilitiesUrl;
    final bool isOnline = await connectionService.checkConnection(apiUrl);
    if (!isOnline) {
      error = "Offline";
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final dynamic responseData = await apiService.fetchData(apiUrl);
      List<StockAsset> fetchedAssets = [];
      if (responseData is List) {
        fetchedAssets = responseData
            .map((item) => StockAsset.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      List<String> priorityList = [];
      try {
        final dynamic priorityResponse = await apiService.fetchData(appConfig.apiEndpoints.priorityAssetsUrl);
        if (priorityResponse is Map<String, dynamic>) {
          priorityList = List<String>.from(priorityResponse['stock_housing_facilities'] as List<dynamic>? ?? []);
        }
      } catch (_) {
        // Failed to load priority list
      }

      final List<StockAsset> priorityAssets = [];
      final List<StockAsset> otherAssets = [];
      if (priorityList.isNotEmpty) {
          for (final symbol in priorityList) {
            priorityAssets.addAll(fetchedAssets.where((a) => a.symbol == symbol));
          }
          for (final asset in fetchedAssets) {
            if (!priorityAssets.any((pa) => pa.id == asset.id)) {
              otherAssets.add(asset);
            }
          }
          _fullDataList = [...priorityAssets, ...otherAssets];
      } else {
          _fullDataList = fetchedAssets;
      }

      stockAssets = _fullDataList.take(_currentlyLoadedCount).toList();
      error = null;
    } catch (e) {
      error = e.toString();
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
      _currentlyLoadedCount = (_currentlyLoadedCount + appConfig.itemsPerLazyLoad > _fullDataList.length)
          ? _fullDataList.length
          : _currentlyLoadedCount + appConfig.itemsPerLazyLoad;
      stockAssets = _fullDataList.take(_currentlyLoadedCount).toList();
      notifyListeners();
    }
  }

  void _startAutoRefresh() {
    _updateTimer?.cancel();
    final updateIntervalMs = appConfig.priceUpdateIntervalMinutes * 60 * 1000;
    if (updateIntervalMs > 0) {
        _updateTimer = Timer.periodic(Duration(milliseconds: updateIntervalMs), (timer) {
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
