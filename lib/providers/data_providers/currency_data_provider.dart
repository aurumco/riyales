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

  // int _currentlyLoadedCount = 0; // Replaced by items.length for loadMore
  List<CurrencyAsset> _fullDataList = [];
  // Timer? _updateTimer; // Removed

  bool hasDataBeenFetchedOnce = false;
  DateTime? lastFetchTime;
  bool _isLoadingMore = false;

  // Public getter for the full data list (primarily for search)
  List<CurrencyAsset> get fullDataList => _fullDataList;
  // Public getter for the paginated/currently visible items
  List<CurrencyAsset> get items => currencyAssets;

  CurrencyDataNotifier(
      {required this.apiService,
      required this.appConfig,
      required this.connectionService}) {
    // Initial fetch removed to defer loading until tab is activated
  }

  Future<void> fetchInitialData(
      {bool isRefresh = false, bool isLoadMore = false}) async {
    // Determine if this call is for fetching a special list (e.g., favorites in Crypto)
    // For CurrencyDataNotifier, isSpecialFetch is always false as it doesn't have favoriteIds parameter.
    const bool isSpecialFetch = false;

    // Handle Load More first
    if (isLoadMore) {
      if (_isLoadingMore ||
          (_fullDataList.isNotEmpty &&
              currencyAssets.length >= _fullDataList.length)) {
        return;
      }
      _isLoadingMore = true;
      // notifyListeners(); // Optional: notify that loading more has started

      final currentLength = currencyAssets.length;
      final int end =
          (currentLength + appConfig.itemsPerLazyLoad > _fullDataList.length)
              ? _fullDataList.length
              : currentLength + appConfig.itemsPerLazyLoad;
      if (currentLength < end) {
        currencyAssets.addAll(_fullDataList.sublist(currentLength, end));
      }

      _isLoadingMore = false;
      notifyListeners();
      return;
    }

    // This is a full fetch (initial load or forced refresh for main data)
    if (!isRefresh && !isSpecialFetch && hasDataBeenFetchedOnce) {
      if (isLoading) {
        // If called while already loading (e.g. from constructor then immediately from UI)
        isLoading = false; // Ensure loading state is reset if we return early
        notifyListeners();
      }
      return;
    }

    isLoading = true;
    // Clear error only if it's a refresh of main data
    if (isRefresh) {
      error = null;
    }
    notifyListeners();

    try {
      final bool isOnline = await connectionService
          .checkConnection(appConfig.apiEndpoints.currencyUrl);
      if (!isOnline) {
        error = "Offline"; // Or a localized message
        // TODO: Implement loading cached data if necessary
        // Only set hasDataBeenFetchedOnce to false if this was the initial attempt and it failed due to offline
        if (!isRefresh && !hasDataBeenFetchedOnce) {
          hasDataBeenFetchedOnce = false;
        }
        // Do not throw here, allow finally to run
      } else {
        final dynamic responseData =
            await apiService.fetchData(appConfig.apiEndpoints.currencyUrl);
        List<CurrencyAsset> fetchedAssets = [];
        if (responseData is Map && responseData.containsKey('currency')) {
          fetchedAssets = (responseData['currency'] as List)
              .map((item) =>
                  CurrencyAsset.fromJson(item as Map<String, dynamic>))
              .toList();
        }

        final List<String> priorityList =
            appConfig.priorityCurrency; // Use pre-loaded list
        // try { // Remove old fetching logic
        //   final dynamic priorityResponse = await apiService
        //       .fetchData(appConfig.apiEndpoints.priorityAssetsUrl);
        //   if (priorityResponse is Map<String, dynamic>) {
        //     priorityList = List<String>.from(
        //         priorityResponse['currency'] as List<dynamic>? ?? []);
        //   }
        // } catch (_) {
        //   // Failed to load or parse priority list, proceed without it
        // }

        final List<CurrencyAsset> priorityAssetsList =
            []; // Renamed to avoid conflict
        final List<CurrencyAsset> otherAssets = [];
        if (priorityList.isNotEmpty) {
          for (final symbol in priorityList) {
            priorityAssetsList
                .addAll(fetchedAssets.where((a) => a.symbol == symbol));
          }
          for (final assetInFetched in fetchedAssets) {
            // Renamed asset to assetInFetched
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
        // Only update if fetch was successful and not a special fetch
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
      // TODO: Load cached data on error if necessary
    } finally {
      isLoading = false;
      _isLoadingMore = false; // Ensure this is reset too
      notifyListeners();
    }
  }

  // void loadMore() { // This method is now integrated into fetchInitialData
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
  //     _updateTimer =
  //         Timer.periodic(Duration(milliseconds: updateIntervalMs), (timer) {
  //       fetchInitialData(isRefresh: true);
  //     });
  //   }
  // }

  @override
  void dispose() {
    // _updateTimer?.cancel(); // Removed timer cancellation
    super.dispose();
  }
}
