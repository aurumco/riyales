import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../models/asset_models.dart';
import '../../../config/app_config.dart';
import '../../../services/api_service.dart';
import '../../../services/connection_service.dart';

class GoldDataNotifier extends ChangeNotifier {
  final ApiService apiService;
  final AppConfig appConfig;
  final ConnectionService connectionService;

  bool isLoading = false;
  String? error;
  List<GoldAsset> goldAssets = []; // Public list for current items

  // int _currentlyLoadedCount = 0; // Replaced by items.length for loadMore
  List<GoldAsset> _fullDataList = [];
  // Timer? _updateTimer; // Removed

  bool hasDataBeenFetchedOnce = false;
  DateTime? lastFetchTime;
  bool _isLoadingMore = false;

  // Public getter for the full data list
  List<GoldAsset> get fullDataList => _fullDataList;
  // Public getter for the paginated/currently visible items
  List<GoldAsset> get items => goldAssets;

  GoldDataNotifier(
      {required this.apiService,
      required this.appConfig,
      required this.connectionService}) {
    // Initial fetch removed to defer loading until tab is activated
  }

  Future<void> fetchInitialData(
      {bool isRefresh = false, bool isLoadMore = false}) async {
    const bool isSpecialFetch =
        false; // GoldDataNotifier doesn't have special fetches like crypto favorites

    if (isLoadMore) {
      if (_isLoadingMore ||
          (_fullDataList.isNotEmpty &&
              goldAssets.length >= _fullDataList.length)) {
        // Added braces
        return;
      }
      _isLoadingMore = true;
      // notifyListeners(); // Optional

      final currentLength = goldAssets.length;
      final int end =
          (currentLength + appConfig.itemsPerLazyLoad > _fullDataList.length)
              ? _fullDataList.length
              : currentLength + appConfig.itemsPerLazyLoad;
      if (currentLength < end) {
        // Added braces
        goldAssets.addAll(_fullDataList.sublist(currentLength, end));
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
      // Check primary gold URL connection first
      final bool isGoldOnline = await connectionService
          .checkConnection(appConfig.apiEndpoints.goldUrl);
      // Check commodity URL connection (only if URL is provided)
      final commodityUrl = appConfig.apiEndpoints.commodityUrl;
      bool isCommodityOnline = false;
      if (commodityUrl.isNotEmpty) {
        isCommodityOnline =
            await connectionService.checkConnection(commodityUrl);
      }

      if (!isGoldOnline && (commodityUrl.isEmpty || !isCommodityOnline)) {
        error = "Offline"; // Both are offline
        if (!isRefresh && !hasDataBeenFetchedOnce) {
          hasDataBeenFetchedOnce = false;
        }
      } else {
        // Fetch local gold prices
        List<GoldAsset> fetchedGoldAssets = [];
        if (isGoldOnline) {
          // Only fetch if online
          final dynamic goldResponseData =
              await apiService.fetchData(appConfig.apiEndpoints.goldUrl);
          if (goldResponseData is Map && goldResponseData.containsKey('gold')) {
            fetchedGoldAssets.addAll(
              (goldResponseData['gold'] as List)
                  .map((item) =>
                      GoldAsset.fromJson(item as Map<String, dynamic>))
                  .toList(),
            );
          }
        } else if (commodityUrl.isNotEmpty && isCommodityOnline) {
          // Gold is offline, but commodities might be online. Set error for partial data.
          error = "Gold data offline; showing commodities only.";
        }

        // Fetch commodity data
        List<GoldAsset> commodityAssets = [];
        if (commodityUrl.isNotEmpty && isCommodityOnline) {
          // Only fetch if URL exists and is online
          final dynamic commodityResponseData =
              await apiService.fetchData(commodityUrl);
          if (commodityResponseData is Map) {
            final preciousList =
                commodityResponseData['metal_precious'] as List<dynamic>? ?? [];
            final baseList =
                commodityResponseData['metal_base'] as List<dynamic>? ?? [];
            final energyList =
                commodityResponseData['energy'] as List<dynamic>? ?? [];

            commodityAssets.addAll(preciousList
                .map((item) => GoldAsset.fromJson(item as Map<String, dynamic>,
                    isCommodity: true))
                .toList());
            commodityAssets.addAll(baseList
                .map((item) => GoldAsset.fromJson(item as Map<String, dynamic>,
                    isCommodity: true))
                .toList());
            commodityAssets.addAll(energyList
                .map((item) => GoldAsset.fromJson(item as Map<String, dynamic>,
                    isCommodity: true))
                .toList());
          }
        } else if (isGoldOnline &&
            commodityUrl.isNotEmpty &&
            !isCommodityOnline) {
          // Commodities are offline, but gold might be online. Set error for partial data.
          if (error == null) {
            error = "Commodity data offline; showing gold only.";
          } else {
            error = '${error!} Commodity data offline.';
          }
        }

        // Combine gold and commodity assets, avoiding duplicates by id
        final List<GoldAsset> combinedAssets = [];
        final Set<String> seenIds = {};
        for (final asset in fetchedGoldAssets) {
          if (seenIds.add(asset.id)) {
            combinedAssets.add(asset);
          }
        }
        for (final asset in commodityAssets) {
          if (seenIds.add(asset.id)) {
            combinedAssets.add(asset);
          }
        }

        // Load priority lists
        final List<String> goldPriorityList =
            appConfig.priorityGold; // Use pre-loaded list
        final List<String> commodityPriorityList =
            appConfig.priorityCommodity; // Use pre-loaded list
        // // Only attempt to fetch priority if at least one main data source was online // Kept for reference, logic removed
        // if(isGoldOnline || (commodityUrl.isNotEmpty && isCommodityOnline)) {
        //     try {
        //         final dynamic priorityResponse = await apiService.fetchData(appConfig.apiEndpoints.priorityAssetsUrl);
        //         if (priorityResponse is Map<String, dynamic>) {
        //         goldPriorityList = List<String>.from(priorityResponse['gold'] as List<dynamic>? ?? []);
        //         commodityPriorityList = List<String>.from(priorityResponse['commodity'] as List<dynamic>? ?? []);
        //         }
        //     } catch (_) {
        //         // Failed to load priority lists, proceed without them
        //     }
        // }

        // Apply priority
        final List<GoldAsset> sortedPriorityGold = [];
        final List<GoldAsset> remainingAfterGoldPriority = [];
        if (goldPriorityList.isNotEmpty) {
          for (final symbol in goldPriorityList) {
            sortedPriorityGold.addAll(combinedAssets
                .where((a) => a.symbol == symbol && !a.isCommodity));
          }
          for (final asset in combinedAssets) {
            if (!sortedPriorityGold.any((sa) => sa.id == asset.id)) {
              remainingAfterGoldPriority.add(asset);
            }
          }
        } else {
          remainingAfterGoldPriority.addAll(combinedAssets);
        }

        final List<GoldAsset> sortedPriorityCommodities = [];
        final List<GoldAsset> otherAssets = [];

        if (commodityPriorityList.isNotEmpty) {
          for (final symbol in commodityPriorityList) {
            sortedPriorityCommodities.addAll(remainingAfterGoldPriority.where(
                (a) =>
                    a.symbol.toLowerCase() == symbol.toLowerCase() &&
                    a.isCommodity));
          }
          for (final asset in remainingAfterGoldPriority) {
            if (!sortedPriorityCommodities.any((sa) => sa.id == asset.id)) {
              otherAssets.add(asset);
            }
          }
        } else {
          otherAssets.addAll(remainingAfterGoldPriority);
        }

        _fullDataList = [
          ...sortedPriorityGold,
          ...sortedPriorityCommodities,
          ...otherAssets
        ];
        goldAssets = _fullDataList.take(appConfig.initialItemsToLoad).toList();
        // If there was a partial offline error but some data was fetched, keep it, otherwise clear if all successful
        if (isGoldOnline && (commodityUrl.isEmpty || isCommodityOnline)) {
          error = null;
        }
      }

      if (error == null && !isSpecialFetch) {
        hasDataBeenFetchedOnce = true;
        lastFetchTime = DateTime.now();
        //  if (!isRefresh) { // Removed call to _startAutoRefresh
        //    _startAutoRefresh();
        //  }
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

  // void loadMore() { // Integrated into fetchInitialData
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
  //    final updateIntervalMs = appConfig.priceUpdateIntervalMinutes * 60 * 1000;
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
