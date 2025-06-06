import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dio/dio.dart';
// provider.dart is not used for FutureProvider, it's part of the flutter foundation.
// For FutureProvider in a MultiProvider setup, you typically use `FutureProvider<AppConfig>.value` or similar.
// The function itself is what's important here.
import '../config/app_config.dart';

// The function that fetches AppConfig
Future<AppConfig> fetchAppConfig() async {
  final dio = Dio();
  Map<String, dynamic> localConfigJson;
  AppConfig loadedAppConfig = AppConfig.defaultConfig(); // Initialize here

  try {
    final localConfigString = await rootBundle.loadString('assets/config/app_config.json');
    localConfigJson = jsonDecode(localConfigString) as Map<String, dynamic>;
  } catch (e) {
    // print('Error loading local config asset, using default AppConfig structure: $e');
    // If local asset fails, start with AppConfig.defaultConfig() to ensure essential structure and URLs (like remote_config_url)
    loadedAppConfig = AppConfig.defaultConfig();
    // Attempt to use remote_config_url from this default to fetch potentially valid remote config
    // This is a change from directly returning defaultConfig(), to allow remote override even if local asset is missing/corrupt
    localConfigJson = {}; // Prevent using a potentially corrupt localConfigJson later
  }

  // Determine initial AppConfig (local, remote, or default)
  // If localConfigJson was loaded successfully, try remote, then fallback to local.
  // If localConfigJson failed to load, loadedAppConfig is already AppConfig.defaultConfig().
  if (localConfigJson.isNotEmpty) { // successfully loaded local config asset
      try {
        final remoteUrl = localConfigJson['remote_config_url'] as String?;
        if (remoteUrl != null && remoteUrl.isNotEmpty) {
          final response = await dio.get(remoteUrl);
          if (response.statusCode == 200) {
            final data = response.data;
            final remoteJson = data is String
                ? jsonDecode(data) as Map<String, dynamic>
                : data as Map<String, dynamic>;
            // print('Successfully loaded remote config.');
            loadedAppConfig = AppConfig.fromJson(remoteJson);
          } else {
            // print('Failed to load remote config (status: ${response.statusCode}), using local config.');
            loadedAppConfig = AppConfig.fromJson(localConfigJson);
          }
        } else {
          // print('Remote URL not configured or empty, using local config.');
          loadedAppConfig = AppConfig.fromJson(localConfigJson);
        }
      } catch (e) {
        // print('Error loading remote config, using local config: $e');
        loadedAppConfig = AppConfig.fromJson(localConfigJson);
      }
  } else {
      // This path is taken if localConfigJson failed to load from assets,
      // loadedAppConfig is already AppConfig.defaultConfig().
      // We attempt to fetch remote config using the default remote_config_url.
      final defaultRemoteUrl = loadedAppConfig.remoteConfigUrl;
      if (defaultRemoteUrl.isNotEmpty) {
          try {
              final response = await dio.get(defaultRemoteUrl);
              if (response.statusCode == 200) {
                  final data = response.data;
                  final remoteJson = data is String
                      ? jsonDecode(data) as Map<String, dynamic>
                      : data as Map<String, dynamic>;
                  // print('Successfully loaded remote config using default remote URL.');
                  loadedAppConfig = AppConfig.fromJson(remoteJson);
              } else {
                  // print('Failed to load remote config using default remote URL (status: ${response.statusCode}), using default AppConfig.');
                  // loadedAppConfig remains AppConfig.defaultConfig()
              }
          } catch (e) {
              // print('Error loading remote config using default remote URL, using default AppConfig: $e');
              // loadedAppConfig remains AppConfig.defaultConfig()
          }
      } else {
          // print('Default remote URL is empty, using default AppConfig.');
          // loadedAppConfig remains AppConfig.defaultConfig()
      }
  }

  AppConfig finalAppConfig = loadedAppConfig;

  if (finalAppConfig.apiEndpoints.priorityAssetsUrl.isNotEmpty) {
    try {
      final response = await dio.get(finalAppConfig.apiEndpoints.priorityAssetsUrl);
      if (response.statusCode == 200) {
        final priorityData = response.data is String
            ? jsonDecode(response.data) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;

        finalAppConfig = finalAppConfig.copyWithPriorityAssets(
          priorityCurrency: List<String>.from(priorityData['currency'] as List<dynamic>? ?? []),
          priorityGold: List<String>.from(priorityData['gold'] as List<dynamic>? ?? []),
          priorityCrypto: List<String>.from(priorityData['crypto'] as List<dynamic>? ?? []),
            priorityCommodity: List<String>.from(priorityData['commodity'] as List<dynamic>? ?? []), // Added
        );
        // print('Successfully loaded and merged priority assets.');
      } else {
        // print('Failed to load priority assets, status code: ${response.statusCode}');
      }
    } catch (e) {
      // print('Error loading priority assets, using AppConfig without them: $e');
    }
  }
  return finalAppConfig;
}
