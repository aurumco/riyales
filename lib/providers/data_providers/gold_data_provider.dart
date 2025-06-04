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

  int _currentlyLoadedCount = 0;
  List<GoldAsset> _fullDataList = [];
  Timer? _updateTimer;

  // Public getter for the full data list
  List<GoldAsset> get fullDataList => _fullDataList;
  // Public getter for the paginated/currently visible items
  List<GoldAsset> get items => goldAssets;

  GoldDataNotifier({required this.apiService, required this.appConfig, required this.connectionService}) {
    _currentlyLoadedCount = appConfig.initialItemsToLoad;
    fetchInitialData();
  }

  Future<void> fetchInitialData({bool isRefresh = false}) async {
    if (!isRefresh) {
      isLoading = true;
      error = null;
      notifyListeners();
    }

    final bool isOnline = await connectionService.checkConnection(appConfig.apiEndpoints.goldUrl);
    if (!isOnline) {
      error = "Offline"; // Or a localized message
      isLoading = false;
      notifyListeners();
      // TODO: Implement loading cached data
      return;
    }

    try {
      // Fetch local gold prices
      List<GoldAsset> fetchedGoldAssets = [];
      final dynamic goldResponseData = await apiService.fetchData(appConfig.apiEndpoints.goldUrl);
      if (goldResponseData is Map && goldResponseData.containsKey('gold')) {
        fetchedGoldAssets.addAll(
          (goldResponseData['gold'] as List)
              .map((item) => GoldAsset.fromJson(item as Map<String, dynamic>))
              .toList(),
        );
      }

      // Fetch commodity data
      List<GoldAsset> commodityAssets = [];
      final commodityUrl = appConfig.apiEndpoints.commodityUrl;
      if (commodityUrl.isNotEmpty) {
        final bool isCommodityOnline = await connectionService.checkConnection(commodityUrl);
        if (isCommodityOnline) {
          final dynamic commodityResponseData = await apiService.fetchData(commodityUrl);
          if (commodityResponseData is Map) {
            final preciousList = commodityResponseData['metal_precious'] as List<dynamic>? ?? [];
            final baseList = commodityResponseData['metal_base'] as List<dynamic>? ?? [];
            final energyList = commodityResponseData['energy'] as List<dynamic>? ?? [];

            commodityAssets.addAll(preciousList.map((item) => GoldAsset.fromJson(item as Map<String, dynamic>, isCommodity: true)).toList());
            commodityAssets.addAll(baseList.map((item) => GoldAsset.fromJson(item as Map<String, dynamic>, isCommodity: true)).toList());
            commodityAssets.addAll(energyList.map((item) => GoldAsset.fromJson(item as Map<String, dynamic>, isCommodity: true)).toList());
          }
        } else {
          // Potentially handle commodity offline differently or note partial data
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
      List<String> goldPriorityList = [];
      List<String> commodityPriorityList = [];
      try {
        final dynamic priorityResponse = await apiService.fetchData(appConfig.apiEndpoints.priorityAssetsUrl);
        if (priorityResponse is Map<String, dynamic>) {
          goldPriorityList = List<String>.from(priorityResponse['gold'] as List<dynamic>? ?? []);
          commodityPriorityList = List<String>.from(priorityResponse['commodity'] as List<dynamic>? ?? []);
        }
      } catch (_) {
        // Failed to load priority lists
      }

      // Apply priority
      final List<GoldAsset> sortedPriorityGold = [];
      final List<GoldAsset> remainingAfterGoldPriority = [];
      if (goldPriorityList.isNotEmpty) {
          for (final symbol in goldPriorityList) {
            sortedPriorityGold.addAll(combinedAssets.where((a) => a.symbol == symbol && !a.isCommodity));
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
            // Ensure case-insensitivity for commodity symbols if needed, original used .toLowerCase()
            sortedPriorityCommodities.addAll(remainingAfterGoldPriority.where((a) => a.symbol.toLowerCase() == symbol.toLowerCase() && a.isCommodity));
          }
           for (final asset in remainingAfterGoldPriority) {
            if (!sortedPriorityCommodities.any((sa) => sa.id == asset.id)) {
                 otherAssets.add(asset);
            }
          }
      } else {
          otherAssets.addAll(remainingAfterGoldPriority);
      }

      _fullDataList = [...sortedPriorityGold, ...sortedPriorityCommodities, ...otherAssets];
      goldAssets = _fullDataList.take(_currentlyLoadedCount).toList();
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
      _currentlyLoadedCount = (_currentlyLoadedCount + appConfig.itemsPerLazyLoad > _fullDataList.length)
          ? _fullDataList.length
          : _currentlyLoadedCount + appConfig.itemsPerLazyLoad;
      goldAssets = _fullDataList.take(_currentlyLoadedCount).toList();
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
