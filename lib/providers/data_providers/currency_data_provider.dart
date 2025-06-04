import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../models/asset_models.dart';
import '../../../config/app_config.dart';
import '../../../services/api_service.dart';
import '../../../services/connection_service.dart'; // Required for online check

class CurrencyDataNotifier extends ChangeNotifier {
  final ApiService apiService;
  final AppConfig appConfig;
  final ConnectionService connectionService;

  bool isLoading = false;
  String? error;
  List<CurrencyAsset> currencyAssets = []; // Public list for current items

  int _currentlyLoadedCount = 0;
  List<CurrencyAsset> _fullDataList = [];
  Timer? _updateTimer;

  // Public getter for the full data list (primarily for search)
  List<CurrencyAsset> get fullDataList => _fullDataList;
  // Public getter for the paginated/currently visible items
  List<CurrencyAsset> get items => currencyAssets;

  CurrencyDataNotifier(
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
        .checkConnection(appConfig.apiEndpoints.currencyUrl);
    if (!isOnline) {
      error = "Offline"; // Or a localized message
      isLoading = false;
      notifyListeners();
      // TODO: Implement loading cached data if necessary
      return;
    }

    try {
      final dynamic responseData =
          await apiService.fetchData(appConfig.apiEndpoints.currencyUrl);
      List<CurrencyAsset> fetchedAssets = [];
      if (responseData is Map && responseData.containsKey('currency')) {
        fetchedAssets = (responseData['currency'] as List)
            .map((item) => CurrencyAsset.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      List<String> priorityList = [];
      try {
        final dynamic priorityResponse = await apiService
            .fetchData(appConfig.apiEndpoints.priorityAssetsUrl);
        if (priorityResponse is Map<String, dynamic>) {
          priorityList = List<String>.from(
              priorityResponse['currency'] as List<dynamic>? ?? []);
        }
      } catch (_) {
        // Failed to load or parse priority list, proceed without it
      }

      final List<CurrencyAsset> priorityAssets = [];
      final List<CurrencyAsset> otherAssets = [];
      if (priorityList.isNotEmpty) {
        for (final symbol in priorityList) {
          // Find all assets that match the symbol and add them.
          // This handles cases where symbols might not be unique, though typically they are.
          priorityAssets.addAll(fetchedAssets.where((a) => a.symbol == symbol));
        }
        // Add remaining assets that were not in the priority list.
        for (final asset in fetchedAssets) {
          if (!priorityAssets.any((pa) => pa.id == asset.id)) {
            // Check by ID for uniqueness
            otherAssets.add(asset);
          }
        }
        _fullDataList = [...priorityAssets, ...otherAssets];
      } else {
        _fullDataList = fetchedAssets;
      }

      currencyAssets = _fullDataList.take(_currentlyLoadedCount).toList();
      error = null;
    } catch (e) {
      error = e.toString();
      // TODO: Load cached data on error if necessary
    } finally {
      isLoading = false;
      notifyListeners();
      if (!isRefresh) {
        // Only start auto-refresh on initial load or if it was stopped
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
      currencyAssets = _fullDataList.take(_currentlyLoadedCount).toList();
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
