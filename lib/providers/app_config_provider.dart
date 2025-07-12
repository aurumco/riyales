import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dio/dio.dart';
import '../config/app_config.dart';

/// Fetches the application configuration from local assets or remote endpoint.
Future<AppConfig> fetchAppConfig() async {
  final dio = Dio();
  late final Map<String, dynamic> localConfigJson;
  AppConfig loadedAppConfig = AppConfig.defaultConfig();

  try {
    final localConfigString =
        await rootBundle.loadString('assets/config/app_config.json');
    localConfigJson = jsonDecode(localConfigString) as Map<String, dynamic>;
  } catch (e) {
    loadedAppConfig = AppConfig.defaultConfig();
    localConfigJson = {};
  }

  if (localConfigJson.isNotEmpty) {
    try {
      final remoteUrl = localConfigJson['remote_config_url'] as String?;
      if (remoteUrl != null && remoteUrl.isNotEmpty) {
        final response = await dio.get(remoteUrl);
        if (response.statusCode == 200) {
          final data = response.data;
          final remoteJson = data is String
              ? jsonDecode(data) as Map<String, dynamic>
              : data as Map<String, dynamic>;
          loadedAppConfig = AppConfig.fromJson(remoteJson);
        } else {
          loadedAppConfig = AppConfig.fromJson(localConfigJson);
        }
      } else {
        loadedAppConfig = AppConfig.fromJson(localConfigJson);
      }
    } catch (_) {
      loadedAppConfig = AppConfig.fromJson(localConfigJson);
    }
  } else {
    final defaultRemoteUrl = loadedAppConfig.remoteConfigUrl;
    if (defaultRemoteUrl.isNotEmpty) {
      try {
        final response = await dio.get(defaultRemoteUrl);
        if (response.statusCode == 200) {
          final data = response.data;
          final remoteJson = data is String
              ? jsonDecode(data) as Map<String, dynamic>
              : data as Map<String, dynamic>;
          loadedAppConfig = AppConfig.fromJson(remoteJson);
        }
      } catch (_) {}
    }
  }

  // Override priorityAssetsUrl with local value
  final localPriorityUrl = (localConfigJson['api_endpoints']
          as Map<String, dynamic>?)?['priority_assets_url'] as String? ??
      loadedAppConfig.apiEndpoints.priorityAssetsUrl;
  final updatedEndpoints = ApiEndpoints(
    currencyUrl: loadedAppConfig.apiEndpoints.currencyUrl,
    goldUrl: loadedAppConfig.apiEndpoints.goldUrl,
    commodityUrl: loadedAppConfig.apiEndpoints.commodityUrl,
    cryptoUrl: loadedAppConfig.apiEndpoints.cryptoUrl,
    stockDebtSecuritiesUrl: loadedAppConfig.apiEndpoints.stockDebtSecuritiesUrl,
    stockFuturesUrl: loadedAppConfig.apiEndpoints.stockFuturesUrl,
    stockHousingFacilitiesUrl:
        loadedAppConfig.apiEndpoints.stockHousingFacilitiesUrl,
    stockTseIfbSymbolsUrl: loadedAppConfig.apiEndpoints.stockTseIfbSymbolsUrl,
    priorityAssetsUrl: localPriorityUrl,
    termsEnUrl: loadedAppConfig.apiEndpoints.termsEnUrl,
    termsFaUrl: loadedAppConfig.apiEndpoints.termsFaUrl,
  );
  loadedAppConfig = AppConfig(
    appName: loadedAppConfig.appName,
    remoteConfigUrl: loadedAppConfig.remoteConfigUrl,
    apiEndpoints: updatedEndpoints,
    priceUpdateIntervalMinutes: loadedAppConfig.priceUpdateIntervalMinutes,
    updateIntervalMs: loadedAppConfig.updateIntervalMs,
    supportedLocales: loadedAppConfig.supportedLocales,
    defaultLocale: loadedAppConfig.defaultLocale,
    themeOptions: loadedAppConfig.themeOptions,
    fonts: loadedAppConfig.fonts,
    splashScreen: loadedAppConfig.splashScreen,
    itemsPerLazyLoad: loadedAppConfig.itemsPerLazyLoad,
    initialItemsToLoad: loadedAppConfig.initialItemsToLoad,
    cryptoIconFilter: loadedAppConfig.cryptoIconFilter,
    featureFlags: loadedAppConfig.featureFlags,
    updateInfo: loadedAppConfig.updateInfo,
    priorityCurrency: loadedAppConfig.priorityCurrency,
    priorityGold: loadedAppConfig.priorityGold,
    priorityCrypto: loadedAppConfig.priorityCrypto,
    priorityCommodity: loadedAppConfig.priorityCommodity,
  );

  AppConfig finalAppConfig = loadedAppConfig;

  if (finalAppConfig.apiEndpoints.priorityAssetsUrl.isNotEmpty) {
    try {
      final response =
          await dio.get(finalAppConfig.apiEndpoints.priorityAssetsUrl);
      if (response.statusCode == 200) {
        final priorityData = response.data is String
            ? jsonDecode(response.data) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;

        finalAppConfig = finalAppConfig.copyWithPriorityAssets(
          priorityCurrency: List<String>.from(
              priorityData['currency'] as List<dynamic>? ?? []),
          priorityGold:
              List<String>.from(priorityData['gold'] as List<dynamic>? ?? []),
          priorityCrypto:
              List<String>.from(priorityData['crypto'] as List<dynamic>? ?? []),
          priorityCommodity: List<String>.from(
              priorityData['commodity'] as List<dynamic>? ?? []), // Added
        );
      }
    } catch (_) {}
  }
  return finalAppConfig;
}
