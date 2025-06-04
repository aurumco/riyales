import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dio/dio.dart';
// provider.dart is not used for FutureProvider, it's part of the flutter foundation.
// For FutureProvider in a MultiProvider setup, you typically use `FutureProvider<AppConfig>.value` or similar.
// The function itself is what's important here.
import '../config/app_config.dart';

// The function that fetches AppConfig
Future<AppConfig> fetchAppConfig() async {
  final dio = Dio(); // Instantiate Dio here or get from another provider if set up
  Map<String, dynamic> localConfigJson;
  try {
    final localConfigString = await rootBundle.loadString('assets/config/app_config.json');
    localConfigJson = jsonDecode(localConfigString) as Map<String, dynamic>;
  } catch (e) {
    // print('Error loading local config, using default: $e');
    return AppConfig.defaultConfig(); // Fallback to default if local load fails
  }

  // Attempt to fetch remote config
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
        return AppConfig.fromJson(remoteJson);
      } else {
        // print('Failed to load remote config, status code: ${response.statusCode}');
      }
    }
  } catch (e) {
    // print('Error loading remote config, using local: $e');
    // Ignore and fallback to local
  }
  // print('Falling back to local config.');
  return AppConfig.fromJson(localConfigJson); // Fallback to local config
}
