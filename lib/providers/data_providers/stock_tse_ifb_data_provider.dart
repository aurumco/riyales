import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../models/asset_models.dart';
import '../../../config/app_config.dart';
import '../../../services/api_service.dart';
import '../../../services/connection_service.dart';

class StockTseIfbDataNotifier extends ChangeNotifier {
  final ApiService apiService;
  final AppConfig appConfig;
  final ConnectionService connectionService;

  bool isLoading = false;
  String? error;
  List<StockAsset> stockAssets = []; // Public list for current items

  // int _currentlyLoadedCount = 0; // Replaced by items.length for loadMore
  List<StockAsset> _fullDataList = [];
  // Timer? _updateTimer; // Removed

  bool hasDataBeenFetchedOnce = false;
  DateTime? lastFetchTime;
  bool _isLoadingMore = false;

  // Public getter for the full data list
  List<StockAsset> get fullDataList => _fullDataList;
  // Public getter for the paginated/currently visible items
  List<StockAsset> get items => stockAssets;

  StockTseIfbDataNotifier(
      {required this.apiService,
      required this.appConfig,
      required this.connectionService}) {
    // Initial fetch removed to defer loading until sub-tab is activated
  }

  Future<void> fetchInitialData(
      {bool isRefresh = false, bool isLoadMore = false}) async {
    const bool isSpecialFetch = false;

    if (isLoadMore) {
      if (_isLoadingMore ||
          (_fullDataList.isNotEmpty &&
              stockAssets.length >= _fullDataList.length)) {
        return;
      }
      _isLoadingMore = true;
      // notifyListeners(); // Optional

      final currentLength = stockAssets.length;
      final int end =
          (currentLength + appConfig.itemsPerLazyLoad > _fullDataList.length)
              ? _fullDataList.length
              : currentLength + appConfig.itemsPerLazyLoad;
      if (currentLength < end) {
        stockAssets.addAll(_fullDataList.sublist(currentLength, end));
      }

      _isLoadingMore = false;
      notifyListeners();
      return;
    }

    if (!isRefresh && !isSpecialFetch && hasDataBeenFetchedOnce) {
      if (isLoading) {
        isLoading = false;
        notifyListeners();
      }
      return;
    }

    isLoading = true;
    if (isRefresh || isSpecialFetch) {
      // isSpecialFetch will always be false here
      error = null;
    }
    notifyListeners();

    try {
      final String apiUrl = appConfig.apiEndpoints.stockTseIfbSymbolsUrl;
      final bool isOnline = await connectionService.checkConnection(apiUrl);
      if (!isOnline) {
        error = "Offline";
        if (!isRefresh && !hasDataBeenFetchedOnce) {
          hasDataBeenFetchedOnce = false;
        }
      } else {
        final dynamic responseData = await apiService.fetchData(apiUrl);
        List<StockAsset> fetchedAssets = [];
        if (responseData is List) {
          fetchedAssets = responseData
              .map((item) => StockAsset.fromJson(item as Map<String, dynamic>))
              .toList();
        }

        List<String> priorityList = [];
        try {
          final dynamic priorityResponse = await apiService
              .fetchData(appConfig.apiEndpoints.priorityAssetsUrl);
          if (priorityResponse is Map<String, dynamic>) {
            priorityList = List<String>.from(
                priorityResponse['stock_tse_ifb_symbols'] as List<dynamic>? ??
                    []);
          }
        } catch (_) {
          // Failed to load priority list
        }

        final List<StockAsset> priorityAssetsList = []; // Renamed
        final List<StockAsset> otherAssets = [];
        if (priorityList.isNotEmpty) {
          for (final symbol in priorityList) {
            priorityAssetsList
                .addAll(fetchedAssets.where((a) => a.symbol == symbol));
          }
          for (final assetInFetched in fetchedAssets) {
            // Renamed
            if (!priorityAssetsList.any((pa) => pa.id == assetInFetched.id)) {
              otherAssets.add(assetInFetched);
            }
          }
          _fullDataList = [...priorityAssetsList, ...otherAssets];
        } else {
          _fullDataList = fetchedAssets;
        }

        stockAssets = _fullDataList.take(appConfig.initialItemsToLoad).toList();
        error = null;
      }

      if (error == null && !isSpecialFetch) {
        hasDataBeenFetchedOnce = true;
        lastFetchTime = DateTime.now();
        // if (!isRefresh) { // Removed call to _startAutoRefresh
        //   _startAutoRefresh();
        // }
      }
    } catch (e) {
      error = e.toString();
      if (!isRefresh && !isSpecialFetch) {
        hasDataBeenFetchedOnce = false;
      }
    } finally {
      isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // void loadMore() { // Integrated
  // }

  Future<void> fetchDataIfStaleOrNeverFetched(
      {Duration staleness = const Duration(minutes: 5)}) async {
    if (!hasDataBeenFetchedOnce ||
        lastFetchTime == null ||
        DateTime.now().difference(lastFetchTime!) > staleness) {
      await fetchInitialData(isRefresh: true);
    }
  }

  // void _startAutoRefresh() { // Removed method
  //   _updateTimer?.cancel();
  //   final updateIntervalMs = appConfig.priceUpdateIntervalMinutes * 60 * 1000;
  //   if (updateIntervalMs > 0) {
  //       _updateTimer = Timer.periodic(Duration(milliseconds: updateIntervalMs), (timer) {
  //           fetchInitialData(isRefresh: true);
  //       });
  //   }
  // }

  @override
  void dispose() {
    // _updateTimer?.cancel(); // Removed timer cancellation
    super.dispose();
  }
}
