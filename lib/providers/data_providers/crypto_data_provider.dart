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

  // int _currentlyLoadedCount = 0; // Replaced by items.length for loadMore
  List<CryptoAsset> _fullDataList = [];
  // Timer? _updateTimer; // Removed

  bool hasDataBeenFetchedOnce = false;
  DateTime? lastFetchTime;
  bool _isLoadingMore = false;
  // bool _isCurrentlyShowingFavorites = false; // Consider if needed for fetchDataIfStale

  // Public getter for the full data list
  List<CryptoAsset> get fullDataList => _fullDataList;
  // Public getter for the paginated/currently visible items
  List<CryptoAsset> get items => cryptoAssets;

  CryptoDataNotifier(
      {required this.apiService,
      required this.appConfig,
      required this.connectionService}) {
    // Initial fetch removed to defer loading until tab is activated
  }

  Future<void> fetchInitialData(
      {bool isRefresh = false,
      bool isLoadMore = false,
      List<String>? favoriteIds}) async {
    final bool isSpecialFetch = (favoriteIds != null && favoriteIds.isNotEmpty);

    if (isLoadMore) {
      // Load more should not apply if we are showing a special list like favorites
      if (isSpecialFetch ||
          _isLoadingMore ||
          (_fullDataList.isNotEmpty &&
              cryptoAssets.length >= _fullDataList.length)) {
        return;
      }
      _isLoadingMore = true;
      // notifyListeners(); // Optional

      final currentLength = cryptoAssets.length;
      final int end =
          (currentLength + appConfig.itemsPerLazyLoad > _fullDataList.length)
              ? _fullDataList.length
              : currentLength + appConfig.itemsPerLazyLoad;
      if (currentLength < end) {
        cryptoAssets.addAll(_fullDataList.sublist(currentLength, end));
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
      final bool isOnline = await connectionService
          .checkConnection(appConfig.apiEndpoints.cryptoUrl);
      if (!isOnline) {
        error = "Offline";
        if (!isRefresh && !isSpecialFetch && !hasDataBeenFetchedOnce) {
          // Check !hasDataBeenFetchedOnce for initial offline
          hasDataBeenFetchedOnce = false;
        }
      } else {
        final dynamic responseData =
            await apiService.fetchData(appConfig.apiEndpoints.cryptoUrl);
        List<CryptoAsset> fetchedAssets = [];
        if (responseData is List) {
          fetchedAssets = responseData
              .map((item) => CryptoAsset.fromJson(item as Map<String, dynamic>))
              .toList();
        }

        if (isSpecialFetch) {
          // Filter for favorites and directly assign to cryptoAssets
          // This assumes favoriteIds contains the asset.id
          cryptoAssets = fetchedAssets
              .where((asset) => favoriteIds.contains(asset.id))
              .toList(); // Removed !
          // _isCurrentlyShowingFavorites = true; // Set flag if needed
        } else {
          // _isCurrentlyShowingFavorites = false; // Reset flag
          final List<String> priorityList =
              appConfig.priorityCrypto; // Use pre-loaded list
          // try { // Remove old fetching logic
          //   final dynamic priorityResponse = await apiService
          //       .fetchData(appConfig.apiEndpoints.priorityAssetsUrl);
          //   if (priorityResponse is Map<String, dynamic>) {
          //     priorityList = List<String>.from(
          //         priorityResponse['crypto'] as List<dynamic>? ?? []);
          //   }
          // } catch (_) {
          //   // Failed to load priority list
          // }

          final List<CryptoAsset> iconAssets = [];
          for (final key in cryptoIconMap.keys) {
            iconAssets.addAll(fetchedAssets
                .where((a) => a.name.toLowerCase() == key.toLowerCase()));
          }
          final Set<String> usedAssetIds = iconAssets.map((a) => a.id).toSet();

          final List<CryptoAsset> sortedList = [];
          sortedList.addAll(iconAssets);

          if (priorityList.isNotEmpty) {
            for (final name in priorityList) {
              final lowerName = name.toLowerCase();
              final assetsToPrio = fetchedAssets.where(
                  (a) => // Renamed to avoid conflict
                      a.name.toLowerCase() == lowerName &&
                      !usedAssetIds.contains(a.id));
              for (final assetToPrio in assetsToPrio) {
                // Renamed to avoid conflict
                sortedList.add(assetToPrio);
                usedAssetIds.add(assetToPrio.id);
              }
            }
          }
          final remaining =
              fetchedAssets.where((a) => !usedAssetIds.contains(a.id)).toList();
          sortedList.addAll(remaining);
          _fullDataList = sortedList;
          cryptoAssets =
              _fullDataList.take(appConfig.initialItemsToLoad).toList();
        }
        error = null; // Clear error if data fetch was successful
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
    // If currently showing favorites, an explicit refresh (pull-to-refresh) or re-selecting favorites
    // would be the way to update them, not this staleness check for the main list.
    // if (_isCurrentlyShowingFavorites) return;

    if (!hasDataBeenFetchedOnce ||
        lastFetchTime == null ||
        DateTime.now().difference(lastFetchTime!) > staleness) {
      // Passing null for favoriteIds to ensure it fetches the main list
      await fetchInitialData(isRefresh: true, favoriteIds: null);
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
