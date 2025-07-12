import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../models/asset_models.dart';
import '../../../config/app_config.dart';
import '../../../services/api_service.dart';
import '../../../services/connection_service.dart';

/// Provides gold and commodity price data with pagination and caching.
class GoldDataNotifier extends ChangeNotifier {
  final ApiService apiService;
  final AppConfig appConfig;
  final ConnectionService connectionService;

  bool isLoading = false;
  String? error;
  List<GoldAsset> goldAssets = [];

  List<GoldAsset> _fullDataList = [];

  bool hasDataBeenFetchedOnce = false;
  DateTime? lastFetchTime;
  bool _isLoadingMore = false;

  List<GoldAsset> get fullDataList => _fullDataList;
  List<GoldAsset> get items => goldAssets;

  /// Creates a notifier for managing gold and commodity data.
  GoldDataNotifier(
      {required this.apiService,
      required this.appConfig,
      required this.connectionService});

  Future<void> fetchInitialData(
      {bool isRefresh = false, bool isLoadMore = false}) async {
    const bool isSpecialFetch = false;

    if (isLoadMore) {
      if (_isLoadingMore ||
          (_fullDataList.isNotEmpty &&
              goldAssets.length >= _fullDataList.length)) {
        return;
      }
      _isLoadingMore = true;
      // notify listeners when loading more is complete.

      final currentLength = goldAssets.length;
      final int end =
          (currentLength + appConfig.itemsPerLazyLoad > _fullDataList.length)
              ? _fullDataList.length
              : currentLength + appConfig.itemsPerLazyLoad;
      if (currentLength < end) {
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
      // Check connection for gold and commodity URLs
      final bool isGoldOnline = await connectionService
          .checkConnection(appConfig.apiEndpoints.goldUrl);
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
        List<GoldAsset> fetchedGoldAssets = [];
        if (isGoldOnline) {
          final dynamic goldResponseData =
              await apiService.fetchData(appConfig.apiEndpoints.goldUrl);
          if (goldResponseData is Map) {
            List<dynamic> goldList = [];
            if (goldResponseData.containsKey('items')) {
              goldList = goldResponseData['items'] as List<dynamic>;
            } else if (goldResponseData.containsKey('gold')) {
              goldList = goldResponseData['gold'] as List<dynamic>;
            }
            fetchedGoldAssets.addAll(
              goldList
                  .map((item) =>
                      GoldAsset.fromJson(item as Map<String, dynamic>))
                  .toList(),
            );
          }
        } else if (commodityUrl.isNotEmpty && isCommodityOnline) {
          // Gold is offline, but commodities might be online. Set error for partial data.
          error = "Gold data offline; showing commodities only.";
        }

        List<GoldAsset> commodityAssets = [];
        if (commodityUrl.isNotEmpty && isCommodityOnline) {
          final dynamic commodityResponseData =
              await apiService.fetchData(commodityUrl);
          if (commodityResponseData is Map) {
            final allCommodities =
                commodityResponseData['metalPrecious'] as List<dynamic>? ?? [];
            commodityAssets.addAll(allCommodities
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

        final List<String> goldPriorityList = appConfig.priorityGold;
        final List<String> commodityPriorityList = appConfig.priorityCommodity;

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
