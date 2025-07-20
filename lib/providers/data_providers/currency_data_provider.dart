import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../models/asset_models.dart';
import '../../../config/app_config.dart';
import '../../../services/api_service.dart';
import '../../../services/connection_service.dart';

/// Provides currency data with pagination and basic caching.
class CurrencyDataNotifier extends ChangeNotifier {
  final ApiService apiService;
  final AppConfig appConfig;
  final ConnectionService connectionService;

  bool isLoading = false;
  String? error;
  List<CurrencyAsset> currencyAssets = [];
  List<CurrencyAsset> _fullDataList = [];

  bool hasDataBeenFetchedOnce = false;
  DateTime? lastFetchTime;
  bool _isLoadingMore = false;

  bool _disposed = false;

  List<CurrencyAsset> get fullDataList => _fullDataList;
  List<CurrencyAsset> get items => currencyAssets;

  CurrencyDataNotifier(
      {required this.apiService,
      required this.appConfig,
      required this.connectionService});

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  Future<void> fetchInitialData(
      {bool isRefresh = false, bool isLoadMore = false}) async {
    const bool isSpecialFetch = false;

    if (isLoadMore) {
      if (_isLoadingMore ||
          (_fullDataList.isNotEmpty &&
              currencyAssets.length >= _fullDataList.length)) {
        return;
      }
      _isLoadingMore = true;

      final currentLength = currencyAssets.length;
      final int end =
          (currentLength + appConfig.itemsPerLazyLoad > _fullDataList.length)
              ? _fullDataList.length
              : currentLength + appConfig.itemsPerLazyLoad;
      if (currentLength < end) {
        currencyAssets.addAll(_fullDataList.sublist(currentLength, end));
      }

      _isLoadingMore = false;
      if (!_disposed) notifyListeners();
      return;
    }

    if (!isRefresh && !isSpecialFetch && hasDataBeenFetchedOnce) {
      if (isLoading) {
        isLoading = false;
        if (!_disposed) notifyListeners();
      }
      return;
    }

    isLoading = true;
    if (isRefresh) {
      error = null;
    }
    if (!_disposed) notifyListeners();

    try {
      final bool isOnline = await connectionService
          .checkConnection(appConfig.apiEndpoints.currencyUrl);
      if (!isOnline) {
        error = "Offline";
        if (!isRefresh && !hasDataBeenFetchedOnce) {
          hasDataBeenFetchedOnce = false;
        }
      } else {
        final dynamic responseData =
            await apiService.fetchData(appConfig.apiEndpoints.currencyUrl);
        List<CurrencyAsset> fetchedAssets = [];
        if (responseData is Map) {
          List<dynamic> listData = [];
          if (responseData.containsKey('items')) {
            listData = responseData['items'] as List<dynamic>;
          } else if (responseData.containsKey('currency')) {
            listData = responseData['currency'] as List<dynamic>;
          }
          fetchedAssets = listData
              .map((item) =>
                  CurrencyAsset.fromJson(item as Map<String, dynamic>))
              .toList();
        }

        final List<String> priorityList = appConfig.priorityCurrency;

        final List<CurrencyAsset> priorityAssetsList = [];
        final List<CurrencyAsset> otherAssets = [];
        if (priorityList.isNotEmpty) {
          for (final symbol in priorityList) {
            priorityAssetsList
                .addAll(fetchedAssets.where((a) => a.symbol == symbol));
          }
          for (final assetInFetched in fetchedAssets) {
            if (!priorityAssetsList.any((pa) => pa.id == assetInFetched.id)) {
              otherAssets.add(assetInFetched);
            }
          }
          _fullDataList = [...priorityAssetsList, ...otherAssets];
        } else {
          _fullDataList = fetchedAssets;
        }

        currencyAssets =
            _fullDataList.take(appConfig.initialItemsToLoad).toList();
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
      if (!_disposed) notifyListeners();
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
