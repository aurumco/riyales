import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../models/asset_models.dart';
import '../../../config/app_config.dart';
import '../../../services/api_service.dart';
import '../../../services/connection_service.dart';

/// Provides stock futures data with pagination and caching.
class StockFuturesDataNotifier extends ChangeNotifier {
  final ApiService apiService;
  final AppConfig appConfig;
  final ConnectionService connectionService;

  bool isLoading = false;
  String? error;
  List<StockAsset> stockAssets = [];

  List<StockAsset> _fullDataList = [];

  bool hasDataBeenFetchedOnce = false;
  DateTime? lastFetchTime;
  bool _isLoadingMore = false;

  List<StockAsset> get fullDataList => _fullDataList;
  List<StockAsset> get items => stockAssets;

  /// Creates a notifier for stock futures data and triggers initial load.
  StockFuturesDataNotifier(
      {required this.apiService,
      required this.appConfig,
      required this.connectionService}) {
    fetchInitialData();
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
      // notify listeners when loading more is complete

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
      error = null;
    }
    notifyListeners();

    try {
      final String apiUrl = appConfig.apiEndpoints.stockFuturesUrl;
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
                priorityResponse['stock_futures'] as List<dynamic>? ?? []);
          }
        } catch (_) {}

        final List<StockAsset> priorityAssetsList = [];
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

  Future<void> fetchDataIfStaleOrNeverFetched(
      {Duration staleness = const Duration(minutes: 5)}) async {
    if (!hasDataBeenFetchedOnce ||
        lastFetchTime == null ||
        DateTime.now().difference(lastFetchTime!) > staleness) {
      await fetchInitialData(isRefresh: true);
    }
  }
}
