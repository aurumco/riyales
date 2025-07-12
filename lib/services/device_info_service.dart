/// Service to collect and send device and app information once per install.
library;

import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riyales/config/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceInfoService {
  final Dio _dio = Dio();
  static const String _deviceInfoSentKey = 'device_info_sent';
  static const String _apiKeyKey = 'ryls_api_key';
  static const String _installTimestampKey = 'ryls_install_timestamp';

  Future<String> _getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    String? apiKey = prefs.getString(_apiKeyKey);
    if (apiKey == null) {
      // Generate and persist a new API key if absent.
      final String uuid = const Uuid().v4();
      apiKey = 'RYLS-$uuid';
      await prefs.setString(_apiKeyKey, apiKey);
    }
    return apiKey;
  }

  Future<void> collectAndSendDeviceInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final bool alreadySent = prefs.getBool(_deviceInfoSentKey) ?? false;

    if (alreadySent) return;

    try {
      final deviceInfo = DeviceInfoPlugin();
      await PackageInfo.fromPlatform();
      final connectivityResult = await Connectivity().checkConnectivity();

      String? installTimestamp = prefs.getString(_installTimestampKey);
      if (installTimestamp == null) {
        installTimestamp = DateTime.now().toIso8601String();
        await prefs.setString(_installTimestampKey, installTimestamp);
      }

      final String deviceLanguage = kIsWeb
          ? PlatformDispatcher.instance.locale.toLanguageTag()
          : Platform.localeName;

      Map<String, dynamic> data = {
        'push_notification_enabled': false,
        'install_timestamp': installTimestamp,
        'device_language': deviceLanguage,
        'network_type': connectivityResult.toString().split('.').last,
      };

      String userAgent = 'Unknown';

      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        userAgent = webInfo.userAgent ?? 'WebApp';
        data.addAll({
          'os_name': webInfo.browserName.name,
          'device_type': 'web',
          'model': webInfo.appName ?? 'Unknown',
          'user_agent': webInfo.userAgent,
        });
      } else {
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
            final androidInfo = await deviceInfo.androidInfo;
            userAgent =
                'Android ${androidInfo.version.release} (Build ${androidInfo.id})';
            data.addAll({
              'device_brand': androidInfo.brand,
              'device_model': androidInfo.model,
              'os_name': 'Android',
              'os_version': androidInfo.version.release,
              'device_type':
                  androidInfo.isPhysicalDevice ? 'mobile' : 'emulator',
            });
            break;
          case TargetPlatform.iOS:
            final iosInfo = await deviceInfo.iosInfo;
            userAgent =
                '${iosInfo.systemName} ${iosInfo.systemVersion} (${iosInfo.utsname.machine})';
            data.addAll({
              'device_brand': 'Apple',
              'device_model': iosInfo.model,
              'os_name': 'iOS',
              'os_version': iosInfo.systemVersion,
              'device_type': iosInfo.isPhysicalDevice ? 'mobile' : 'simulator',
            });
            break;
          case TargetPlatform.macOS:
            final macInfo = await deviceInfo.macOsInfo;
            userAgent = 'macOS ${macInfo.osRelease}';
            data.addAll({
              'device_brand': 'Apple',
              'device_model': macInfo.model,
              'os_name': 'macOS',
              'os_version': macInfo.osRelease,
              'device_type': 'desktop',
            });
            break;
          case TargetPlatform.windows:
            final windowsInfo = await deviceInfo.windowsInfo;
            userAgent =
                'Windows ${windowsInfo.productName} ${windowsInfo.displayVersion}';
            data.addAll({
              'device_brand': windowsInfo.computerName,
              'device_model': 'PC',
              'os_name': 'Windows',
              'os_version': windowsInfo.displayVersion,
              'device_type': 'desktop',
            });
            break;
          case TargetPlatform.linux:
            final linuxInfo = await deviceInfo.linuxInfo;
            userAgent = 'Linux ${linuxInfo.version}';
            data.addAll({
              'device_brand': 'Unknown',
              'device_model': 'PC',
              'os_name': 'Linux',
              'os_version': linuxInfo.version,
              'device_type': 'desktop',
            });
            break;
          default:
            break;
        }
      }

      final response = await _dio.post(
        AppConstants.apiBaseUrl + AppConstants.deviceEndpoint,
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-API-Key': await _getApiKey(),
            'User-Agent': userAgent,
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await prefs.setBool(_deviceInfoSentKey, true);
      } else {}
    } catch (_) {
      // Suppress errors in production.
    }
  }
}
