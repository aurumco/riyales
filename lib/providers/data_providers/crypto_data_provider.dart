import 'dart:async';
import 'dart:math' as math; // Ensure this import is present and correct
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
  List<CryptoAsset> cryptoAssets = [];

  List<CryptoAsset> _fullDataList = [];

  bool hasDataBeenFetchedOnce = false;
  DateTime? lastFetchTime;
  bool _isLoadingMore = false;

  List<CryptoAsset> get fullDataList => _fullDataList;
  List<CryptoAsset> get items => cryptoAssets;

  CryptoDataNotifier(
      {required this.apiService,
      required this.appConfig,
      required this.connectionService});

  Future<void> fetchInitialData(
      {bool isRefresh = false,
      bool isLoadMore = false,
      List<String>? favoriteIds}) async {
    final bool isSpecialFetch = (favoriteIds != null && favoriteIds.isNotEmpty);

    if (isLoadMore) {
      if (isSpecialFetch || _isLoadingMore || cryptoAssets.length >= _fullDataList.length) {
        if (_isLoadingMore && cryptoAssets.length >= _fullDataList.length) {
            _isLoadingMore = false;
        }
        return;
      }

      _isLoadingMore = true;

      final currentLength = cryptoAssets.length;
      final itemsToLoad = appConfig.itemsPerLazyLoad;
      // Corrected usage of math.min
      int end = math.min(currentLength + itemsToLoad, _fullDataList.length);

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
          cryptoAssets = fetchedAssets
              .where((asset) => favoriteIds.contains(asset.id))
              .toList();
        } else {
          final List<String> priorityList = appConfig.priorityCrypto;

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
                  (a) =>
                      a.name.toLowerCase() == lowerName &&
                      !usedAssetIds.contains(a.id));
              for (final assetToPrio in assetsToPrio) {
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
      await fetchInitialData(isRefresh: true, favoriteIds: null);
    }
  }

  // @override // Removed unnecessary override
  // void dispose() {
  //   super.dispose();
  // }
}

