import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui; // Modified import

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vibration/vibration.dart';
import 'package:equatable/equatable.dart';
import 'package:smooth_corner/smooth_corner.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:url_launcher/url_launcher.dart';

// Hardcoded current app version
const String currentAppVersion = '0.140.0'; // Update this with each release

// Extension methods
extension ColorExtension on Color {
  Color darken(int percent) {
    assert(1 <= percent && percent <= 100);
    final value = 1 - percent / 100;
    return Color.fromARGB(
      alpha,
      (red * value).round(),
      (green * value).round(),
      (blue * value).round(),
    );
  }

  Color lighten(int percent) {
    assert(1 <= percent && percent <= 100);
    final value = percent / 100;
    return Color.fromARGB(
      alpha,
      (red + ((255 - red) * value)).round(),
      (green + ((255 - green) * value)).round(),
      (blue + ((255 - blue) * value)).round(),
    );
  }
}

// Class for storing icon path and color for crypto icons
class CryptoIconInfo {
  final String iconPath;
  final Color color;

  const CryptoIconInfo({required this.iconPath, required this.color});
}

// region 0. Application Configuration (Constants and Models)

// --- App Config Model ---
// This model represents the structure of your app_config.json
class AppConfig extends Equatable {
  final String appName;
  final String remoteConfigUrl;
  final ApiEndpoints apiEndpoints;
  final int priceUpdateIntervalMinutes;
  final int updateIntervalMs;
  final List<String> supportedLocales;
  final String defaultLocale;
  final ThemeOptions themeOptions;
  final FontsConfig fonts;
  final SplashScreenConfig splashScreen;
  final int itemsPerLazyLoad;
  final int initialItemsToLoad;
  final CryptoIconFilterConfig cryptoIconFilter;
  final FeatureFlags featureFlags;
  final UpdateInfoConfig updateInfo; // New

  const AppConfig({
    required this.appName,
    required this.remoteConfigUrl,
    required this.apiEndpoints,
    required this.priceUpdateIntervalMinutes,
    required this.updateIntervalMs,
    required this.supportedLocales,
    required this.defaultLocale,
    required this.themeOptions,
    required this.fonts,
    required this.splashScreen,
    required this.itemsPerLazyLoad,
    required this.initialItemsToLoad,
    required this.cryptoIconFilter,
    required this.featureFlags,
    required this.updateInfo, // New
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    // Merge top-level app_version into update_info if present
    final updateMap = (json['update_info'] as Map<String, dynamic>?)
            ?.cast<String, dynamic>() ??
        {};
    if (json.containsKey('app_version')) {
      updateMap['latest_version'] = json['app_version'];
    }
    return AppConfig(
      appName: json['app_name'] as String? ?? 'Riyales',
      remoteConfigUrl: json['remote_config_url'] as String? ?? '',
      apiEndpoints: ApiEndpoints.fromJson(
        json['api_endpoints'] as Map<String, dynamic>? ?? {},
      ),
      priceUpdateIntervalMinutes:
          json['priceUpdateIntervalMinutes'] as int? ?? 5,
      updateIntervalMs: json['update_interval_ms'] as int? ?? 30000,
      supportedLocales: List<String>.from(
        json['supported_locales'] as List<dynamic>? ?? ['en', 'fa'],
      ),
      defaultLocale: json['default_locale'] as String? ?? 'fa',
      themeOptions: ThemeOptions.fromJson(
        json['theme_options'] as Map<String, dynamic>? ?? {},
      ),
      fonts: FontsConfig.fromJson(json['fonts'] as Map<String, dynamic>? ?? {}),
      splashScreen: SplashScreenConfig.fromJson(
        json['splashScreen'] as Map<String, dynamic>? ?? {},
      ),
      itemsPerLazyLoad: json['itemsPerLazyLoad'] as int? ?? 20,
      initialItemsToLoad: json['initialItemsToLoad'] as int? ?? 20,
      cryptoIconFilter: CryptoIconFilterConfig.fromJson(
        json['cryptoIconFilter'] as Map<String, dynamic>? ?? {},
      ),
      featureFlags: FeatureFlags.fromJson(
        json['feature_flags'] as Map<String, dynamic>? ?? {},
      ),
      updateInfo: UpdateInfoConfig.fromJson(updateMap),
    );
  }

  // Default fallback config
  factory AppConfig.defaultConfig() {
    return AppConfig.fromJson(const {
      "app_name": "Riyales",
      "remote_config_url":
          "https://raw.githubusercontent.com/aurumco/riyales-api/main/config.json",
      "api_endpoints": {
        "currency_url":
            "https://raw.githubusercontent.com/aurumco/riyales-api/main/api/v1/market/currency.json",
        "gold_url":
            "https://raw.githubusercontent.com/aurumco/riyales-api/main/api/v1/market/gold.json",
        "commodity_url":
            "https://raw.githubusercontent.com/aurumco/riyales-api/main/api/v1/market/commodity.json",
        "crypto_url":
            "https://raw.githubusercontent.com/aurumco/riyales-api/main/api/v1/market/cryptocurrency.json",
        "stock_debt_securities_url":
            "https://raw.githubusercontent.com/aurumco/riyales-api/main/api/v1/market/stock/debt_securities.json",
        "stock_futures_url":
            "https://raw.githubusercontent.com/aurumco/riyales-api/main/api/v1/market/stock/futures.json",
        "stock_housing_facilities_url":
            "https://raw.githubusercontent.com/aurumco/riyales-api/main/api/v1/market/stock/housing_facilities.json",
        "stock_tse_ifb_symbols_url":
            "https://raw.githubusercontent.com/aurumco/riyales-api/main/api/v1/market/stock/tse_ifb_symbols.json",
        "priority_assets_url":
            "https://raw.githubusercontent.com/aurumco/riyales-api/main/priority_assets.json",
        "terms_en_url": "https://example.com/terms_en.json", // Placeholder
        "terms_fa_url": "https://example.com/terms_fa.json", // Placeholder
      },
      "priceUpdateIntervalMinutes": 10,
      "update_interval_ms": 600000,
      "supported_locales": ["en", "fa"],
      "default_locale": "en",
      "theme_options": {
        "default_theme": "light",
        "light": {
          "brightness": "light",
          "primaryColor": "#FFFFFF",
          "backgroundColor": "#F2F2F7",
          "scaffoldBackgroundColor": "#F2F2F7",
          "appBarColor": "#F2F2F7",
          "cardColor": "#FFFFFF",
          "textColor": "#000000",
          "secondaryTextColor": "#8E8E93",
          "accentColorGreen": "#00B894",
          "accentColorRed": "#FF4444",
          "cardBorderRadius": 21.0,
          "shadowColor": "#000000",
          "cardCornerSmoothness": 0.90,
        },
        "dark": {
          "brightness": "dark",
          "primaryColor": "#1C1C1E",
          "backgroundColor": "#1C1C1E",
          "scaffoldBackgroundColor": "#1C1C1E",
          "appBarColor": "#1C1C1E",
          "cardColor": "#2C2C2E",
          "textColor": "#E5E5EA",
          "secondaryTextColor": "#8E8E93",
          "accentColorGreen": "#00B894",
          "accentColorRed": "#FF5252",
          "cardBorderRadius": 21.0,
          "shadowColor": "#000000",
          "backgroundGradientColors": ["#1C1C1E", "#2C2C2E"],
          "cardCornerSmoothness": 0.90,
        },
      },
      "fonts": {
        "persianFontFamily": "Vazirmatn",
        "englishFontFamily": "SF-Pro",
      },
      "splashScreen": {
        "durationSeconds": 1.5,
        "iconPath": "assets/images/splash-screen-light.svg",
        "loadingIndicatorColor": "#FBC02D",
      },
      "itemsPerLazyLoad": 20,
      "initialItemsToLoad": 20,
      "cryptoIconFilter": {
        "brightness": 0.0,
        "contrast": 0.0,
        "saturation": -0.2,
      },
      "feature_flags": {"enable_chat": false, "enable_notifications": true},
      "update_info": {
        // New
        "latest_version": "1.0.0", // Placeholder
        "update_url": "https://example.com/update", // Placeholder
        "changelog_en": "Initial release.", // Placeholder
        "changelog_fa": "نسخه اولیه.", // Placeholder
      },
    });
  }

  @override
  List<Object?> get props => [
        appName,
        remoteConfigUrl,
        apiEndpoints,
        priceUpdateIntervalMinutes,
        updateIntervalMs,
        supportedLocales,
        defaultLocale,
        themeOptions,
        fonts,
        splashScreen,
        itemsPerLazyLoad,
        initialItemsToLoad,
        cryptoIconFilter,
        featureFlags,
        updateInfo, // New
      ];
}

class ApiEndpoints extends Equatable {
  final String currencyUrl;
  final String goldUrl;
  final String commodityUrl;
  final String cryptoUrl;
  final String stockDebtSecuritiesUrl;
  final String stockFuturesUrl;
  final String stockHousingFacilitiesUrl;
  final String stockTseIfbSymbolsUrl;
  final String priorityAssetsUrl;
  final String termsEnUrl; // New: URL for English terms
  final String termsFaUrl; // New: URL for Persian terms

  const ApiEndpoints({
    required this.currencyUrl,
    required this.goldUrl,
    required this.commodityUrl,
    required this.cryptoUrl,
    required this.stockDebtSecuritiesUrl,
    required this.stockFuturesUrl,
    required this.stockHousingFacilitiesUrl,
    required this.stockTseIfbSymbolsUrl,
    required this.priorityAssetsUrl,
    required this.termsEnUrl, // New
    required this.termsFaUrl, // New
  });

  factory ApiEndpoints.fromJson(Map<String, dynamic> json) {
    return ApiEndpoints(
      currencyUrl: json['currency_url'] as String? ?? '',
      goldUrl: json['gold_url'] as String? ?? '',
      commodityUrl: json['commodity_url'] as String? ?? '',
      cryptoUrl: json['crypto_url'] as String? ?? '',
      stockDebtSecuritiesUrl:
          json['stock_debt_securities_url'] as String? ?? '',
      stockFuturesUrl: json['stock_futures_url'] as String? ?? '',
      stockHousingFacilitiesUrl:
          json['stock_housing_facilities_url'] as String? ?? '',
      stockTseIfbSymbolsUrl: json['stock_tse_ifb_symbols_url'] as String? ?? '',
      priorityAssetsUrl: json['priority_assets_url'] as String? ?? '',
      termsEnUrl: json['terms_en_url'] as String? ?? '', // New
      termsFaUrl: json['terms_fa_url'] as String? ?? '', // New
    );
  }
  @override
  List<Object?> get props => [
        currencyUrl,
        goldUrl,
        commodityUrl,
        cryptoUrl,
        stockDebtSecuritiesUrl,
        stockFuturesUrl,
        stockHousingFacilitiesUrl,
        stockTseIfbSymbolsUrl,
        priorityAssetsUrl,
        termsEnUrl, // New
        termsFaUrl, // New
      ];
}

class ThemeOptions extends Equatable {
  final String defaultTheme;
  final ThemeConfig light;
  final ThemeConfig dark;

  const ThemeOptions({
    required this.defaultTheme,
    required this.light,
    required this.dark,
  });

  factory ThemeOptions.fromJson(Map<String, dynamic> json) {
    return ThemeOptions(
      defaultTheme: json['default_theme'] as String? ?? 'dark',
      light: ThemeConfig.fromJson(json['light'] as Map<String, dynamic>? ?? {}),
      dark: ThemeConfig.fromJson(json['dark'] as Map<String, dynamic>? ?? {}),
    );
  }
  @override
  List<Object?> get props => [defaultTheme, light, dark];
}

class ThemeConfig extends Equatable {
  final String brightness;
  final String primaryColor;
  final String backgroundColor;
  final String scaffoldBackgroundColor;
  final String appBarColor;
  final String cardColor;
  final String textColor;
  final String secondaryTextColor;
  final String accentColorGreen;
  final String accentColorRed;
  final double cardBorderRadius;
  final String shadowColor;
  final List<String>? backgroundGradientColors;
  final double
      cardCornerSmoothness; // New: controls the squircle shape smoothness

  const ThemeConfig({
    required this.brightness,
    required this.primaryColor,
    required this.backgroundColor,
    required this.scaffoldBackgroundColor,
    required this.appBarColor,
    required this.cardColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.accentColorGreen,
    required this.accentColorRed,
    required this.cardBorderRadius,
    required this.shadowColor,
    this.backgroundGradientColors,
    this.cardCornerSmoothness = 0.6, // Default smoothness value
  });

  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    return ThemeConfig(
      brightness: json['brightness'] as String? ?? 'light',
      primaryColor: json['primaryColor'] as String? ?? '#FFFFFF',
      backgroundColor: json['backgroundColor'] as String? ?? '#F5F5F5',
      scaffoldBackgroundColor:
          json['scaffoldBackgroundColor'] as String? ?? '#F8F9FA',
      appBarColor: json['appBarColor'] as String? ?? '#FFFFFF',
      cardColor: json['cardColor'] as String? ?? '#FFFFFF',
      textColor: json['textColor'] as String? ?? '#1E1E1E',
      secondaryTextColor: json['secondaryTextColor'] as String? ?? '#525252',
      accentColorGreen: json['accentColorGreen'] as String? ?? '#00C851',
      accentColorRed: json['accentColorRed'] as String? ?? '#FF4444',
      cardBorderRadius: (json['cardBorderRadius'] as num?)?.toDouble() ?? 21.0,
      shadowColor: json['shadowColor'] as String? ?? '#000000',
      backgroundGradientColors:
          (json['backgroundGradientColors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      cardCornerSmoothness:
          (json['cardCornerSmoothness'] as num?)?.toDouble() ?? 0.90,
    );
  }
  @override
  List<Object?> get props => [
        brightness,
        primaryColor,
        backgroundColor,
        scaffoldBackgroundColor,
        appBarColor,
        cardColor,
        textColor,
        secondaryTextColor,
        accentColorGreen,
        accentColorRed,
        cardBorderRadius,
        shadowColor,
        backgroundGradientColors,
        cardCornerSmoothness,
      ];
}

class FontsConfig extends Equatable {
  final String persianFontFamily;
  final String englishFontFamily;

  const FontsConfig({
    required this.persianFontFamily,
    required this.englishFontFamily,
  });

  factory FontsConfig.fromJson(Map<String, dynamic> json) {
    return FontsConfig(
      persianFontFamily: json['persianFontFamily'] as String? ?? 'Vazirmatn',
      englishFontFamily: json['englishFontFamily'] as String? ?? 'SF-Pro',
    );
  }
  @override
  List<Object?> get props => [persianFontFamily, englishFontFamily];
}

class SplashScreenConfig extends Equatable {
  final double durationSeconds;
  final String iconPath;
  final String loadingIndicatorColor;

  const SplashScreenConfig({
    required this.durationSeconds,
    required this.iconPath,
    required this.loadingIndicatorColor,
  });

  factory SplashScreenConfig.fromJson(Map<String, dynamic> json) {
    return SplashScreenConfig(
      durationSeconds: (json['durationSeconds'] as num?)?.toDouble() ?? 1.5,
      iconPath: json['iconPath'] as String? ??
          'assets/images/splash-screen-light.svg',
      loadingIndicatorColor:
          json['loadingIndicatorColor'] as String? ?? '#FBC02D',
    );
  }
  @override
  List<Object?> get props => [durationSeconds, iconPath, loadingIndicatorColor];
}

class CryptoIconFilterConfig extends Equatable {
  final double brightness;
  final double contrast;
  final double saturation;

  const CryptoIconFilterConfig({
    required this.brightness,
    required this.contrast,
    required this.saturation,
  });

  factory CryptoIconFilterConfig.fromJson(Map<String, dynamic> json) {
    return CryptoIconFilterConfig(
      brightness: (json['brightness'] as num?)?.toDouble() ?? 0.0,
      contrast: (json['contrast'] as num?)?.toDouble() ?? 0.0,
      saturation: (json['saturation'] as num?)?.toDouble() ?? -0.2,
    );
  }
  @override
  List<Object?> get props => [brightness, contrast, saturation];
}

class FeatureFlags extends Equatable {
  final bool enableChat;
  final bool enableNotifications;

  const FeatureFlags({
    required this.enableChat,
    required this.enableNotifications,
  });

  factory FeatureFlags.fromJson(Map<String, dynamic> json) {
    return FeatureFlags(
      enableChat: json['enable_chat'] as bool? ?? false,
      enableNotifications: json['enable_notifications'] as bool? ?? true,
    );
  }
  @override
  List<Object?> get props => [enableChat, enableNotifications];
}

class UpdateInfoConfig extends Equatable {
  final String latestVersion;
  final String updateUrl;
  final String changelogEn;
  final String changelogFa;
  final String updateMode;
  final String updatePackage;
  final String updateLink;

  const UpdateInfoConfig({
    required this.latestVersion,
    required this.updateUrl,
    required this.changelogEn,
    required this.changelogFa,
    required this.updateMode,
    required this.updatePackage,
    required this.updateLink,
  });

  factory UpdateInfoConfig.fromJson(Map<String, dynamic> json) {
    return UpdateInfoConfig(
      latestVersion: json['latest_version'] as String? ?? '0.0.0',
      updateUrl: json['update_url'] as String? ?? '',
      changelogEn: json['changelog_en'] as String? ?? 'No new changes.',
      changelogFa:
          json['changelog_fa'] as String? ?? 'تغییرات جدیدی وجود ندارد.',
      updateMode: json['update_mode'] as String? ?? 'url',
      updatePackage: json['update_package'] as String? ?? '',
      updateLink: json['update_link'] as String? ?? '',
    );
  }

  factory UpdateInfoConfig.defaultConfig() {
    return const UpdateInfoConfig(
      latestVersion: '0.0.0',
      updateUrl: '',
      changelogEn: 'No new changes.',
      changelogFa: 'تغییرات جدیدی وجود ندارد.',
      updateMode: 'url',
      updatePackage: '',
      updateLink: '',
    );
  }

  @override
  List<Object?> get props => [
        latestVersion,
        updateUrl,
        changelogEn,
        changelogFa,
        updateMode,
        updatePackage,
        updateLink,
      ];
}

// --- Helper to parse color from hex string ---
Color _hexToColor(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  try {
    return Color(int.parse(buffer.toString(), radix: 16));
  } catch (e) {
    // print_error("Invalid color string: $hexString. Using default black.");
    return Colors.black;
  }
}
// endregion

// region 1. Providers (Riverpod State Management)

// --- AppConfig Provider ---
final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  final dio = Dio();
  Map<String, dynamic> localConfigJson;
  // Load local config
  try {
    final localConfigString = await rootBundle.loadString(
      'assets/config/app_config.json',
    );
    localConfigJson = jsonDecode(localConfigString) as Map<String, dynamic>;
  } catch (e) {
    return AppConfig.defaultConfig();
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
        return AppConfig.fromJson(remoteJson);
      }
    }
  } catch (_) {
    // ignore and fallback to local
  }
  // Fallback to local config
  return AppConfig.fromJson(localConfigJson);
});

// --- ThemeNotifier and Provider ---
final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((
  ref,
) {
  final appConfig =
      ref.watch(appConfigProvider).asData?.value ?? AppConfig.defaultConfig();
  return ThemeNotifier(
    appConfig.themeOptions.defaultTheme == 'dark'
        ? ThemeMode.dark
        : ThemeMode.light,
  );
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier(super.initialMode) {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode');
    if (isDarkMode != null) {
      state = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    }
  }

  Future<void> toggleTheme() async {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', state == ThemeMode.dark);
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    _saveThemePreference();
  }

  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', state == ThemeMode.dark);
  }
}

// --- LocaleNotifier and Provider ---
final localeNotifierProvider = StateNotifierProvider<LocaleNotifier, Locale>((
  ref,
) {
  final appConfig =
      ref.watch(appConfigProvider).asData?.value ?? AppConfig.defaultConfig();
  return LocaleNotifier(Locale(appConfig.defaultLocale));
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(super.initialLocale) {
    _loadLocalePreference();
  }

  Future<void> _loadLocalePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode');
    if (languageCode != null) {
      state = Locale(languageCode);
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    state = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', newLocale.languageCode);
  }
}

// --- Currency Unit Provider ---
enum CurrencyUnit { toman, usd, eur }

final currencyUnitProvider =
    StateNotifierProvider<CurrencyUnitNotifier, CurrencyUnit>((ref) {
  return CurrencyUnitNotifier();
});

class CurrencyUnitNotifier extends StateNotifier<CurrencyUnit> {
  CurrencyUnitNotifier() : super(CurrencyUnit.toman) {
    // Default to Toman
    _loadCurrencyUnitPreference();
  }

  Future<void> _loadCurrencyUnitPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final unitString = prefs.getString('currencyUnit');
    if (unitString != null) {
      state = CurrencyUnit.values.firstWhere(
        (e) => e.toString() == unitString,
        orElse: () => CurrencyUnit.toman,
      );
    }
  }

  Future<void> setCurrencyUnit(CurrencyUnit unit) async {
    state = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currencyUnit', unit.toString());
  }
}

// --- Favorites Provider ---
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>(
  (ref) {
    return FavoritesNotifier();
  },
);

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super({}) {
    _loadFavorites();
  }

  static const _favoritesKey = 'favorite_assets';

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteList = prefs.getStringList(_favoritesKey);
    if (favoriteList != null) {
      state = favoriteList.toSet();
    }
  }

  Future<void> toggleFavorite(String assetId) async {
    final newFavorites = Set<String>.from(state);
    if (newFavorites.contains(assetId)) {
      newFavorites.remove(assetId);
    } else {
      newFavorites.add(assetId);
    }
    state = newFavorites;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, newFavorites.toList());

    // Haptic feedback
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100);
    }
  }

  bool isFavorite(String assetId) => state.contains(assetId);
}

// --- API Service Provider ---
final dioProvider = Provider<Dio>((ref) => Dio());

final apiServiceProvider = Provider<ApiService>((ref) {
  final dio = ref.watch(dioProvider);
  final config = ref.watch(appConfigProvider).asData?.value;
  if (config == null) {
    // This should ideally not happen if appConfigProvider is handled correctly at app start
    throw Exception("AppConfig not available for ApiService");
  }
  return ApiService(dio, config.apiEndpoints);
});

// --- Data Providers for each asset type ---
// Base class for asset items to share common properties like ID for favorites
abstract class Asset extends Equatable {
  final String
      id; // Unique identifier for the asset (e.g., symbol or a combination)
  final String name;
  final String symbol;
  final num price;
  final num? changePercent;
  final num? changeValue; // For currencies/gold that have it

  const Asset({
    required this.id,
    required this.name,
    required this.symbol,
    required this.price,
    this.changePercent,
    this.changeValue,
  });
}

// Currency Model
class CurrencyAsset extends Asset {
  final String nameEn;
  final String unit; // e.g., "تومان"
  final String? iconEmoji; // For flag emoji

  const CurrencyAsset({
    required super.id, // Use symbol as ID
    required super.name, // Persian name
    required this.nameEn,
    required super.symbol,
    required super.price,
    super.changeValue,
    super.changePercent,
    required this.unit,
    this.iconEmoji,
  });

  factory CurrencyAsset.fromJson(Map<String, dynamic> json) {
    return CurrencyAsset(
      id: json['symbol'] as String? ?? 'UNKNOWN',
      name: json['name'] as String? ?? 'نامشخص',
      nameEn: json['name_en'] as String? ?? 'Unknown',
      symbol: json['symbol'] as String? ?? '---',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      changeValue: (json['change_value'] as num?)?.toDouble(),
      changePercent: (json['change_percent'] as num?)?.toDouble(),
      unit: json['unit'] as String? ?? 'تومان',
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        nameEn,
        symbol,
        price,
        changeValue,
        changePercent,
        unit,
        iconEmoji,
      ];
}

// Gold Model (includes precious metals from commodity)
class GoldAsset extends Asset {
  final String nameEn;
  final String unit;
  final String? customIconPath; // For specific gold icons

  const GoldAsset({
    required super.id,
    required super.name,
    required this.nameEn,
    required super.symbol,
    required super.price,
    super.changeValue,
    super.changePercent,
    required this.unit,
    this.customIconPath,
  });

  factory GoldAsset.fromJson(
    Map<String, dynamic> json, {
    bool isCommodity = false,
  }) {
    if (isCommodity) {
      return GoldAsset(
        id: json['symbol'] as String? ?? 'UNKNOWN_COMM',
        name: json['nameFa'] as String? ?? json['name'] as String? ?? 'نامشخص',
        nameEn: json['nameEn'] as String? ??
            json['symbol'] as String? ??
            'Unknown Commodity',
        symbol: json['symbol'] as String? ?? '---',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        changePercent: (json['change_percent'] as num?)?.toDouble(),
        unit: json['unit'] as String? ?? 'دلار', // Commodity unit might be USD
        customIconPath: _getGoldIconPath(json['symbol'] as String? ?? ''),
      );
    }
    return GoldAsset(
      id: json['symbol'] as String? ?? 'UNKNOWN_GOLD',
      name: json['nameFa'] as String? ?? json['name'] as String? ?? 'نامشخص',
      nameEn: json['nameEn'] as String? ??
          json['name_en'] as String? ??
          'Unknown Gold',
      symbol: json['symbol'] as String? ?? '---',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      changeValue: (json['change_value'] as num?)?.toDouble(),
      changePercent: (json['change_percent'] as num?)?.toDouble(),
      unit: json['unit'] as String? ?? 'تومان',
      customIconPath: _getGoldIconPath(json['symbol'] as String? ?? ''),
    );
  }
  @override
  List<Object?> get props => [
        id,
        name,
        nameEn,
        symbol,
        price,
        changeValue,
        changePercent,
        unit,
        customIconPath,
      ];
}

// Crypto Model
class CryptoAsset extends Asset {
  final String nameFa;
  final String priceToman; // String because API provides it as string
  final String? iconUrl;
  final num? marketCap;

  const CryptoAsset({
    required super.id, // Use name as ID for crypto as symbols might not be unique across exchanges
    required super.name, // English name
    required this.nameFa,
    required super.symbol, // This is often the ticker like BTC, ETH
    required super.price, // USD Price
    required this.priceToman,
    super.changePercent,
    this.iconUrl,
    this.marketCap,
  });

  factory CryptoAsset.fromJson(Map<String, dynamic> json) {
    String name = json['name'] as String? ?? 'Unknown';
    // API returns price as string for crypto, need to parse it
    num usdPrice = 0;
    if (json['price'] is String) {
      usdPrice = num.tryParse(json['price'] as String) ?? 0;
    } else if (json['price'] is num) {
      usdPrice = json['price'] as num;
    }

    return CryptoAsset(
      id: name.toLowerCase().replaceAll(' ', '-'), // Create a slug-like ID
      name: name,
      nameFa: json['nameFa'] as String? ?? 'نامشخص',
      symbol: json['symbol'] as String? ??
          (json['name'] as String? ?? '---')
              .substring(0, math.min(3, (json['name'] as String? ?? '').length))
              .toUpperCase(), // Fallback symbol
      price: usdPrice,
      priceToman: json['price_toman'] as String? ?? '0',
      changePercent: (json['change_percent'] as num?)?.toDouble(),
      iconUrl: json['link_icon'] as String?,
      marketCap: json['market_cap'] as num?,
    );
  }
  @override
  List<Object?> get props => [
        id,
        name,
        nameFa,
        symbol,
        price,
        priceToman,
        changePercent,
        iconUrl,
        marketCap,
      ];
}

// Stock Model
class StockAsset extends Asset {
  final String l30; // Full name
  final String isin;
  final num? pc; // Closing price
  final num? pcp; // Closing price change percentage
  final num? pl; // Last trade price
  final num? plp; // Last trade price change percentage

  const StockAsset(
    this.isin,
    this.pl, {
    required super.id, // Use ISIN as ID
    required super.name, // Use l18 (short name) as name
    required this.l30,
    required super.symbol, // Same as l18 or a derived symbol
    required super.price, // Use 'pl' (last trade price) as primary display price
    this.pc,
    this.pcp,
    this.plp,
    super.changePercent,
  });

  factory StockAsset.fromJson(Map<String, dynamic> json) {
    final isin = json['isin'] as String? ?? 'UNKNOWN_STOCK_${json['l18']}';
    final pl = (json['pl'] as num?)?.toDouble() ?? 0.0;

    return StockAsset(
      isin,
      pl,
      id: isin,
      name: json['l18'] as String? ?? 'نامشخص',
      l30: json['l30'] as String? ?? 'نام کامل نامشخص',
      symbol: json['l18'] as String? ?? '---',
      price: pl, // Last trade price
      pc: (json['pc'] as num?)?.toDouble(), // Closing price
      pcp: (json['pcp'] as num?)?.toDouble(), // Closing price change percent
      plp: (json['plp'] as num?)?.toDouble(), // Last trade price change percent
      changePercent: (json['plp'] as num?)
          ?.toDouble(), // Use last trade % change for consistency with Asset.changePercent
    );
  }
  @override
  List<Object?> get props => [
        id,
        name,
        l30,
        symbol,
        price,
        pc,
        pcp,
        plp,
        changePercent,
      ];
}

// --- Data Fetching Notifiers ---
// Generic Data Fetcher Notifier
abstract class DataFetcherNotifier<T extends Asset>
    extends StateNotifier<AsyncValue<List<T>>> {
  final ApiService _apiService;
  final String _cacheKey;
  final AppConfig _appConfig;
  final String _initialUrl;
  bool _initialized = false;
  List<T> _fullDataList = [];
  int _currentlyLoadedCount = 0;
  Timer? _updateTimer;

  DataFetcherNotifier(
    this._apiService,
    this._cacheKey,
    this._appConfig,
    this._initialUrl,
  ) : super(const AsyncValue.loading()) {
    _currentlyLoadedCount = _appConfig.initialItemsToLoad;
    // Data will load when initialize() is called.
  }

  Future<void> initialize() async {
    if (!_initialized) {
      _initialized = true;

      // Check connection before trying to fetch data
      final connectionService = ConnectionService();
      final isOnline = await connectionService.checkConnection(_initialUrl);

      if (isOnline) {
        await fetchData(_initialUrl);
        _startAutoRefresh(_initialUrl);
      } else {
        // Load cached data if available
        final cachedData = await _loadCachedData();
        if (cachedData.isNotEmpty) {
          _fullDataList = cachedData;
          state = AsyncValue.data(
            _fullDataList.take(_currentlyLoadedCount).toList(),
          );
        } else {
          // Show offline error
          state = const AsyncValue.error("Offline", StackTrace.empty);
        }
      }
    } else {
      // Already initialized, just ensure state is refreshed with current data
      if (_fullDataList.isNotEmpty) {
        state = AsyncValue.data(
          _fullDataList.take(_currentlyLoadedCount).toList(),
        );
      }
    }
  }

  Future<void> refresh() async {
    await fetchData(_initialUrl, isRefresh: true);
  }

  Future<void> fetchData(String url, {bool isRefresh = false}) async {
    if (!isRefresh) {
      state = const AsyncValue.loading();
    }

    // Check connection first
    final connectionService = ConnectionService();
    final isConnected = await connectionService.checkConnection(url);

    if (!isConnected) {
      final cachedData = await _loadCachedData();
      if (cachedData.isNotEmpty) {
        _fullDataList = cachedData;
        state = AsyncValue.data(
          _fullDataList.take(_currentlyLoadedCount).toList(),
        );
        return;
      }

      // No cached data, show offline state
      return;
    }

    try {
      final List<T> previousData = state.asData?.value ?? [];
      final fetchedData = await _fetchAndParse(url);

      // Store the complete fetched data
      _fullDataList = _applyPriority(_sortData(fetchedData));

      // Debug log - verify we're getting all items
      print(
        "DEBUG: Fetched ${_fullDataList.length} items for ${url.split('/').last}",
      );

      // Compare with previous for change indication (simplified)
      final List<T> updatedDisplayList =
          _fullDataList.take(_currentlyLoadedCount).map((newItem) {
        final oldItem = previousData.firstWhere(
          (old) => old.id == newItem.id,
          orElse: () => newItem,
        );
        return newItem; // Assuming API data already has change %
      }).toList();

      state = AsyncValue.data(updatedDisplayList);
      await _cacheData(_fullDataList); // Cache the full list
    } catch (e, s) {
      final cachedData = await _loadCachedData();
      if (cachedData.isNotEmpty) {
        _fullDataList = cachedData;
        state = AsyncValue.data(
          _fullDataList.take(_currentlyLoadedCount).toList(),
        );
      } else {
        state = AsyncValue.error(e, s);
      }
    }
  }

  List<T> _sortData(List<T> data) {
    // Default sort: could be by name or market cap if available
    // For now, API order is preserved, or implement custom sort logic here
    return data;
  }

  List<T> _applyPriority(List<T> data) {
    // Placeholder for priority sorting based on priority_assets.json
    // This needs fetching and parsing priority_assets.json
    // For now, returns data as is.
    return data;
  }

  Future<List<T>> _fetchAndParse(String url); // To be implemented by subclasses

  void loadMore() {
    if (_currentlyLoadedCount < _fullDataList.length) {
      // Store old index for animation
      final oldCount = _currentlyLoadedCount;
      _currentlyLoadedCount = math.min(
        _fullDataList.length,
        _currentlyLoadedCount + _appConfig.itemsPerLazyLoad,
      );

      // Add a slight delay before showing new items to ensure smooth animation
      Future.delayed(const Duration(milliseconds: 100), () {
        state = AsyncValue.data(
          _fullDataList.take(_currentlyLoadedCount).toList(),
        );
      });
    }
  }

  Future<void> _cacheData(List<T> data) async {
    // Simple caching using SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonDataList = data.map((item) {
        if (item is CurrencyAsset) {
          return {
            'id': item.id,
            'name': item.name,
            'symbol': item.symbol,
            'price': item.price,
          };
        } else if (item is GoldAsset) {
          return {
            'id': item.id,
            'name': item.name,
            'symbol': item.symbol,
            'price': item.price,
          };
        } else if (item is CryptoAsset) {
          return {
            'id': item.id,
            'name': item.name,
            'symbol': item.symbol,
            'price': item.price,
          };
        } else if (item is StockAsset) {
          return {
            'id': item.id,
            'name': item.name,
            'symbol': item.symbol,
            'price': item.price,
          };
        }
        return {};
      }).toList();

      await prefs.setString('cache_$_cacheKey', jsonEncode(jsonDataList));
    } catch (e) {
      // Ignore cache errors
    }
  }

  Future<List<T>> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('cache_$_cacheKey');

      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonDataList = jsonDecode(jsonString);
        // Here we'd need type-specific deserialization based on T
        // This is a simplified version
        return jsonDataList.map((item) {
          if (T == CurrencyAsset) {
            return CurrencyAsset(
              id: item['id'],
              name: item['name'],
              nameEn: item['name'],
              symbol: item['symbol'],
              price: item['price'].toDouble(),
              unit: 'تومان',
            ) as T;
          } else if (T == GoldAsset) {
            return GoldAsset(
              id: item['id'],
              name: item['name'],
              nameEn: item['name'],
              symbol: item['symbol'],
              price: item['price'].toDouble(),
              unit: 'تومان',
            ) as T;
          } else if (T == CryptoAsset) {
            return CryptoAsset(
              id: item['id'],
              name: item['name'],
              nameFa: item['name'],
              symbol: item['symbol'],
              price: item['price'].toDouble(),
              priceToman: item['price'].toString(),
            ) as T;
          } else if (T == StockAsset) {
            return StockAsset(
              item['id'],
              item['price'].toDouble(),
              id: item['id'],
              name: item['name'],
              l30: item['name'],
              symbol: item['symbol'],
              price: item['price'].toDouble(),
            ) as T;
          }
          throw Exception('Unsupported type');
        }).toList();
      }
    } catch (e) {
      // Ignore cache errors
    }
    return [];
  }

  void _startAutoRefresh(String url) {
    _updateTimer?.cancel();
    // Use priceUpdateIntervalMinutes instead of updateIntervalMs which is inconsistently defined
    final updateIntervalMs = _appConfig.priceUpdateIntervalMinutes * 60 * 1000;
    print(
      "DEBUG: Setting auto-refresh interval to ${_appConfig.priceUpdateIntervalMinutes} minutes",
    );
    _updateTimer = Timer.periodic(Duration(milliseconds: updateIntervalMs), (
      timer,
    ) {
      fetchData(url, isRefresh: true);
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
}

// Specific Notifiers
class CurrencyNotifier extends DataFetcherNotifier<CurrencyAsset> {
  CurrencyNotifier(ApiService apiService, AppConfig appConfig)
      : super(
          apiService,
          'currency_cache',
          appConfig,
          appConfig.apiEndpoints.currencyUrl,
        );

  @override
  Future<List<CurrencyAsset>> _fetchAndParse(String url) async {
    final responseData = await _apiService.fetchData(url);
    List<CurrencyAsset> assets = [];
    if (responseData is Map && responseData.containsKey('currency')) {
      assets = (responseData['currency'] as List)
          .map(
            (item) => CurrencyAsset.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }
    // Load priority list for currency
    List<String> priorityList = [];
    try {
      final dyn = await _apiService.fetchData(
        _appConfig.apiEndpoints.priorityAssetsUrl,
      );
      if (dyn is Map<String, dynamic>) {
        priorityList = List<String>.from(
          dyn['currency'] as List<dynamic>? ?? [],
        );
      }
    } catch (_) {}
    // Apply priority: items in priorityList first, then others
    final priorityAssets = <CurrencyAsset>[];
    final otherAssets = <CurrencyAsset>[];
    for (final symbol in priorityList) {
      priorityAssets.addAll(assets.where((a) => a.symbol == symbol));
    }
    for (final asset in assets) {
      if (!priorityAssets.contains(asset)) {
        otherAssets.add(asset);
      }
    }
    return [...priorityAssets, ...otherAssets];
  }
}

final currencyProvider =
    StateNotifierProvider<CurrencyNotifier, AsyncValue<List<CurrencyAsset>>>((
  ref,
) {
  final apiService = ref.watch(apiServiceProvider);
  final appConfig = ref.watch(appConfigProvider).asData!.value;
  return CurrencyNotifier(apiService, appConfig);
});

class GoldNotifier extends DataFetcherNotifier<GoldAsset> {
  GoldNotifier(ApiService apiService, AppConfig appConfig)
      : super(
          apiService,
          'gold_cache',
          appConfig,
          appConfig.apiEndpoints.goldUrl,
        );

  @override
  Future<List<GoldAsset>> _fetchAndParse(String url) async {
    // Fetch local gold prices
    final List<GoldAsset> goldAssets = [];
    final goldResponseData = await _apiService.fetchData(url);
    if (goldResponseData is Map && goldResponseData.containsKey('gold')) {
      goldAssets.addAll(
        (goldResponseData['gold'] as List)
            .map((item) => GoldAsset.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    }
    // Fetch commodity data: precious metals, base metals, and energy
    final List<GoldAsset> commodityAssets = [];
    final commodityUrl = _appConfig.apiEndpoints.commodityUrl;
    if (commodityUrl.isNotEmpty) {
      final commodityResponseData = await _apiService.fetchData(commodityUrl);
      if (commodityResponseData is Map) {
        final preciousList =
            commodityResponseData['metal_precious'] as List<dynamic>? ?? [];
        final baseList =
            commodityResponseData['metal_base'] as List<dynamic>? ?? [];
        final energyList =
            commodityResponseData['energy'] as List<dynamic>? ?? [];
        commodityAssets.addAll(
          preciousList
              .map(
                (item) => GoldAsset.fromJson(
                  item as Map<String, dynamic>,
                  isCommodity: true,
                ),
              )
              .toList(),
        );
        commodityAssets.addAll(
          baseList
              .map(
                (item) => GoldAsset.fromJson(
                  item as Map<String, dynamic>,
                  isCommodity: true,
                ),
              )
              .toList(),
        );
        commodityAssets.addAll(
          energyList
              .map(
                (item) => GoldAsset.fromJson(
                  item as Map<String, dynamic>,
                  isCommodity: true,
                ),
              )
              .toList(),
        );
      }
    }
    // Combine gold and commodity assets, avoiding duplicates by symbol
    final List<GoldAsset> combinedAssets = [];
    final Set<String> seen = {};
    for (final asset in goldAssets) {
      if (seen.add(asset.id)) {
        combinedAssets.add(asset);
      }
    }
    for (final asset in commodityAssets) {
      if (seen.add(asset.id)) {
        combinedAssets.add(asset);
      }
    }
    // Load priority lists for gold and commodity
    List<String> goldPriorityList = [];
    List<String> commodityPriorityList = [];
    try {
      final dyn = await _apiService.fetchData(
        _appConfig.apiEndpoints.priorityAssetsUrl,
      );
      if (dyn is Map<String, dynamic>) {
        goldPriorityList = List<String>.from(
          dyn['gold'] as List<dynamic>? ?? [],
        );
        commodityPriorityList = List<String>.from(
          dyn['commodity'] as List<dynamic>? ?? [],
        );
      }
    } catch (_) {}
    // Apply priority: gold first, then commodity, then others
    final goldPriorityAssets = <GoldAsset>[];
    final remainingAssets = <GoldAsset>[];
    for (final symbol in goldPriorityList) {
      goldPriorityAssets.addAll(
        combinedAssets.where((a) => a.symbol == symbol),
      );
    }
    for (final asset in combinedAssets) {
      if (!goldPriorityAssets.contains(asset)) {
        remainingAssets.add(asset);
      }
    }
    final commodityPriorityAssets = <GoldAsset>[];
    final otherAssets = <GoldAsset>[];
    for (final symbol in commodityPriorityList) {
      commodityPriorityAssets.addAll(
        remainingAssets.where(
          (a) => a.symbol.toLowerCase() == symbol.toLowerCase(),
        ),
      );
    }
    for (final asset in remainingAssets) {
      if (!commodityPriorityAssets.contains(asset)) {
        otherAssets.add(asset);
      }
    }
    return [...goldPriorityAssets, ...commodityPriorityAssets, ...otherAssets];
  }
}

final goldProvider =
    StateNotifierProvider<GoldNotifier, AsyncValue<List<GoldAsset>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final appConfig = ref.watch(appConfigProvider).asData!.value;
  return GoldNotifier(apiService, appConfig);
});

class CryptoNotifier extends DataFetcherNotifier<CryptoAsset> {
  CryptoNotifier(ApiService apiService, AppConfig appConfig)
      : super(
          apiService,
          'crypto_cache',
          appConfig,
          appConfig.apiEndpoints.cryptoUrl,
        );

  @override
  Future<List<CryptoAsset>> _fetchAndParse(String url) async {
    final responseData = await _apiService.fetchData(url);
    if (responseData is List) {
      // Parse all crypto assets
      final assets = responseData
          .map((item) => CryptoAsset.fromJson(item as Map<String, dynamic>))
          .toList();
      // Load priority list for crypto
      List<String> priorityList = [];
      try {
        final dyn = await _apiService.fetchData(
          _appConfig.apiEndpoints.priorityAssetsUrl,
        );
        if (dyn is Map<String, dynamic>) {
          priorityList = List<String>.from(
            dyn['crypto'] as List<dynamic>? ?? <dynamic>[],
          );
        }
      } catch (_) {}
      // Partition assets into iconed (custom icons) and non-iconed
      final iconed = <CryptoAsset>[];
      final nonIconed = <CryptoAsset>[];
      for (final asset in assets) {
        if (_cryptoIconMap.containsKey(asset.name.toLowerCase())) {
          iconed.add(asset);
        } else {
          nonIconed.add(asset);
        }
      }
      // Within iconed, order by priorityList, then others
      final iconedPriority = <CryptoAsset>[];
      final iconedOthers = <CryptoAsset>[];
      for (final name in priorityList) {
        final matches = iconed.where((a) => a.name == name);
        iconedPriority.addAll(matches);
      }
      for (final a in iconed) {
        if (!iconedPriority.contains(a)) iconedOthers.add(a);
      }
      // Within non-iconed, order priorityList, then others
      final nonIconedPriority = <CryptoAsset>[];
      final nonIconedOthers = <CryptoAsset>[];
      for (final name in priorityList) {
        final matches = nonIconed.where((a) => a.name == name);
        nonIconedPriority.addAll(matches);
      }
      for (final a in nonIconed) {
        if (!nonIconedPriority.contains(a)) nonIconedOthers.add(a);
      }
      // Combine lists: iconed priority, iconed others, non-iconed priority, non-iconed others
      return <CryptoAsset>[
        ...iconedPriority,
        ...iconedOthers,
        ...nonIconedPriority,
        ...nonIconedOthers,
      ];
    }
    return <CryptoAsset>[];
  }
}

final cryptoProvider =
    StateNotifierProvider<CryptoNotifier, AsyncValue<List<CryptoAsset>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final appConfig = ref.watch(appConfigProvider).asData!.value;
  return CryptoNotifier(apiService, appConfig);
});

// Stock Notifiers (one for each sub-category)
class StockTseIfbNotifier extends DataFetcherNotifier<StockAsset> {
  StockTseIfbNotifier(ApiService apiService, AppConfig appConfig)
      : super(
          apiService,
          'stock_tse_ifb_cache',
          appConfig,
          appConfig.apiEndpoints.stockTseIfbSymbolsUrl,
        );
  @override
  Future<List<StockAsset>> _fetchAndParse(String url) async {
    final responseData = await _apiService.fetchData(url);
    if (responseData is List) {
      final assets = responseData
          .map((item) => StockAsset.fromJson(item as Map<String, dynamic>))
          .toList();
      // Load priority list for TSE/IFB symbols
      List<String> priorityList = [];
      try {
        final dyn = await _apiService.fetchData(
          _appConfig.apiEndpoints.priorityAssetsUrl,
        );
        if (dyn is Map<String, dynamic>) {
          priorityList = List<String>.from(
            dyn['stock_tse_ifb_symbols'] as List<dynamic>? ?? [],
          );
        }
      } catch (_) {}
      // Apply priority: items in priorityList first, then others
      final priorityAssets = <StockAsset>[];
      final otherAssets = <StockAsset>[];
      for (final symbol in priorityList) {
        priorityAssets.addAll(assets.where((a) => a.symbol == symbol));
      }
      for (final asset in assets) {
        if (!priorityAssets.contains(asset)) {
          otherAssets.add(asset);
        }
      }
      return [...priorityAssets, ...otherAssets];
    }
    return [];
  }
}

final stockTseIfbProvider =
    StateNotifierProvider<StockTseIfbNotifier, AsyncValue<List<StockAsset>>>((
  ref,
) {
  final apiService = ref.watch(apiServiceProvider);
  final appConfig = ref.watch(appConfigProvider).asData!.value;
  return StockTseIfbNotifier(apiService, appConfig);
});

class StockDebtSecuritiesNotifier extends DataFetcherNotifier<StockAsset> {
  StockDebtSecuritiesNotifier(ApiService apiService, AppConfig appConfig)
      : super(
          apiService,
          'stock_debt_cache',
          appConfig,
          appConfig.apiEndpoints.stockDebtSecuritiesUrl,
        );
  @override
  Future<List<StockAsset>> _fetchAndParse(String url) async {
    final responseData = await _apiService.fetchData(url);
    if (responseData is List) {
      final assets = responseData
          .map((item) => StockAsset.fromJson(item as Map<String, dynamic>))
          .toList();
      // Load priority list for debt securities
      List<String> priorityList = [];
      try {
        final dyn = await _apiService.fetchData(
          _appConfig.apiEndpoints.priorityAssetsUrl,
        );
        if (dyn is Map<String, dynamic>) {
          priorityList = List<String>.from(
            dyn['stock_debt_securities'] as List<dynamic>? ?? [],
          );
        }
      } catch (_) {}
      // Apply priority: items in priorityList first, then others
      final priorityAssets = <StockAsset>[];
      final otherAssets = <StockAsset>[];
      for (final symbol in priorityList) {
        priorityAssets.addAll(assets.where((a) => a.symbol == symbol));
      }
      for (final asset in assets) {
        if (!priorityAssets.contains(asset)) {
          otherAssets.add(asset);
        }
      }
      return [...priorityAssets, ...otherAssets];
    }
    return [];
  }
}

final stockDebtSecuritiesProvider = StateNotifierProvider<
    StockDebtSecuritiesNotifier, AsyncValue<List<StockAsset>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final appConfig = ref.watch(appConfigProvider).asData!.value;
  return StockDebtSecuritiesNotifier(apiService, appConfig);
});

class StockFuturesNotifier extends DataFetcherNotifier<StockAsset> {
  StockFuturesNotifier(ApiService apiService, AppConfig appConfig)
      : super(
          apiService,
          'stock_futures_cache',
          appConfig,
          appConfig.apiEndpoints.stockFuturesUrl,
        );
  @override
  Future<List<StockAsset>> _fetchAndParse(String url) async {
    final responseData = await _apiService.fetchData(url);
    if (responseData is List) {
      final assets = responseData
          .map((item) => StockAsset.fromJson(item as Map<String, dynamic>))
          .toList();
      // Load priority list for futures
      List<String> priorityList = [];
      try {
        final dyn = await _apiService.fetchData(
          _appConfig.apiEndpoints.priorityAssetsUrl,
        );
        if (dyn is Map<String, dynamic>) {
          priorityList = List<String>.from(
            dyn['stock_futures'] as List<dynamic>? ?? [],
          );
        }
      } catch (_) {}
      // Apply priority: items in priorityList first, then others
      final priorityAssets = <StockAsset>[];
      final otherAssets = <StockAsset>[];
      for (final symbol in priorityList) {
        priorityAssets.addAll(assets.where((a) => a.symbol == symbol));
      }
      for (final asset in assets) {
        if (!priorityAssets.contains(asset)) {
          otherAssets.add(asset);
        }
      }
      return [...priorityAssets, ...otherAssets];
    }
    return [];
  }
}

final stockFuturesProvider =
    StateNotifierProvider<StockFuturesNotifier, AsyncValue<List<StockAsset>>>((
  ref,
) {
  final apiService = ref.watch(apiServiceProvider);
  final appConfig = ref.watch(appConfigProvider).asData!.value;
  return StockFuturesNotifier(apiService, appConfig);
});

class StockHousingFacilitiesNotifier extends DataFetcherNotifier<StockAsset> {
  StockHousingFacilitiesNotifier(ApiService apiService, AppConfig appConfig)
      : super(
          apiService,
          'stock_housing_cache',
          appConfig,
          appConfig.apiEndpoints.stockHousingFacilitiesUrl,
        );
  @override
  Future<List<StockAsset>> _fetchAndParse(String url) async {
    final responseData = await _apiService.fetchData(url);
    if (responseData is List) {
      final assets = responseData
          .map((item) => StockAsset.fromJson(item as Map<String, dynamic>))
          .toList();
      // Load priority list for housing facilities
      List<String> priorityList = [];
      try {
        final dyn = await _apiService.fetchData(
          _appConfig.apiEndpoints.priorityAssetsUrl,
        );
        if (dyn is Map<String, dynamic>) {
          priorityList = List<String>.from(
            dyn['stock_housing_facilities'] as List<dynamic>? ?? [],
          );
        }
      } catch (_) {}
      // Apply priority: items in priorityList first, then others
      final priorityAssets = <StockAsset>[];
      final otherAssets = <StockAsset>[];
      for (final symbol in priorityList) {
        priorityAssets.addAll(assets.where((a) => a.symbol == symbol));
      }
      for (final asset in assets) {
        if (!priorityAssets.contains(asset)) {
          otherAssets.add(asset);
        }
      }
      return [...priorityAssets, ...otherAssets];
    }
    return [];
  }
}

final stockHousingFacilitiesProvider = StateNotifierProvider<
    StockHousingFacilitiesNotifier, AsyncValue<List<StockAsset>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final appConfig = ref.watch(appConfigProvider).asData!.value;
  return StockHousingFacilitiesNotifier(apiService, appConfig);
});

// Search Query Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// --- Card Corner Settings Provider ---
class CardCornerSettings {
  final double radius;
  final double smoothness;

  CardCornerSettings({required this.radius, required this.smoothness});

  CardCornerSettings copyWith({double? radius, double? smoothness}) {
    return CardCornerSettings(
      radius: radius ?? this.radius,
      smoothness: smoothness ?? this.smoothness,
    );
  }
}

final cardCornerSettingsProvider =
    StateNotifierProvider<CardCornerSettingsNotifier, CardCornerSettings>(
        (ref) {
  final appConfig =
      ref.watch(appConfigProvider).asData?.value ?? AppConfig.defaultConfig();
  return CardCornerSettingsNotifier(
    CardCornerSettings(
      radius: appConfig.themeOptions.light.cardBorderRadius,
      smoothness: appConfig.themeOptions.light.cardCornerSmoothness,
    ),
  );
});

class CardCornerSettingsNotifier extends StateNotifier<CardCornerSettings> {
  CardCornerSettingsNotifier(super.initial) {
    _loadSettings();
  }

  static const _radiusKey = 'card_corner_radius';
  static const _smoothnessKey = 'card_corner_smoothness';

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final radius = prefs.getDouble(_radiusKey);
      final smoothness = prefs.getDouble(_smoothnessKey);

      if (radius != null && smoothness != null) {
        state = CardCornerSettings(radius: radius, smoothness: smoothness);
      }
    } catch (e) {
      // Fallback to default if loading fails
    }
  }

  Future<void> updateRadius(double radius) async {
    state = state.copyWith(radius: radius);
    _saveSettings();
  }

  Future<void> updateSmoothness(double smoothness) async {
    state = state.copyWith(smoothness: smoothness);
    _saveSettings();
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_radiusKey, state.radius);
      await prefs.setDouble(_smoothnessKey, state.smoothness);
    } catch (e) {
      // Handle error
    }
  }
}
// endregion

// region 2. API Service
class ApiService {
  final Dio _dio;
  final ApiEndpoints
      _apiEndpoints; // Not used directly here, but good for context

  ApiService(this._dio, this._apiEndpoints);

  Future<dynamic> fetchData(String url) async {
    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        // Check if response.data is already a Map/List or a String needing decode
        if (response.data is String) {
          return jsonDecode(response.data as String);
        }
        return response
            .data; // Assuming it's already parsed by Dio (e.g. if responseType is JSON)
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'API request failed with status code ${response.statusCode}',
        );
      }
    } on DioException {
      // Handle Dio specific errors (network, timeout, etc.)
      // print_error('DioException in ApiService for $url: ${e.message}');
      // You might want to log this error to a service
      // For self-healing: if (e.type == DioExceptionType.connectionTimeout) { searchOnline("Dio connection timeout fix"); }
      rethrow; // Rethrow to be caught by the DataFetcherNotifier
    } catch (e) {
      // Handle other errors
      // print_error('Generic error in ApiService for $url: $e');
      rethrow;
    }
  }
}
// endregion

// region 3. Main Application & Entry Point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Load saved theme preference before app start
  final prefs = await SharedPreferences.getInstance();
  final isDarkModePref = prefs.getBool('isDarkMode');
  final initialThemeMode = isDarkModePref == null
      ? null
      : (isDarkModePref ? ThemeMode.dark : ThemeMode.light);
  // Initialize ConnectionService singleton
  final connectionService = ConnectionService();

  runApp(
    ProviderScope(
      overrides: [
        if (initialThemeMode != null)
          themeNotifierProvider.overrideWithProvider(
            StateNotifierProvider<ThemeNotifier, ThemeMode>(
              (ref) => ThemeNotifier(initialThemeMode),
            ),
          ),
      ],
      child: ScrollConfiguration(
        behavior: SmoothScrollBehavior(),
        child: const RiyalesApp(),
      ),
    ),
  );
}

class RiyalesApp extends ConsumerStatefulWidget {
  const RiyalesApp({super.key});

  @override
  ConsumerState<RiyalesApp> createState() => _RiyalesAppState();
}

class _RiyalesAppState extends ConsumerState<RiyalesApp> {
  @override
  void initState() {
    super.initState();

    // Initialize connection service after app loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appConfig = ref.read(appConfigProvider).asData?.value;
      if (appConfig != null) {
        final apiUrl = appConfig.apiEndpoints.currencyUrl;
        ConnectionService().initialize(apiUrl);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appConfigAsync = ref.watch(appConfigProvider);
    final themeMode = ref.watch(themeNotifierProvider);
    final currentLocale = ref.watch(localeNotifierProvider);

    // Apply hoverColor: Colors.transparent to all hover effects globally
    final materialTheme = Theme.of(context);
    final themeData = materialTheme.copyWith(
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );

    return Theme(
      data: themeData,
      child: appConfigAsync.when(
        data: (config) {
          final lightThemeConfig = config.themeOptions.light;
          final darkThemeConfig = config.themeOptions.dark;

          // Define text theme using local fonts
          TextTheme createTextTheme(String fontFamily, Color textColor) {
            return TextTheme(
              displayLarge: TextStyle(
                fontFamily: fontFamily,
                color: textColor,
                fontSize: 57,
                fontWeight: FontWeight.w400,
              ),
              displayMedium: TextStyle(
                fontFamily: fontFamily,
                color: textColor,
                fontSize: 45,
                fontWeight: FontWeight.w400,
              ),
              displaySmall: TextStyle(
                fontFamily: fontFamily,
                color: textColor,
                fontSize: 36,
                fontWeight: FontWeight.w400,
              ),
              headlineLarge: TextStyle(
                fontFamily: fontFamily,
                color: textColor,
                fontSize: 32,
                fontWeight: FontWeight.w400,
              ),
              headlineMedium: TextStyle(
                fontFamily: fontFamily,
                color: textColor,
                fontSize: 28,
                fontWeight: FontWeight.w400,
              ),
              headlineSmall: TextStyle(
                fontFamily: fontFamily,
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
              titleLarge: TextStyle(
                fontFamily: fontFamily,
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
              titleMedium: TextStyle(
                fontFamily: fontFamily,
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              titleSmall: TextStyle(
                fontFamily: fontFamily,
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              bodyLarge: TextStyle(
                fontFamily: fontFamily,
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              bodyMedium: TextStyle(
                fontFamily: fontFamily,
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              bodySmall: TextStyle(
                fontFamily: fontFamily,
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              labelLarge: TextStyle(
                fontFamily: fontFamily,
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              labelMedium: TextStyle(
                fontFamily: fontFamily,
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              labelSmall: TextStyle(
                fontFamily: fontFamily,
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            );
          }

          final lightTextTheme = createTextTheme(
            currentLocale.languageCode == 'fa'
                ? config.fonts.persianFontFamily
                : config.fonts.englishFontFamily,
            _hexToColor(lightThemeConfig.textColor),
          );
          final darkTextTheme = createTextTheme(
            currentLocale.languageCode == 'fa'
                ? config.fonts.persianFontFamily
                : config.fonts.englishFontFamily,
            _hexToColor(darkThemeConfig.textColor),
          );

          // Make dark theme slightly darker for a more modern look
          final darkBackgroundColor = _hexToColor(
            darkThemeConfig.backgroundColor,
          ).darken(10);
          final darkCardColor = _hexToColor(
            darkThemeConfig.cardColor,
          ).darken(5);
          final darkScaffoldBackgroundColor = _hexToColor(
            darkThemeConfig.scaffoldBackgroundColor,
          ).darken(10);

          final lightTheme = ThemeData(
            brightness: Brightness.light,
            primaryColor: _hexToColor(lightThemeConfig.primaryColor),
            scaffoldBackgroundColor: _hexToColor(
              lightThemeConfig.scaffoldBackgroundColor,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: _hexToColor(
                lightThemeConfig.scaffoldBackgroundColor,
              ), // Use scaffold background for uniformity
              elevation: 0, // Flat design
              iconTheme: IconThemeData(
                color: _hexToColor(lightThemeConfig.textColor),
              ),
              titleTextStyle: TextStyle(
                fontFamily:
                    currentLocale.languageCode == 'fa' ? 'Vazirmatn' : 'Onest',
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: _hexToColor(lightThemeConfig.textColor),
              ),
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: _hexToColor(
                  lightThemeConfig.scaffoldBackgroundColor,
                ),
                statusBarIconBrightness: Brightness.dark,
                systemNavigationBarColor: _hexToColor(
                  lightThemeConfig.scaffoldBackgroundColor,
                ),
                systemNavigationBarIconBrightness: Brightness.dark,
              ),
            ),
            cardTheme: CardTheme(
              elevation: 0, // Flat design
              color: _hexToColor(lightThemeConfig.cardColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  lightThemeConfig.cardBorderRadius,
                ),
              ),
            ),
            textTheme: lightTextTheme,
            colorScheme: ColorScheme.light(
              primary: _hexToColor(lightThemeConfig.primaryColor),
              secondary: _hexToColor(lightThemeConfig.accentColorGreen),
              surface: _hexToColor(lightThemeConfig.cardColor),
              onPrimary: _hexToColor(lightThemeConfig.textColor),
              onSecondary: Colors.white,
              onSurface: _hexToColor(lightThemeConfig.textColor),
              error: _hexToColor(lightThemeConfig.accentColorRed),
              onError: Colors.white,
            ),
            iconTheme: IconThemeData(
              color: _hexToColor(lightThemeConfig.secondaryTextColor),
            ),
            dividerColor: Colors.transparent, // No separator lines
            dropdownMenuTheme: DropdownMenuThemeData(
              menuStyle: MenuStyle(
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          );

          final darkTheme = ThemeData(
            brightness: Brightness.dark,
            primaryColor: _hexToColor(darkThemeConfig.primaryColor),
            scaffoldBackgroundColor: darkScaffoldBackgroundColor,
            appBarTheme: AppBarTheme(
              backgroundColor: darkScaffoldBackgroundColor,
              elevation: 0,
              iconTheme: IconThemeData(
                color: _hexToColor(darkThemeConfig.textColor),
              ),
              titleTextStyle: TextStyle(
                fontFamily:
                    currentLocale.languageCode == 'fa' ? 'Vazirmatn' : 'Onest',
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: _hexToColor(darkThemeConfig.textColor),
              ),
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: darkScaffoldBackgroundColor,
                statusBarIconBrightness: Brightness.light,
                systemNavigationBarColor: darkScaffoldBackgroundColor,
                systemNavigationBarIconBrightness: Brightness.light,
              ),
            ),
            cardTheme: CardTheme(
              elevation: 0,
              color: darkCardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  darkThemeConfig.cardBorderRadius,
                ),
              ),
            ),
            textTheme: darkTextTheme,
            colorScheme: ColorScheme.dark(
              primary: _hexToColor(darkThemeConfig.primaryColor),
              secondary: _hexToColor(darkThemeConfig.accentColorGreen),
              surface: darkCardColor,
              onPrimary: _hexToColor(darkThemeConfig.textColor),
              onSecondary: _hexToColor(darkThemeConfig.textColor),
              onSurface: _hexToColor(darkThemeConfig.textColor),
              error: _hexToColor(darkThemeConfig.accentColorRed),
              onError: _hexToColor(darkThemeConfig.textColor), // Check contrast
            ),
            iconTheme: IconThemeData(
              color: _hexToColor(darkThemeConfig.secondaryTextColor),
            ),
            dividerColor: Colors.transparent,
            dropdownMenuTheme: DropdownMenuThemeData(
              menuStyle: MenuStyle(
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          );

          return MaterialApp(
            title: config.appName, // Reverted to use config.appName
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeMode,
            // Smooth theme switching with fade and curve
            builder: (context, child) {
              return AnimatedTheme(
                data: Theme.of(context),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutQuart,
                child: child!,
              );
            },
            locale: currentLocale,
            supportedLocales: config.supportedLocales.map((loc) => Locale(loc)),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            debugShowCheckedModeBanner: false,
            home: SplashScreen(config: config.splashScreen),
          );
        },
        loading: () => const MaterialApp(
          home: Scaffold(body: Center(child: CupertinoActivityIndicator())),
        ),
        error: (error, stackTrace) => MaterialApp(
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Failed to load app configuration: $error\nPlease restart the app or check your internet connection.',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// endregion

// region 4. Splash Screen
class SplashScreen extends StatefulWidget {
  final SplashScreenConfig config;
  const SplashScreen({super.key, required this.config});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
      Duration(milliseconds: (widget.config.durationSeconds * 1000).toInt()),
      () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    // Select SVG image based on theme
    final imagePath = isDarkMode
        ? 'assets/images/splash-screen-dark.svg'
        : 'assets/images/splash-screen-light.svg';

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF121212) // Dark theme background
          : Colors.white, // Light theme background
      body: SafeArea(
        child: Column(
          children: [
            // Top 1/3 empty space
            SizedBox(height: screenHeight * 0.15),

            // App icon in upper 1/3
            Center(
              child: SvgPicture.asset(
                imagePath,
                width: 80,
                height: 80,
              ),
            ),

            // Push loading indicator to bottom 1/3
            const Spacer(),

            // iOS-style loading indicator at bottom
            Padding(
              padding: EdgeInsets.only(bottom: screenHeight * 0.15),
              child: CupertinoActivityIndicator(
                radius: 12,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// endregion

// region 5. Home Screen & Main Tabs
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin<HomeScreen> {
  late TabController _tabController;
  final List<Tab> _mainTabs = [];
  final List<Widget> _mainTabViews = [];
  ConnectionStatus _connectionStatus = ConnectionStatus.connected;
  late StreamSubscription<ConnectionStatus> _connectionSubscription;
  bool _showSearchBar = false;
  bool _isSearchActive =
      false; // Track if search is active, separate from visibility
  bool _tabListenerAdded = false;
  // Map to store scroll controllers for each tab
  final Map<int, ScrollController?> _tabScrollControllers = {};
  // Map to store scroll listeners for each tab
  final Map<int, void Function()> _tabScrollListeners = {};
  // Global keys for tab pages
  final currencyTabKey = GlobalKey<_AssetListPageState<CurrencyAsset>>();
  final goldTabKey = GlobalKey<_AssetListPageState<GoldAsset>>();
  final cryptoTabKey = GlobalKey<_AssetListPageState<CryptoAsset>>();
  final stockTabKey = GlobalKey<_StockPageState>();

  // Method to set up scroll listener for auto-hiding search bar
  void _setupScrollListener(int tabIndex) {
    // Remove any existing listener first
    if (_tabScrollListeners.containsKey(tabIndex)) {
      final controller = _tabScrollControllers[tabIndex];
      if (controller != null) {
        controller.removeListener(_tabScrollListeners[tabIndex]!);
      }
      _tabScrollListeners.remove(tabIndex);
    }

    // Create and add new listener
    final controller = _findScrollController(tabIndex);
    if (controller != null && controller.hasClients) {
      void listener() {
        // Only care about scroll events when search is active
        if (_isSearchActive) {
          if (controller.offset <= 0) {
            // At the top, show search bar if it's not already visible
            if (!_showSearchBar) {
              setState(() {
                _showSearchBar = true;
              });
            }
          } else {
            // Scrolled down, hide search bar if it's visible
            if (_showSearchBar) {
              setState(() {
                _showSearchBar = false;
              });
            }
          }
        }
      }

      controller.addListener(listener);
      _tabScrollListeners[tabIndex] = listener;
    }
  }

  void _initializeTab(int index) {
    switch (index) {
      case 0:
        ref.read(currencyProvider.notifier).initialize();
        // Capture scroll controller for currency tab
        _tabScrollControllers[0] = _findScrollController(index);
        _setupScrollListener(0);
        break;
      case 1:
        ref.read(goldProvider.notifier).initialize();
        // Capture scroll controller for gold tab
        _tabScrollControllers[1] = _findScrollController(index);
        _setupScrollListener(1);
        break;
      case 2:
        ref.read(cryptoProvider.notifier).initialize();
        // Capture scroll controller for crypto tab
        _tabScrollControllers[2] = _findScrollController(index);
        _setupScrollListener(2);
        break;
      case 3:
        // Initialize the primary stock list when Stock tab is selected
        ref.read(stockTseIfbProvider.notifier).initialize();
        // Capture scroll controller for stock tab
        _tabScrollControllers[3] = _findScrollController(index);
        _setupScrollListener(3);
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Listen for connection status changes
    _connectionSubscription = ConnectionService().statusStream.listen((status) {
      setState(() {
        _connectionStatus = status;
      });
    });
    // _setupTabs();
  }

  // Add listener to locale changes
  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset listener state and scroll controllers on locale or widget change
    _tabListenerAdded = false;
    _tabScrollControllers.clear();

    // Wait for build to complete before re-initializing tabs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_tabController.hasListeners) {
        // Re-initialize the current tab
        _initializeTab(_tabController.index);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Only refresh the active tab's data when app is resumed
      final currentTabIndex = _tabController.index;
      switch (currentTabIndex) {
        case 0:
          ref.read(currencyProvider.notifier).refresh();
          break;
        case 1:
          ref.read(goldProvider.notifier).refresh();
          break;
        case 2:
          ref.read(cryptoProvider.notifier).refresh();
          break;
        case 3:
          // For the stock tab, only refresh the active stock sub-tab
          final stockPage = _mainTabViews[3] as StockPage;
          final stockState = stockPage.key as GlobalKey<_StockPageState>;
          final state = stockState.currentState;
          if (state != null) {
            // Get active stock tab index
            final activeStockTabIndex = state._stockTabController.index;
            switch (activeStockTabIndex) {
              case 0:
                ref.read(stockTseIfbProvider.notifier).refresh();
                break;
              case 1:
                ref.read(stockDebtSecuritiesProvider.notifier).refresh();
                break;
              case 2:
                ref.read(stockFuturesProvider.notifier).refresh();
                break;
              case 3:
                ref.read(stockHousingFacilitiesProvider.notifier).refresh();
                break;
            }
          }
          break;
      }
    }
  }

  // Setup tabs based on current localization
  void _setupTabs() {
    if (!mounted) return;

    _mainTabs.clear();
    _mainTabViews.clear();

    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    _mainTabs.addAll([
      Tab(text: l10n.tabCurrency),
      Tab(text: l10n.tabGold),
      Tab(text: l10n.tabCrypto),
      Tab(text: l10n.tabStock),
    ]);

    _mainTabViews.addAll([
      AssetListPage<CurrencyAsset>(
        key: currencyTabKey,
        provider: currencyProvider,
        assetType: AssetType.currency,
      ),
      AssetListPage<GoldAsset>(
        key: goldTabKey,
        provider: goldProvider,
        assetType: AssetType.gold,
      ),
      AssetListPage<CryptoAsset>(
        key: cryptoTabKey,
        provider: cryptoProvider,
        assetType: AssetType.crypto,
      ),
      StockPage(
        key: stockTabKey,
        showSearchBar: _showSearchBar,
        isSearchActive: _isSearchActive,
      ), // Stock page has its own internal tabs
    ]);

    // Initialize tab controller with proper null check
    try {
      if (mounted) {
        // Save current tab index if possible before reinitializing
        int currentIndex = 0;
        try {
          currentIndex = _tabController.index;
          _tabController.dispose();
        } catch (e) {
          // Ignore disposal error
        }

        _tabController = TabController(
          length: _mainTabs.length,
          vsync: this,
          initialIndex: currentIndex < _mainTabs.length ? currentIndex : 0,
        );
        // Trigger data load when tab changes
        if (!_tabListenerAdded) {
          _tabListenerAdded = true;
          _initializeTab(_tabController.index);
          _tabController.addListener(() {
            if (!_tabController.indexIsChanging) {
              _initializeTab(_tabController.index);
            }
          });
        }
      }
    } catch (e) {
      // Fallback
      _tabController = TabController(length: _mainTabs.length, vsync: this);
      if (!_tabListenerAdded) {
        _tabListenerAdded = true;
        _initializeTab(_tabController.index);
        _tabController.addListener(() {
          if (!_tabController.indexIsChanging) {
            _initializeTab(_tabController.index);
          }
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setupTabs();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectionSubscription.cancel();
    // Clean up scroll listeners
    for (final entry in _tabScrollListeners.entries) {
      final controller = _tabScrollControllers[entry.key];
      if (controller != null) {
        controller.removeListener(entry.value);
      }
    }
    _tabScrollListeners.clear();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = ref.watch(appConfigProvider).asData?.value;
    final l10n = AppLocalizations.of(context)!;

    if (appConfig == null) {
      return const Scaffold(body: Center(child: CupertinoActivityIndicator()));
    }

    // Get teal green color for tab indicator
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final tealGreen = _hexToColor(
      isDarkMode
          ? appConfig.themeOptions.dark.accentColorGreen
          : appConfig.themeOptions.light.accentColorGreen,
    );

    // Styles & backgrounds for segmented control (badge style matching currency badges)
    final themeConfig =
        isDarkMode ? appConfig.themeOptions.dark : appConfig.themeOptions.light;
    // Inactive fill: match card background
    final segmentInactiveBackground = _hexToColor(themeConfig.cardColor);
    // Active fill and text: match currency badge styling
    final segmentActiveBackground = isDarkMode
        ? tealGreen.withAlpha(38)
        : Theme.of(context).colorScheme.secondaryContainer.withAlpha(128);
    final segmentActiveTextColor = isDarkMode
        ? tealGreen.withAlpha(230)
        : Theme.of(context).colorScheme.onSecondaryContainer;
    // Get screen width for responsive text sizing
    final screenWidth = MediaQuery.of(context).size.width;
    // Reduce font size on smaller screens
    final tabFontSize = screenWidth < 360 ? 12.0 : 14.0;

    final selectedTextStyle = TextStyle(
      color: segmentActiveTextColor,
      fontSize: tabFontSize,
      fontWeight: FontWeight.w600,
    );
    final unselectedTextStyle = TextStyle(
      color: Theme.of(context).textTheme.bodyLarge?.color,
      fontSize: tabFontSize,
      fontWeight: FontWeight.w600,
    );

    // Build the main scaffold
    Widget mainScaffold = Scaffold(
      appBar: AppBar(
        // Create a custom title animation that ensures sequential transition
        title: Text(l10n.riyalesAppTitle),
        actions: [
          // 3. Add animations to the action icons based on locale
          AnimatedAlign(
            alignment: Localizations.localeOf(context).languageCode == 'fa'
                ? Alignment.centerLeft
                : Alignment.center,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutQuart,
            child: IconButton(
              // Smooth transition between search and clear icons
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  _isSearchActive
                      ? CupertinoIcons.clear
                      : CupertinoIcons.search,
                  key: ValueKey<bool>(_isSearchActive),
                  color: _showSearchBar
                      ? (isDarkMode ? Colors.grey[400] : Colors.grey[600])
                      : (isDarkMode ? Colors.white : Colors.black),
                  size: 28, // match profile icon size
                ),
              ),
              onPressed: () {
                // Already showing search bar, so hide it and clear search
                if (_isSearchActive) {
                  setState(() {
                    ref.read(searchQueryProvider.notifier).state = '';
                    _showSearchBar = false;
                    _isSearchActive = false;
                  });
                  return;
                }

                // Get current tab's scroll controller
                final currentTabIndex = _tabController.index;
                _tabScrollControllers[currentTabIndex] ??=
                    _findScrollController(currentTabIndex);
                final controller = _tabScrollControllers[currentTabIndex];

                if (controller != null && controller.hasClients) {
                  // Check if already at top
                  if (controller.offset <= 0) {
                    // Already at top, just show search bar
                    setState(() {
                      _showSearchBar = true;
                      _isSearchActive = true;
                    });
                    // Set up scroll listener if not already set
                    _setupScrollListener(currentTabIndex);
                  } else {
                    // First scroll to top, then show search bar
                    // Stop any ongoing scroll/fling
                    controller.jumpTo(controller.offset);
                    // Animate to top and then show search
                    controller
                        .animateTo(
                      0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutQuart,
                    )
                        .then((_) {
                      if (mounted) {
                        setState(() {
                          _showSearchBar = true;
                          _isSearchActive = true;
                        });
                        // Set up scroll listener if not already set
                        _setupScrollListener(currentTabIndex);
                      }
                    });
                  }
                } else {
                  // No valid scroll controller, just show search bar
                  setState(() {
                    _showSearchBar = true;
                    _isSearchActive = true;
                  });
                }
              },
              splashColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              focusColor: Colors.transparent,
              style: ButtonStyle(
                overlayColor: WidgetStateProperty.all(Colors.transparent),
              ),
            ),
          ),
          // Profile/Settings Icon
          AnimatedAlign(
            alignment: Localizations.localeOf(context).languageCode == 'fa'
                ? Alignment.centerLeft
                : Alignment.center,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutQuart,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () {
                  // Close search bar when opening settings
                  setState(() {
                    if (_isSearchActive) {
                      ref.read(searchQueryProvider.notifier).state = '';
                      _showSearchBar = false;
                      _isSearchActive = false;
                    }
                  });
                  showCupertinoModalPopup(
                    context: context,
                    builder: (_) => const SettingsSheet(),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: Icon(
                    CupertinoIcons.person_crop_circle,
                    size: 28,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(
            56.0 + 2.0,
          ), // Added 12.0 for bottom padding
          child: Padding(
            padding: const EdgeInsets.only(
              left: 8.0,
              right: 8.0,
              bottom: 2.0, // Added bottom padding, kept horizontal
            ), // Added bottom padding, kept horizontal
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final horizontalMargin =
                    isMobile ? 4.0 : 0.0; // Reduced margin for desktop/tablet
                // Use existing themeConfig for main tabs defined earlier
                final tabRadius =
                    themeConfig.cardBorderRadius * 0.7; //Tab corner radius
                return Row(
                  mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isSelected = _tabController.index == index;
                    final label = [
                      l10n.tabCurrency,
                      l10n.tabGold,
                      l10n.tabCrypto,
                      l10n.tabStock,
                    ][index];
                    void onTabTap() {
                      if (_tabController.index == index) {
                        // Scroll to top if active tab tapped
                        final controller = _tabScrollControllers[index] ??=
                            _findScrollController(index);
                        if (controller != null && controller.hasClients) {
                          controller.jumpTo(controller.offset);
                          controller.animateTo(
                            0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOutQuart,
                          );
                        }
                      } else {
                        setState(() {
                          _tabController.animateTo(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOutQuart,
                          );
                        });
                      }
                    }

                    final segment = SmoothCard(
                      smoothness: themeConfig.cardCornerSmoothness,
                      borderRadius: BorderRadius.circular(tabRadius),
                      elevation: 0,
                      color: isSelected
                          ? segmentActiveBackground
                          : segmentInactiveBackground,
                      child: Padding(
                        // bump vertical padding slightly for height
                        padding: const EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 16.0,
                        ), // Increased horizontal padding
                        child: Center(
                          child: Builder(
                            builder: (context) {
                              Widget textWidget = Text(
                                label,
                                style: isSelected
                                    ? selectedTextStyle
                                    : unselectedTextStyle,
                                textAlign: TextAlign.center,
                              );
                              // Ensure text fits within the tab
                              Widget fittedText = FittedBox(
                                fit: BoxFit.scaleDown,
                                child: textWidget,
                              );

                              // Shift light-theme active text down by 1px
                              if (isSelected && !isDarkMode) {
                                fittedText = Transform.translate(
                                  offset: const Offset(0, 1),
                                  child: fittedText,
                                );
                              }
                              return fittedText;
                            },
                          ),
                        ),
                      ),
                    );
                    final wrapped = GestureDetector(
                      onTap: onTabTap,
                      onLongPress: () {
                        // Haptic feedback
                        Vibration.vibrate(duration: 90);
                        final isFa =
                            Localizations.localeOf(context).languageCode ==
                                'fa';
                        final optionDefault = isFa ? 'پیشفرض' : 'Default';
                        final optionHigh =
                            isFa ? 'بیشترین قیمت' : 'Highest Price';
                        final optionLow = isFa ? 'کمترین قیمت' : 'Lowest Price';
                        showCupertinoModalPopup(
                          context: context,
                          builder: (_) => CupertinoTheme(
                            data: CupertinoThemeData(
                              brightness: isDarkMode
                                  ? Brightness.dark
                                  : Brightness.light,
                            ),
                            child: CupertinoActionSheet(
                              title: Text(
                                isFa ? 'مرتب‌سازی' : 'Sort By',
                                style: TextStyle(
                                  fontFamily: isFa ? 'Vazirmatn' : 'SF-Pro',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              actions: [
                                CupertinoActionSheetAction(
                                  onPressed: () {
                                    if (index == 0) {
                                      currencyTabKey.currentState
                                          ?._setSortMode(SortMode.defaultOrder);
                                    } else if (index == 1) {
                                      goldTabKey.currentState
                                          ?._setSortMode(SortMode.defaultOrder);
                                    } else if (index == 2) {
                                      cryptoTabKey.currentState
                                          ?._setSortMode(SortMode.defaultOrder);
                                    }
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(
                                    optionDefault,
                                    style: TextStyle(
                                      fontFamily: isFa ? 'Vazirmatn' : 'SF-Pro',
                                      fontSize: 17,
                                      fontWeight: FontWeight.normal,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                CupertinoActionSheetAction(
                                  onPressed: () {
                                    if (index == 0) {
                                      currencyTabKey.currentState
                                          ?._setSortMode(SortMode.highestPrice);
                                    } else if (index == 1) {
                                      goldTabKey.currentState
                                          ?._setSortMode(SortMode.highestPrice);
                                    } else if (index == 2) {
                                      cryptoTabKey.currentState
                                          ?._setSortMode(SortMode.highestPrice);
                                    }
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(
                                    optionHigh,
                                    style: TextStyle(
                                      fontFamily: isFa ? 'Vazirmatn' : 'SF-Pro',
                                      fontSize: 17,
                                      fontWeight: FontWeight.normal,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                CupertinoActionSheetAction(
                                  onPressed: () {
                                    if (index == 0) {
                                      currencyTabKey.currentState
                                          ?._setSortMode(SortMode.lowestPrice);
                                    } else if (index == 1) {
                                      goldTabKey.currentState
                                          ?._setSortMode(SortMode.lowestPrice);
                                    } else if (index == 2) {
                                      cryptoTabKey.currentState
                                          ?._setSortMode(SortMode.lowestPrice);
                                    }
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(
                                    optionLow,
                                    style: TextStyle(
                                      fontFamily: isFa ? 'Vazirmatn' : 'SF-Pro',
                                      fontSize: 17,
                                      fontWeight: FontWeight.normal,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                              cancelButton: CupertinoActionSheetAction(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(
                                  isFa ? 'انصراف' : 'Cancel',
                                  style: TextStyle(
                                    fontFamily: isFa ? 'Vazirmatn' : 'SF-Pro',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: tealGreen,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      child: segment,
                    );
                    return isMobile
                        ? Expanded(child: wrapped)
                        : Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalMargin,
                            ),
                            child: wrapped,
                          );
                  }),
                );
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_tabController.index != 3)
            AnimatedContainer(
              duration: _showSearchBar
                  ? const Duration(milliseconds: 400)
                  : const Duration(milliseconds: 300),
              curve: Curves.easeInOutQuart,
              height: _showSearchBar ? 48.0 : 0.0,
              margin: _showSearchBar
                  ? const EdgeInsets.only(
                      top: 10.0,
                      bottom: 4.0,
                    ) // Increased bottom margin by 2.0
                  : EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: AnimatedOpacity(
                opacity: _showSearchBar ? 1.0 : 0.0,
                duration: _showSearchBar
                    ? const Duration(milliseconds: 300)
                    : const Duration(milliseconds: 200),
                child:
                    _isSearchActive // Use _isSearchActive to determine if search widget should exist
                        ? Builder(
                            builder: (context) {
                              final searchText = ref.watch(searchQueryProvider);
                              final isRTL = Localizations.localeOf(context)
                                          .languageCode ==
                                      'fa' ||
                                  _containsPersian(searchText);
                              final textColor = isDarkMode
                                  ? Colors.grey[300]
                                  : Colors.grey[700];
                              final placeholderColor = isDarkMode
                                  ? Colors.grey[600]
                                  : Colors.grey[500];
                              final iconColor = isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600];
                              final fontFamily = isRTL ? 'Vazirmatn' : 'SF-Pro';

                              return CupertinoTextField(
                                controller: TextEditingController(
                                  text: searchText,
                                )..selection = TextSelection.fromPosition(
                                    TextPosition(offset: searchText.length),
                                  ),
                                onChanged: (v) => ref
                                    .read(searchQueryProvider.notifier)
                                    .state = v,
                                placeholder: l10n.searchPlaceholder,
                                placeholderStyle: TextStyle(
                                  color: placeholderColor,
                                  fontFamily: fontFamily,
                                ),
                                // Use directional padding for search icon and clear button
                                prefix: Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    start: 18,
                                  ),
                                  child: Icon(
                                    CupertinoIcons.search,
                                    size: 20,
                                    color: iconColor,
                                  ),
                                ),
                                suffix: searchText.isNotEmpty
                                    ? CupertinoButton(
                                        padding:
                                            const EdgeInsetsDirectional.only(
                                          end: 18,
                                        ),
                                        minSize: 30,
                                        child: Icon(
                                          CupertinoIcons.clear,
                                          size: 18,
                                          color: iconColor,
                                        ),
                                        onPressed: () {
                                          ref
                                              .read(
                                                searchQueryProvider.notifier,
                                              )
                                              .state = '';
                                        },
                                      )
                                    : null,
                                textAlign:
                                    isRTL ? TextAlign.right : TextAlign.left,
                                padding: EdgeInsetsDirectional.only(
                                  start: 9,
                                  end: searchText.isNotEmpty ? 28 : 12,
                                  top: 8,
                                  bottom: 8,
                                ),
                                style: TextStyle(
                                  color: textColor,
                                  fontFamily: fontFamily,
                                ),
                                cursorColor: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? const Color(0xFF2C2C2E)
                                      : const Color(0xFFE2E2E6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              );
                            },
                          )
                        : const SizedBox(),
              ),
            ),
          Expanded(
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, child) {
                final index = _tabController.index;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeInOutQuart,
                  switchOutCurve: Curves.easeInOutQuart,
                  transitionBuilder: (Widget child, Animation<double> anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: Container(
                    key: ValueKey<int>(index),
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: index == 3
                        ? StockPage(
                            key: stockTabKey,
                            showSearchBar: _showSearchBar,
                            isSearchActive: _isSearchActive,
                          )
                        : _mainTabViews[index],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    // Wrap with network awareness
    return NetworkAwareWidget(
      onlineWidget: mainScaffold,
      offlineBuilder: (status) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.riyalesAppTitle),
            actions: [
              // Only show settings in offline mode
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    // Close search bar when opening settings
                    setState(() {
                      if (_isSearchActive) {
                        ref.read(searchQueryProvider.notifier).state = '';
                        _showSearchBar = false;
                        _isSearchActive = false;
                      }
                    });
                    showCupertinoModalPopup(
                      context: context,
                      builder: (_) => const SettingsSheet(),
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Icon(
                      CupertinoIcons.person_crop_circle,
                      size: 28,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Center(child: ErrorPlaceholder(status: status)),
        );
      },
    );
  }

  // Add helper method to find scroll controllers in tab content
  ScrollController? _findScrollController(int tabIndex) {
    try {
      switch (tabIndex) {
        case 0: // Currency tab
          return currencyTabKey.currentState?._scrollController;
        case 1: // Gold tab
          return goldTabKey.currentState?._scrollController;
        case 2: // Crypto tab
          return cryptoTabKey.currentState?._scrollController;
        case 3: // Stock tab (main)
          // We have to get access to the currently active StockPage tab's controller
          // First find the StockPage state
          final stockPage = _mainTabViews[3] as StockPage;
          final stockState = stockPage.key as GlobalKey<_StockPageState>;
          final state = stockState.currentState;
          if (state != null) {
            // Get currently active sub-tab index in Stock page
            final activeStockTabIndex = state._stockTabController.index;
            // Update stock scroll controllers to ensure we have latest references
            state._updateStockScrollControllers();
            // Return the scroll controller for active Stock sub-tab
            return state._stockScrollControllers[activeStockTabIndex];
          }
          return null;
        default:
          return null;
      }
    } catch (e) {
      print('Error finding scroll controller for tab $tabIndex: $e');
      return null;
    }
  }
}

// Settings Sheet (minimal bottom sheet)
class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});

  // Helper to compare semantic versions (e.g., "1.0.1" > "1.0.0")
  bool _isVersionGreaterThan(String v1, String v2) {
    List<int> v1Parts = v1.split('.').map(int.parse).toList();
    List<int> v2Parts = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < math.max(v1Parts.length, v2Parts.length); i++) {
      int p1 = (i < v1Parts.length) ? v1Parts[i] : 0;
      int p2 = (i < v2Parts.length) ? v2Parts[i] : 0;

      if (p1 > p2) return true;
      if (p1 < p2) return false;
    }
    return false; // Versions are equal
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final locale = ref.watch(localeNotifierProvider);
    final currencyUnit = ref.watch(currencyUnitProvider);
    final appConfig = ref.watch(appConfigProvider).asData?.value;
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Get teal green color for all accent elements
    final tealGreen = _hexToColor(
      isDarkMode
          ? appConfig?.themeOptions.dark.accentColorGreen ?? "#00B894"
          : appConfig?.themeOptions.light.accentColorGreen ?? "#00B894",
    );

    // Chevron color and size for all dropdowns and terms row
    final chevronColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    const chevronSize = 0.0;

    // App Version and Update Info
    String displayVersion = currentAppVersion;
    bool updateAvailable = false;
    String updateButtonText = l10n.settingsUpdateAvailable;
    String changelog = '';

    if (appConfig != null) {
      if (_isVersionGreaterThan(
        appConfig.updateInfo.latestVersion,
        currentAppVersion,
      )) {
        updateAvailable = true;
        changelog = locale.languageCode == 'fa'
            ? appConfig.updateInfo.changelogFa
            : appConfig.updateInfo.changelogEn;
      }
    }

    return CupertinoTheme(
      data: CupertinoThemeData(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
      ),
      child: CupertinoActionSheet(
        title: Text(
          l10n.settingsTitle,
          style: TextStyle(
            fontFamily: locale.languageCode == 'fa' ? 'Vazirmatn' : 'SF-Pro',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          // Theme toggle
          CupertinoActionSheetAction(
            onPressed: () {}, // Empty callback to make it non-dismissible
            isDefaultAction: false,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.settingsTheme,
                    style: TextStyle(
                      fontFamily:
                          locale.languageCode == 'fa' ? 'Vazirmatn' : 'SF-Pro',
                      fontSize: 17,
                      fontWeight: FontWeight.normal,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  CupertinoSwitch(
                    value: themeMode == ThemeMode.dark,
                    activeTrackColor: tealGreen,
                    onChanged: (v) =>
                        ref.read(themeNotifierProvider.notifier).toggleTheme(),
                  ),
                ],
              ),
            ),
          ),

          // Language selector
          if (appConfig != null)
            CupertinoActionSheetAction(
              onPressed: () {
                // Show iOS-style picker for language selection
                _showLanguagePicker(context, ref, locale, appConfig);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.settingsLanguage,
                    style: TextStyle(
                      fontFamily:
                          locale.languageCode == 'fa' ? 'Vazirmatn' : 'SF-Pro',
                      fontSize: 17,
                      fontWeight: FontWeight.normal,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        locale.languageCode == 'fa' ? 'فارسی' : 'English',
                        style: TextStyle(
                          fontFamily: locale.languageCode == 'fa'
                              ? 'Vazirmatn'
                              : 'SF-Pro',
                          fontSize: 16,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        CupertinoIcons.chevron_down,
                        size: 16,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Currency unit selector
          CupertinoActionSheetAction(
            onPressed: () {
              // Show iOS-style picker for currency unit selection
              _showCurrencyUnitPicker(context, ref, locale, currencyUnit, l10n);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.settingsCurrencyUnit,
                  style: TextStyle(
                    fontFamily:
                        locale.languageCode == 'fa' ? 'Vazirmatn' : 'SF-Pro',
                    fontSize: 17,
                    fontWeight: FontWeight.normal,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      currencyUnit == CurrencyUnit.toman
                          ? l10n.currencyUnitToman
                          : currencyUnit == CurrencyUnit.usd
                              ? l10n.currencyUnitUSD
                              : l10n.currencyUnitEUR,
                      style: TextStyle(
                        fontFamily: locale.languageCode == 'fa' ||
                                (currencyUnit == CurrencyUnit.toman &&
                                    _containsPersian(
                                      l10n.currencyUnitToman,
                                    ))
                            ? 'Vazirmatn'
                            : 'SF-Pro',
                        fontSize: 16,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      CupertinoIcons.chevron_down,
                      size: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Terms and Conditions Button
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context); // Close the settings sheet
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => const TermsAndConditionsScreen(),
                ),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.settingsTerms,
                  style: TextStyle(
                    fontFamily:
                        locale.languageCode == 'fa' ? 'Vazirmatn' : 'SF-Pro',
                    fontSize: 17,
                    fontWeight: FontWeight.normal,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                Icon(
                  locale.languageCode == 'fa'
                      ? Icons.keyboard_arrow_left
                      : Icons.keyboard_arrow_right,
                  size: chevronSize,
                  color: chevronColor,
                ),
              ],
            ),
          ),
          // Contact Us button
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              final emailUri = Uri(
                scheme: 'mailto',
                path: 'info@ryls.ir',
                queryParameters: {
                  'subject': locale.languageCode == 'fa'
                      ? 'درخواست پشتیبانی'
                      : 'Support Request',
                  'body': locale.languageCode == 'fa'
                      ? 'سلام،\n\nلطفاً به من در مورد...' // starter text in Persian
                      : 'Hello,\n\nPlease assist me with...'
                },
              );
              launchUrl(emailUri);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  locale.languageCode == 'fa' ? 'تماس با ما' : 'Contact Us',
                  style: TextStyle(
                    fontFamily:
                        locale.languageCode == 'fa' ? 'Vazirmatn' : 'SF-Pro',
                    fontSize: 17,
                    fontWeight: FontWeight.normal,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                Icon(
                  locale.languageCode == 'fa'
                      ? Icons.keyboard_arrow_left
                      : Icons.keyboard_arrow_right,
                  size: chevronSize,
                  color: chevronColor,
                ),
              ],
            ),
          ),
          // Update Button
          if (updateAvailable)
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(context);
                // Handle update action based on configuration
                final updateInfo = appConfig!.updateInfo;
                if (updateInfo.updateMode == 'package') {
                  final pkg = updateInfo.updatePackage;
                  // Deep link to app store
                  final storeUri = Uri.parse('market://details?id=$pkg');
                  if (await canLaunchUrl(storeUri)) {
                    await launchUrl(storeUri);
                  } else {
                    // Fallback web URL for Play Store
                    final webUri = Uri.parse(
                      'https://play.google.com/store/apps/details?id=$pkg',
                    );
                    await launchUrl(webUri);
                  }
                } else {
                  final link = updateInfo.updateLink;
                  final uri = Uri.tryParse(link);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    updateButtonText,
                    style: TextStyle(
                      fontFamily:
                          locale.languageCode == 'fa' ? 'Vazirmatn' : 'SF-Pro',
                      fontSize: 17,
                      fontWeight: FontWeight.normal,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  Icon(
                    locale.languageCode == 'fa'
                        ? Icons.keyboard_arrow_left
                        : Icons.keyboard_arrow_right,
                    size: chevronSize,
                    color: chevronColor,
                  ),
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(
            l10n.dialogClose,
            style: TextStyle(
              fontFamily: locale.languageCode == 'fa' ? 'Vazirmatn' : 'SF-Pro',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: tealGreen,
            ),
          ),
        ),
      ),
    );
  }
}

// Helper method to show language picker in iOS style
void _showLanguagePicker(
  BuildContext context,
  WidgetRef ref,
  Locale currentLocale,
  AppConfig appConfig,
) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final l10n = AppLocalizations.of(context)!;

  showCupertinoModalPopup(
    context: context,
    builder: (BuildContext context) {
      // Find the current language index
      int selectedIndex = appConfig.supportedLocales.indexOf(
        currentLocale.languageCode,
      );
      if (selectedIndex < 0) selectedIndex = 0;

      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Column(
          children: [
            // iOS-style picker header
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF3A3A3C)
                    : const Color(0xFFF2F2F7),
                border: Border(
                  bottom: BorderSide(
                    color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      l10n.dialogClose,
                      style: TextStyle(
                        fontFamily: currentLocale.languageCode == 'fa'
                            ? 'Vazirmatn'
                            : 'SF-Pro',
                        fontSize: 16,
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // The language picker
            Expanded(
              child: CupertinoPicker(
                backgroundColor:
                    isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
                itemExtent: 40,
                scrollController: FixedExtentScrollController(
                  initialItem: selectedIndex,
                ),
                onSelectedItemChanged: (index) {
                  final locale = Locale(appConfig.supportedLocales[index]);
                  ref.read(localeNotifierProvider.notifier).setLocale(locale);
                },
                children: appConfig.supportedLocales.map((code) {
                  return Center(
                    child: Text(
                      code == 'fa' ? 'فارسی' : 'English',
                      style: TextStyle(
                        fontFamily: code == 'fa' ? 'Vazirmatn' : 'SF-Pro',
                        fontSize: 20,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    },
  );
}

// Helper method to show currency unit picker in iOS style
void _showCurrencyUnitPicker(
  BuildContext context,
  WidgetRef ref,
  Locale currentLocale,
  CurrencyUnit currentUnit,
  AppLocalizations l10n,
) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  showCupertinoModalPopup(
    context: context,
    builder: (BuildContext context) {
      // Find the current currency unit index
      int selectedIndex = CurrencyUnit.values.indexOf(currentUnit);

      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Column(
          children: [
            // iOS-style picker header
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF3A3A3C)
                    : const Color(0xFFF2F2F7),
                border: Border(
                  bottom: BorderSide(
                    color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      currentLocale.languageCode == 'fa' ? 'بستن' : 'Close',
                      style: TextStyle(
                        fontFamily: currentLocale.languageCode == 'fa'
                            ? 'Vazirmatn'
                            : 'SF-Pro',
                        fontSize: 16,
                        color: CupertinoColors.activeBlue, // blue for close
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // The currency unit picker
            Expanded(
              child: CupertinoPicker(
                backgroundColor:
                    isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
                itemExtent: 40,
                scrollController: FixedExtentScrollController(
                  initialItem: selectedIndex,
                ),
                onSelectedItemChanged: (index) {
                  ref
                      .read(currencyUnitProvider.notifier)
                      .setCurrencyUnit(CurrencyUnit.values[index]);
                },
                children: CurrencyUnit.values.map((unit) {
                  String labelText = unit == CurrencyUnit.toman
                      ? l10n.currencyUnitToman
                      : unit == CurrencyUnit.usd
                          ? l10n.currencyUnitUSD
                          : l10n.currencyUnitEUR;

                  bool hasPersianChars = _containsPersian(labelText);
                  String fontFamily =
                      hasPersianChars || currentLocale.languageCode == 'fa'
                          ? 'Vazirmatn'
                          : 'SF-Pro';

                  return Center(
                    child: Text(
                      labelText,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 20,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    },
  );
}

// Stock Page with Sub-Tabs
class StockPage extends ConsumerStatefulWidget {
  final bool showSearchBar;
  final bool isSearchActive;
  const StockPage({
    super.key,
    required this.showSearchBar,
    required this.isSearchActive,
  });

  @override
  _StockPageState createState() => _StockPageState();
}

class _StockPageState extends ConsumerState<StockPage>
    with TickerProviderStateMixin<StockPage> {
  late TabController _stockTabController;
  final List<Tab> _stockTabs = [];
  final List<Widget> _stockTabViews = [];
  // Add keys for each stock sub-tab to access their scroll controllers
  final stockTseIfbKey = GlobalKey<_AssetListPageState<StockAsset>>();
  final stockDebtKey = GlobalKey<_AssetListPageState<StockAsset>>();
  final stockFuturesKey = GlobalKey<_AssetListPageState<StockAsset>>();
  final stockHousingKey = GlobalKey<_AssetListPageState<StockAsset>>();
  // Map to store scroll controllers for each stock sub-tab
  final Map<int, ScrollController?> _stockScrollControllers = {};

  @override
  void initState() {
    super.initState();
    // Initialized in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;

    _stockTabs.clear();
    _stockTabViews.clear();

    _stockTabs.addAll([
      Tab(text: l10n.stockTabSymbols), // TSE/IFB Symbols (نمادها) - Priority
      Tab(text: l10n.stockTabDebtSecurities), // اوراق بدهی
      Tab(text: l10n.stockTabFutures), // آتی
      Tab(text: l10n.stockTabHousingFacilities), // تسهیلات مسکن
    ]);

    _stockTabViews.addAll([
      AssetListPage<StockAsset>(
        key: stockTseIfbKey,
        provider: stockTseIfbProvider,
        assetType: AssetType.stock,
      ),
      AssetListPage<StockAsset>(
        key: stockDebtKey,
        provider: stockDebtSecuritiesProvider,
        assetType: AssetType.stock,
      ),
      AssetListPage<StockAsset>(
        key: stockFuturesKey,
        provider: stockFuturesProvider,
        assetType: AssetType.stock,
      ),
      AssetListPage<StockAsset>(
        key: stockHousingKey,
        provider: stockHousingFacilitiesProvider,
        assetType: AssetType.stock,
      ),
    ]);
    _stockTabController = TabController(length: _stockTabs.length, vsync: this);
    // Initialize scroll controllers after tabs are set up
    _updateStockScrollControllers();
  }

  // Method to update the scroll controllers map
  void _updateStockScrollControllers() {
    _stockScrollControllers[0] = stockTseIfbKey.currentState?._scrollController;
    _stockScrollControllers[1] = stockDebtKey.currentState?._scrollController;
    _stockScrollControllers[2] =
        stockFuturesKey.currentState?._scrollController;
    _stockScrollControllers[3] =
        stockHousingKey.currentState?._scrollController;
  }

  @override
  void dispose() {
    _stockTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get teal green for tab indicator
    final appConfig = ref.watch(appConfigProvider).asData?.value;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final tealGreen = _hexToColor(
      isDarkMode
          ? appConfig?.themeOptions.dark.accentColorGreen ?? "#00B894"
          : appConfig?.themeOptions.light.accentColorGreen ?? "#00B894",
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8.0,
            vertical: 0.0,
          ), // Reduced vertical padding
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              const horizontalMargin = 1.0; // Reduced horizontal spacing
              // Use fixed tab radius and smoothness from theme, not from provider
              final themeConfig = isDarkMode
                  ? appConfig!.themeOptions.dark
                  : appConfig!.themeOptions.light;
              final tabRadius =
                  themeConfig.cardBorderRadius * 0.7; //Tab corner radius
              final segmentInactiveBackground = _hexToColor(
                themeConfig.cardColor,
              );
              final segmentActiveBackground = isDarkMode
                  ? tealGreen.withAlpha(38)
                  : Theme.of(
                      context,
                    ).colorScheme.secondaryContainer.withAlpha(128);
              final segmentActiveTextColor = isDarkMode
                  ? tealGreen.withAlpha(230)
                  : Theme.of(context).colorScheme.onSecondaryContainer;
              final selectedTextStyle = TextStyle(
                color: segmentActiveTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              );
              final unselectedTextStyle = TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              );
              return Row(
                mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_stockTabs.length, (index) {
                  final isSelected = _stockTabController.index == index;
                  final label = _stockTabs[index].text!;
                  void onTap() {
                    if (_stockTabController.index == index) {
                      _updateStockScrollControllers();
                      final controller = _stockScrollControllers[index];
                      if (controller != null && controller.hasClients) {
                        controller.jumpTo(controller.offset);
                        controller.animateTo(
                          0,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutQuart,
                        );
                      }
                    } else {
                      setState(() {
                        _stockTabController.animateTo(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutQuart,
                        );
                      });
                    }
                  }

                  final segment = SmoothCard(
                    smoothness: themeConfig.cardCornerSmoothness,
                    borderRadius: BorderRadius.circular(tabRadius),
                    elevation: 0,
                    color: isSelected
                        ? segmentActiveBackground
                        : segmentInactiveBackground,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10.0,
                        horizontal: 12.0,
                      ),
                      child: Center(
                        child: Builder(
                          builder: (context) {
                            Widget textWidget = Text(
                              label,
                              style: isSelected
                                  ? selectedTextStyle
                                  : unselectedTextStyle,
                              textAlign: TextAlign.center,
                            );
                            Widget fittedText = FittedBox(
                              fit: BoxFit.scaleDown,
                              child: textWidget,
                            );
                            if (isSelected && !isDarkMode) {
                              fittedText = Transform.translate(
                                offset: const Offset(0, 1),
                                child: fittedText,
                              );
                            }
                            return fittedText;
                          },
                        ),
                      ),
                    ),
                  );
                  final wrapped = GestureDetector(onTap: onTap, child: segment);
                  return isMobile
                      ? Expanded(child: wrapped)
                      : Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalMargin,
                          ),
                          child: wrapped,
                        );
                }),
              );
            },
          ),
        ),
        // Add search bar after stock tabs
        AnimatedContainer(
          duration: widget.showSearchBar
              ? const Duration(milliseconds: 400)
              : const Duration(milliseconds: 300),
          curve: Curves.easeInOutQuart,
          height: widget.showSearchBar ? 48.0 : 0.0,
          margin: widget.showSearchBar
              ? const EdgeInsets.only(top: 10.0, bottom: 2.0)
              : EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: Theme.of(context).scaffoldBackgroundColor,
          child: AnimatedOpacity(
            opacity: widget.showSearchBar ? 1.0 : 0.0,
            duration: widget.showSearchBar
                ? const Duration(milliseconds: 300)
                : const Duration(milliseconds: 200),
            child: widget.isSearchActive
                ? Builder(
                    builder: (context) {
                      final searchText = ref.watch(searchQueryProvider);
                      final isRTL =
                          Localizations.localeOf(context).languageCode ==
                                  'fa' ||
                              _containsPersian(searchText);
                      final textColor =
                          (Theme.of(context).brightness == Brightness.dark)
                              ? Colors.grey[300]
                              : Colors.grey[700];
                      final placeholderColor =
                          (Theme.of(context).brightness == Brightness.dark)
                              ? Colors.grey[600]
                              : Colors.grey[500];
                      final iconColor =
                          (Theme.of(context).brightness == Brightness.dark)
                              ? Colors.grey[400]
                              : Colors.grey[600];
                      final fontFamily = isRTL ? 'Vazirmatn' : 'SF-Pro';

                      return CupertinoTextField(
                        controller: TextEditingController(text: searchText)
                          ..selection = TextSelection.fromPosition(
                            TextPosition(offset: searchText.length),
                          ),
                        onChanged: (v) =>
                            ref.read(searchQueryProvider.notifier).state = v,
                        placeholder:
                            AppLocalizations.of(context)!.searchPlaceholder,
                        placeholderStyle: TextStyle(
                          color: placeholderColor,
                          fontFamily: fontFamily,
                        ),
                        prefix: Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: 18,
                          ),
                          child: Icon(
                            CupertinoIcons.search,
                            size: 20,
                            color: iconColor,
                          ),
                        ),
                        suffix: searchText.isNotEmpty
                            ? CupertinoButton(
                                padding: const EdgeInsetsDirectional.only(
                                  end: 18,
                                ),
                                minSize: 30,
                                child: Icon(
                                  CupertinoIcons.clear,
                                  size: 18,
                                  color: iconColor,
                                ),
                                onPressed: () => ref
                                    .read(
                                      searchQueryProvider.notifier,
                                    )
                                    .state = '',
                              )
                            : null,
                        textAlign: isRTL ? TextAlign.right : TextAlign.left,
                        padding: EdgeInsetsDirectional.only(
                          start: 9,
                          end: searchText.isNotEmpty ? 28 : 12,
                          top: 8,
                          bottom: 8,
                        ),
                        style: TextStyle(
                          color: textColor,
                          fontFamily: fontFamily,
                        ),
                        cursorColor: iconColor,
                        decoration: BoxDecoration(
                          color:
                              (Theme.of(context).brightness == Brightness.dark)
                                  ? const Color(0xFF2C2C2E)
                                  : const Color(0xFFE2E2E6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    },
                  )
                : const SizedBox(),
          ),
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: _stockTabController,
            builder: (context, child) {
              final index = _stockTabController.index;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeInOutQuart,
                switchOutCurve: Curves.easeInOutQuart,
                transitionBuilder: (Widget child, Animation<double> anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Container(
                  key: ValueKey<int>(index),
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: _stockTabViews[index],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// endregion

// region 6. Asset List Page & Card Widget
enum AssetType { currency, gold, crypto, stock }

// Insert SortMode enum for long-press sorting
enum SortMode { defaultOrder, highestPrice, lowestPrice }

class AssetListPage<T extends Asset> extends ConsumerStatefulWidget {
  final StateNotifierProvider<DataFetcherNotifier<T>, AsyncValue<List<T>>>
      provider;
  final AssetType assetType;

  const AssetListPage({
    super.key,
    required this.provider,
    required this.assetType,
  });

  @override
  _AssetListPageState<T> createState() => _AssetListPageState<T>();
}

class _AssetListPageState<T extends Asset>
    extends ConsumerState<AssetListPage<T>> {
  // Pull-to-refresh corner animation config: maximum changes
  static const double _maxRadiusDelta = 13.5;
  static const double _maxSmoothnessDelta = 0.75;
  final ScrollController _scrollController = ScrollController();
  late final StreamSubscription<ConnectionStatus> _connSub;
  Timer? _errorRetryTimer;
  // Default card corner settings for pull-to-refresh animation
  late final double _defaultRadius;
  late final double _defaultSmoothness;

  // Search optimization: inverted index for fast substring search
  bool _searchIndexBuilt = false;
  final Map<String, Set<int>> _bigramIndex = {};
  final Map<String, Set<int>> _trigramIndex = {};
  // Track full data length to know when to rebuild the index
  int _lastFullDataLength = 0;

  // Current sorting mode for this list
  SortMode _sortMode = SortMode.defaultOrder;

  // Build bigram and trigram indices for assets list
  void _buildSearchIndex(List<T> assets) {
    _bigramIndex.clear();
    _trigramIndex.clear();
    for (int i = 0; i < assets.length; i++) {
      final asset = assets[i];
      // Aggregate searchable text fields
      String text =
          '${asset.name.toLowerCase()} ${asset.symbol.toLowerCase()} ${asset.id.toLowerCase()}';
      if (asset is CurrencyAsset) {
        text += ' ${asset.nameEn.toLowerCase()}';
      } else if (asset is GoldAsset) {
        text += ' ${asset.nameEn.toLowerCase()}';
      } else if (asset is CryptoAsset) {
        text += ' ${asset.nameFa.toLowerCase()}';
      } else if (asset is StockAsset) {
        text += ' ${asset.l30.toLowerCase()} ${asset.isin.toLowerCase()}';
      }
      text = text.replaceAll(RegExp(r'\s+'), ' ');
      // Build bigrams
      for (int j = 0; j <= text.length - 2; j++) {
        final gram = text.substring(j, j + 2);
        _bigramIndex.putIfAbsent(gram, () => <int>{}).add(i);
      }
      // Build trigrams
      for (int j = 0; j <= text.length - 3; j++) {
        final gram = text.substring(j, j + 3);
        _trigramIndex.putIfAbsent(gram, () => <int>{}).add(i);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Capture default card corner settings
    final initialSettings = ref.read(cardCornerSettingsProvider);
    _defaultRadius = initialSettings.radius;
    _defaultSmoothness = initialSettings.smoothness;
    _scrollController.addListener(_onScroll);
    // Initialize data when this page is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(widget.provider.notifier).initialize();
    });
    // Auto-refresh when connection is restored
    _connSub = ConnectionService().statusStream.listen((status) {
      if (status == ConnectionStatus.connected) {
        ref.read(widget.provider.notifier).refresh();
      }
    });
  }

  void _onScroll() {
    final pos = _scrollController.position.pixels;
    if (pos >= _scrollController.position.maxScrollExtent * 0.85) {
      // Load more when near the bottom
      ref.read(widget.provider.notifier).loadMore();
    }
    // Animate card corners on pull-to-refresh overscroll
    final settingsNotifier = ref.read(cardCornerSettingsProvider.notifier);
    if (pos < 0) {
      // Normalize overscroll up to 100 px to [0,1]
      final factor = (-pos / 100).clamp(0.0, 1.0);
      // Animate smoothness by max delta, radius by max delta
      final newSmooth = _defaultSmoothness + _maxSmoothnessDelta * factor;
      final newRadius = _defaultRadius + _maxRadiusDelta * factor;
      settingsNotifier.updateSmoothness(newSmooth);
      settingsNotifier.updateRadius(newRadius);
    } else {
      // Restore to default settings
      settingsNotifier.updateSmoothness(_defaultSmoothness);
      settingsNotifier.updateRadius(_defaultRadius);
    }
  }

  @override
  void dispose() {
    _connSub.cancel();
    _errorRetryTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Get optimal number of columns based on screen width
  int _getOptimalColumnCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final orientation = MediaQuery.of(context).orientation;

    // Phone - portrait
    if (width < 600 && orientation == Orientation.portrait) return 2;
    // Phone - landscape
    if (width < 900 && orientation == Orientation.landscape) return 4;
    // Tablet - portrait
    if (width < 900 && orientation == Orientation.portrait) return 5;
    // Tablet - landscape
    if (width < 1200 && orientation == Orientation.landscape) return 5;
    // Small desktop
    if (width < 1600) return 8;
    // Extra wide desktop/TV
    return 9;
  }

  // Calculate appropriate card aspect ratio based on screen size
  double _getCardAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final orientation = MediaQuery.of(context).orientation;

    // Base aspect ratio - slightly rectangular (width:height)
    const double baseAspectRatio =
        0.8; // Width is 80% of height for better mobile proportions

    // For phones in portrait mode
    if (width < 600 && orientation == Orientation.portrait) {
      return baseAspectRatio;
    }
    // For phones in landscape
    else if (width < 900 && orientation == Orientation.landscape) {
      return baseAspectRatio * 0.8; // Wider for landscape phone
    }
    // For tablets portrait
    else if (width < 900 && orientation == Orientation.portrait) {
      return baseAspectRatio * 0.9; // Slightly wider
    }
    // For tablets landscape and small desktop
    else if (width < 1200) {
      return baseAspectRatio * 0.9; // Even wider
    }
    // For large desktop
    else {
      return baseAspectRatio *
          0.9; // Most horizontally compact to fit more in a row
    }
  }

  @override
  Widget build(BuildContext context) {
    // Auto-retry on generic errors every 5 seconds
    ref.listen<AsyncValue<List<T>>>(widget.provider, (prev, next) {
      if (next is AsyncError<List<T>> &&
          !next.error.toString().contains('Offline')) {
        _errorRetryTimer?.cancel();
        _errorRetryTimer = Timer.periodic(
          const Duration(seconds: 5),
          (_) => ref.read(widget.provider.notifier).refresh(),
        );
      } else {
        _errorRetryTimer?.cancel();
      }
    });
    final asyncData = ref.watch(widget.provider);

    final favorites = ref.watch(favoritesProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentLocale = ref.watch(localeNotifierProvider);
    final isRTL = currentLocale.languageCode == 'fa';
    final appConfig = ref.watch(appConfigProvider).asData?.value;

    if (appConfig == null) {
      return const Center(child: CupertinoActivityIndicator());
    }

    return asyncData.when(
      data: (data) {
        // Always use the full fetched list for search
        final notifier = ref.read(widget.provider.notifier);
        final fullDataList = notifier._fullDataList;
        // If the full data has changed, reset the search index
        if (fullDataList.length != _lastFullDataLength) {
          _searchIndexBuilt = false;
          _lastFullDataLength = fullDataList.length;
        }
        List<T> displayedData = data;

        // Optimized filter: start only after 2 characters
        if (searchQuery.length >= 2) {
          // Build index on the full list if needed
          if (!_searchIndexBuilt) {
            _buildSearchIndex(fullDataList);
            _searchIndexBuilt = true;
          }
          final queryLower = searchQuery.toLowerCase();
          List<T> filtered = [];
          if (queryLower.length == 2) {
            // Bigram lookup
            final indices = _bigramIndex[queryLower] ?? <int>{};
            final sortedIdx = indices.toList()..sort();
            filtered = sortedIdx.map((i) => fullDataList[i]).toList();
          } else {
            // Trigram intersection
            Set<int>? resultSet;
            for (int k = 0; k <= queryLower.length - 3; k++) {
              final gram = queryLower.substring(k, k + 3);
              final gramSet = _trigramIndex[gram] ?? <int>{};
              if (resultSet == null) {
                resultSet = gramSet.toSet();
              } else {
                resultSet = resultSet.intersection(gramSet);
              }
              if (resultSet.isEmpty) break;
            }
            if (resultSet != null && resultSet.isNotEmpty) {
              final sortedIdx = resultSet.toList()..sort();
              filtered = sortedIdx.map((i) => fullDataList[i]).toList();
            }
          }
          displayedData = filtered;
        }

        // Sort based on user-selected mode
        late final List<T> sortedData;
        switch (_sortMode) {
          case SortMode.highestPrice:
            sortedData = [...displayedData]
              ..sort((a, b) => b.price.compareTo(a.price));
            break;
          case SortMode.lowestPrice:
            sortedData = [...displayedData]
              ..sort((a, b) => a.price.compareTo(b.price));
            break;
          default:
            final favoriteItems = displayedData
                .where((item) => favorites.contains(item.id))
                .toList();
            final nonFavoriteItems = displayedData
                .where((item) => !favorites.contains(item.id))
                .toList();
            sortedData = [...favoriteItems, ...nonFavoriteItems];
        }

        if (sortedData.isEmpty) {
          return Center(
            child: Text(
              searchQuery.isNotEmpty ? l10n.searchNoResults : l10n.listNoData,
              style: TextStyle(
                fontFamily: isRTL ? 'Vazirmatn' : 'SF-Pro',
                fontSize: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          );
        }

        final columnCount = _getOptimalColumnCount(context);
        final aspectRatio = _getCardAspectRatio(context);

        return CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // iOS-style refresh control
            CupertinoSliverRefreshControl(
              refreshTriggerPullDistance: 100.0,
              refreshIndicatorExtent: 60.0,
              onRefresh: () => ref.read(widget.provider.notifier).refresh(),
            ),
            // Grid of assets
            SliverPadding(
              padding: const EdgeInsets.all(8.0),
              sliver: Directionality(
                // Always use LTR for grid layout regardless of language
                textDirection: ui.TextDirection.ltr,
                child: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columnCount,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    childAspectRatio: aspectRatio,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final asset = sortedData[index];
                      // Add staggered animation to each card
                      return AnimatedCardBuilder(
                        index: index,
                        child: AssetCard(
                          asset: asset,
                          assetType: widget.assetType,
                        ),
                      );
                    },
                    childCount: sortedData.length,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (error, stack) {
        // Determine if this is a connection issue
        final isConnectionError = error.toString().contains('DioException') ||
            error.toString().contains('SocketException') ||
            error.toString().contains('TimeoutException');

        if (isConnectionError) {
          // For network errors, use our ErrorPlaceholder
          return const Center(
            child: ErrorPlaceholder(status: ConnectionStatus.serverDown),
          );
        }

        // For other errors, show minimal error UI
        return Center(
          child: CupertinoPopupSurface(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 25),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.exclamationmark_circle,
                    size: 32,
                    color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.errorGeneric,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: isRTL ? 'Vazirmatn' : 'SF-Pro',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CupertinoActivityIndicator(),
                      const SizedBox(width: 8),
                      Text(
                        l10n.retrying,
                        style: TextStyle(
                          fontFamily: isRTL ? 'Vazirmatn' : 'SF-Pro',
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Allow HomeScreen to change sorting mode
  void _setSortMode(SortMode mode) {
    setState(() {
      _sortMode = mode;
    });
  }
}

class AssetCard extends ConsumerWidget {
  final Asset asset;
  final AssetType assetType;
  // final double? height;

  const AssetCard({
    super.key,
    required this.asset,
    required this.assetType /*this.height*/,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appConfig = ref.watch(appConfigProvider).asData!.value;
    final isFavorite = ref.watch(
      favoritesProvider.select((favs) => favs.contains(asset.id)),
    );
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeNotifierProvider);
    final currencyUnit = ref.watch(currencyUnitProvider);
    final allCurrencies = ref.watch(currencyProvider); // For conversion rates
    final isDarkMode = theme.brightness == Brightness.dark;
    final cornerSettings = ref.watch(cardCornerSettingsProvider);

    // Get current theme config based on mode
    final themeConfig =
        isDarkMode ? appConfig.themeOptions.dark : appConfig.themeOptions.light;

    // Get teal green color for badges and indicators
    final tealGreen = _hexToColor(themeConfig.accentColorGreen);

    // Price conversion logic
    double numericPrice = 0.0;
    String displayUnit = '';

    num priceToConvert = asset.price;
    String originalUnitSymbol =
        ''; // e.g., "USD" or "تومان" for the asset's original price

    if (asset is CurrencyAsset) {
      originalUnitSymbol = (asset as CurrencyAsset).unit;
    } else if (asset is GoldAsset) {
      originalUnitSymbol = (asset as GoldAsset).unit;
      // If gold is in USD (like XAUUSD) and user wants Toman, we need USD->Toman rate
    } else if (asset is CryptoAsset) {
      originalUnitSymbol = "USD"; // Crypto prices are in USD from API
      // If user wants Toman, use price_toman field or convert USD->Toman
      if (currencyUnit == CurrencyUnit.toman) {
        priceToConvert = num.tryParse(
              (asset as CryptoAsset).priceToman.replaceAll(',', ''),
            ) ??
            asset.price;
        originalUnitSymbol = "تومان";
      }
    } else if (asset is StockAsset) {
      originalUnitSymbol =
          "ریال"; // Assuming TSE stocks are in Rial, then convert to Toman
      priceToConvert = asset.price / 10; // Rial to Toman
    }

    if (allCurrencies is AsyncData<List<CurrencyAsset>>) {
      final usdToTomanRate = allCurrencies.value
          .firstWhere(
            (c) => c.symbol == 'USD',
            orElse: () => const CurrencyAsset(
              id: 'USD',
              name: 'Dollar',
              nameEn: 'US Dollar',
              symbol: 'USD',
              price: 50000,
              unit: 'تومان',
            ),
          )
          .price;
      final eurToTomanRate = allCurrencies.value
          .firstWhere(
            (c) => c.symbol == 'EUR',
            orElse: () => const CurrencyAsset(
              id: 'EUR',
              name: 'Euro',
              nameEn: 'Euro',
              symbol: 'EUR',
              price: 60000,
              unit: 'تومان',
            ),
          )
          .price;

      num finalPrice = priceToConvert;

      if (currencyUnit == CurrencyUnit.toman) {
        if (originalUnitSymbol.toLowerCase() == "usd" ||
            originalUnitSymbol.toLowerCase() == "دلار") {
          finalPrice = priceToConvert * usdToTomanRate;
        } else if (originalUnitSymbol.toLowerCase() == "eur" ||
            originalUnitSymbol.toLowerCase() == "یورو") {
          finalPrice = priceToConvert * eurToTomanRate;
        } else if (originalUnitSymbol.toLowerCase() == "ریال") {
          finalPrice =
              priceToConvert; // Already converted from Rial to Toman for stocks
        }
        displayUnit = l10n.currencyUnitToman;
        numericPrice = finalPrice.toDouble();
      } else if (currencyUnit == CurrencyUnit.usd) {
        if (originalUnitSymbol.toLowerCase() == "toman" ||
            originalUnitSymbol.toLowerCase() == "تومان" ||
            originalUnitSymbol.toLowerCase() == "ریال") {
          finalPrice = priceToConvert / usdToTomanRate;
        } else if (originalUnitSymbol.toLowerCase() == "eur" ||
            originalUnitSymbol.toLowerCase() == "یورو") {
          finalPrice = (priceToConvert * eurToTomanRate) /
              usdToTomanRate; // EUR -> Toman -> USD
        }
        displayUnit = l10n.currencyUnitUSD;
        numericPrice = finalPrice.toDouble();
      } else if (currencyUnit == CurrencyUnit.eur) {
        if (originalUnitSymbol.toLowerCase() == "toman" ||
            originalUnitSymbol.toLowerCase() == "تومان" ||
            originalUnitSymbol.toLowerCase() == "ریال") {
          finalPrice = priceToConvert / eurToTomanRate;
        } else if (originalUnitSymbol.toLowerCase() == "usd" ||
            originalUnitSymbol.toLowerCase() == "دلار") {
          finalPrice = (priceToConvert * usdToTomanRate) /
              eurToTomanRate; // USD -> Toman -> EUR
        }
        displayUnit = l10n.currencyUnitEUR;
        numericPrice = finalPrice.toDouble();
      }
    } else {
      // Fallback if currency rates not loaded
      numericPrice = priceToConvert.toDouble();
      displayUnit = (asset is StockAsset)
          ? l10n.currencyUnitToman
          : (asset is CryptoAsset ? "USD" : (asset as dynamic).unit ?? '');
    }

    Widget iconWidget;
    if (assetType == AssetType.crypto &&
        (asset as CryptoAsset).iconUrl != null) {
      final cryptoConfig = appConfig.cryptoIconFilter;
      final double contrastValue = (1 + cryptoConfig.contrast + 0.2);
      final matrix = <double>[
        contrastValue,
        0,
        0,
        0,
        cryptoConfig.brightness * 255,
        0,
        contrastValue,
        0,
        0,
        cryptoConfig.brightness * 255,
        0,
        0,
        contrastValue,
        0,
        cryptoConfig.brightness * 255,
        0,
        0,
        0,
        1,
        0,
      ];
      // Get the stock glow color as fallback for all cryptos
      final defaultGlow = isDarkMode
          ? const ui.Color.fromARGB(255, 116, 158, 177)
          : const ui.Color.fromARGB(255, 94, 150, 255);

      // Check if we have a local SVG for this crypto
      final String cryptoName = (asset as CryptoAsset).name.toLowerCase();
      final CryptoIconInfo? cryptoIconInfo = _cryptoIconMap[cryptoName];

      if (cryptoIconInfo != null) {
        // Use local SVG with predefined glow color
        // The imageProvider for local SVGs is tricky for PaletteGenerator,
        // but since we use preferredGlowColor, PaletteGenerator will be skipped.
        // We can pass a dummy ImageProvider or the AssetImage if it helps CacheManager,
        // but it won't be used for palette generation.
        // For simplicity, let's use AssetImage, assuming it's a raster or PaletteGenerator handles it gracefully if unused.
        final ImageProvider<Object> localIconProvider = AssetImage(
          cryptoIconInfo.iconPath,
        );

        iconWidget = _DynamicGlow(
          key: ValueKey(asset.id),
          imageProvider:
              localIconProvider, // Primarily for consistency, won't be used by PaletteGenerator
          preferredGlowColor:
              cryptoIconInfo.color, // Pass the specific color here
          defaultGlowColor: defaultGlow, // Fallback
          size: 32.0,
          child: ClipOval(
            child: SvgPicture.asset(
              cryptoIconInfo.iconPath,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
            ),
          ),
        );
      } else {
        // Use network image with dynamic glow (PaletteGenerator will run with size optimization)
        iconWidget = _DynamicGlow(
          key: ValueKey(asset.id),
          imageProvider: CachedNetworkImageProvider(
            (asset as CryptoAsset).iconUrl!,
          ),
          // preferredGlowColor is null, so PaletteGenerator will attempt generation
          defaultGlowColor: defaultGlow, // Fallback if PaletteGenerator fails
          size: 32.0,
          child: ColorFiltered(
            // This ColorFiltered was here before, ensure it's still applied correctly
            colorFilter: ColorFilter.matrix(
              matrix,
            ), // matrix is defined earlier in the original code
            child: CachedNetworkImage(
              cacheManager: CacheManager(
                Config('cryptoCache', stalePeriod: const Duration(days: 30)),
              ),
              imageUrl: (asset as CryptoAsset).iconUrl!,
              width: 32,
              height: 32,
              imageBuilder: (context, imageProvider) => Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              placeholder: (context, url) => Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                ),
                child: const CupertinoActivityIndicator(radius: 8),
              ),
              errorWidget: (context, url, error) => Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                ),
                child: const Icon(
                  CupertinoIcons.exclamationmark_circle,
                  size: 16,
                ),
              ),
            ),
          ),
        );
      }
    } else if (assetType == AssetType.currency && asset is CurrencyAsset) {
      String currencyCode = (asset as CurrencyAsset).symbol.toLowerCase();
      String countryCode = _getCurrencyCountryCode(currencyCode);

      String flagPath = 'assets/icons/flags/$countryCode.svg';

      // Define the country/flag specific color for the glow effect
      final Map<String, Color> flagColors = {
        'us': const Color(0xFFB7082A), // USD
        'eu': const Color(0xFF0153B4), // EUR
        'ae': const Color(0xFF6DA445), // AED
        'gb': const Color(0xFFD80027), // GBP
        'jp': const Color(0xFFD80027), // JPY
        'kw': const Color(0xFF6DA445), // KWD
        'au': const Color(0xFF0654B5), // AUD
        'ca': const Color(0xFFD80027), // CAD
        'cn': const Color(0xFFD80127), // CNY
        'tr': const Color(0xFFD80027), // TRY
        'sa': const Color(0xFF527538), // SAR
        'ch': const Color(0xFFD9042B), // CHF
        'in': const Color(0xFFFE9B17), // INR
        'pk': const Color(0xFF486F2D), // PKR
        'iq': const Color(0xFFA30221), // IQD
        'sy': const Color(0xFF486F2D), // SYP
        'se': const Color(0xFF0D59AE), // SEK
        'qa': const Color(0xFF741B46), // QAR
        'om': const Color(0xFF709C42), // OMR
        'bh': const Color(0xFFD80027), // BHD
        'af': const Color(0xFF486F2D), // AFN
        'my': const Color(0xFF105BAD), // MYR
        'th': const Color(0xFF0153B4), // THB
        'ru': const Color(0xFFD80027), // RUB
        'az': const Color(0xFF6DA445), // AZN
        'am': const Color(0xFFFF9811), // AMD
        'ge': const Color(0xFFD9082C), // GEL
      };

      // Get appropriate color for the country or fall back to teal
      final flagColor = flagColors[countryCode] ?? tealGreen;

      iconWidget = Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: flagColor.withOpacity(0.5),
              blurRadius: 60,
              spreadRadius: 6,
            ),
          ],
        ),
        child: ClipOval(
          child: ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              1, 0, 0, 0, 0,
              0, 1, 0, 0, 0,
              0, 0, 1, 0, 0,
              0, 0, 0, 1.1, 0, // 10% contrast
            ]),
            child: SvgPicture.asset(
              flagPath,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              placeholderBuilder: (BuildContext context) => CircleAvatar(
                backgroundColor: Colors.grey[300],
                child: Text(
                  (asset as CurrencyAsset).symbol.substring(0, 1),
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ),
            ),
          ),
        ),
      );
    } else if (assetType == AssetType.gold) {
      // Commodity icon with dynamic glow
      final symbol = asset.symbol.toUpperCase();
      const commodityIconMap = <String, String>{
        '18K': '18_carat.png',
        '24K': '24_carat.png',
        'BAHAR': 'bahar.png',
        'EMAMI': 'emami.png',
        '1G': '1g.png',
        'MELTED': 'melted.png',
        'HALF': 'half.png',
        'QUARTER': 'quarter.png',
        'XAUUSD': 'gold_ounce.png',
        'XAGUSD': 'silver_ounce.png',
        'XPTUSD': 'p_ounce.png',
        'XPDUSD': 'p_ounce.png',
        'CU': 'element.png',
        'AL': 'element.png',
        'ZN': 'element.png',
        'PB': 'element.png',
        'NI': 'element.png',
        'SN': 'element.png',
        'BRENT': 'oil.png',
        'WTI': 'oil.png',
        'OPEC': 'oil.png',
        'GASOIL': 'gas_oil.png',
        'RBOB': 'gas_oil.png',
        'GAS': 'gas.png',
      };
      final fileName = commodityIconMap[symbol] ?? 'blank.png';
      final assetPath = 'assets/icons/commodity/$fileName';
      iconWidget = _DynamicGlow(
        key: ValueKey(asset.id),
        imageProvider: AssetImage(assetPath),
        defaultGlowColor: tealGreen,
        size: 32.0,
        child: ClipOval(
          child: Image.asset(
            assetPath,
            width: 32,
            height: 32,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      // Fallback for stocks or missing icons
      final stockColor = isDarkMode
          ? const ui.Color.fromARGB(255, 116, 158, 177)
          : const ui.Color.fromARGB(255, 94, 150, 255);

      iconWidget = Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: stockColor.withOpacity(0.5),
              blurRadius: 60,
              spreadRadius: 6,
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: theme.colorScheme.surfaceContainerLow,
          child: Text(
            asset.symbol.substring(0, math.min(asset.symbol.length, 1)),
            style: theme.textTheme.labelMedium,
          ),
        ),
      );
    }

    String assetName =
        currentLocale.languageCode == 'fa' && asset is CryptoAsset
            ? (asset as CryptoAsset).nameFa
            : asset.name;
    if (currentLocale.languageCode == 'fa' && asset is CurrencyAsset) {
      assetName = asset.name;
    }
    if (currentLocale.languageCode == 'en' && asset is CurrencyAsset) {
      assetName = (asset as CurrencyAsset).nameEn;
    }
    if (currentLocale.languageCode == 'en' && asset is GoldAsset) {
      assetName = (asset as GoldAsset).nameEn;
    }

    // Detect if the text has Persian/Arabic characters for consistent font selection
    bool hasPersianChars = _containsPersian(assetName);
    // Use appropriate font based on text content, not just locale
    String nameFontFamily = hasPersianChars ? 'Vazirmatn' : 'SF-Pro';

    // For green/red colors in change percentage
    final accentColorGreen = tealGreen;

    final accentColorRed = isDarkMode
        ? _hexToColor(appConfig.themeOptions.dark.accentColorRed)
        : _hexToColor(appConfig.themeOptions.light.accentColorRed);

    // Determine layout direction based on text content and locale
    final isNameRTL = hasPersianChars || currentLocale.languageCode == 'fa';
    final ui.TextDirection nameDirection =
        isNameRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr;

    // Use GestureDetector instead of InkWell to remove hover effect for web
    return GestureDetector(
      // Only long press will toggle favorite
      onLongPress: () {
        ref.read(favoritesProvider.notifier).toggleFavorite(asset.id);
      },
      child: SmoothCard(
        smoothness: cornerSettings.smoothness,
        borderRadius: BorderRadius.circular(cornerSettings.radius),
        elevation: 0, // Flat design
        color: _hexToColor(themeConfig.cardColor),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.center,
              colors: [
                theme.colorScheme.primary
                    .lighten(10)
                    .withAlpha(25), // 25% opacity - Spotlight
                Colors.transparent,
              ],
            ),
          ),
          padding: const EdgeInsets.all(12.0),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween, // Distribute space
                children: [
                  // Top row - name always on right, icon always on left, regardless of language
                  Row(
                    textDirection:
                        ui.TextDirection.ltr, // Force LTR so icon stays left
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Align icon and text at top
                    children: [
                      // Icon always on left
                      iconWidget,

                      // Small spacing
                      const SizedBox(width: 8),

                      // Name always on right
                      Expanded(
                        child: Text(
                          assetName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: nameFontFamily,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right, // Always right-aligned
                        ),
                      ),
                    ],
                  ),

                  // Combined Pin and Symbol Badges
                  Builder(
                    builder: (context) {
                      Widget? pinBadgeWidget;
                      if (isFavorite) {
                        pinBadgeWidget = Container(
                          height: 16, // Fixed height to match symbol badge
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? tealGreen.withAlpha(38)
                                : theme.colorScheme.secondaryContainer
                                    .withAlpha(128),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            CupertinoIcons.eye_fill,
                            size: 11, // Smaller width, height consistent
                            color: isDarkMode
                                ? tealGreen.withAlpha(230)
                                : theme.colorScheme.onSecondaryContainer,
                          ),
                        );
                      }

                      Widget? symbolBadgeInnerWidget;
                      if (assetType == AssetType.currency ||
                          assetType == AssetType.gold) {
                        symbolBadgeInnerWidget = Container(
                          height: 16, // Fixed height to match pin badge
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? tealGreen.withAlpha(38)
                                : theme.colorScheme.secondaryContainer
                                    .withAlpha(128),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            asset.symbol,
                            style: TextStyle(
                              fontFamily: 'CourierPrime',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? tealGreen.withAlpha(230)
                                  : theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        );
                      }

                      if (pinBadgeWidget == null &&
                          symbolBadgeInnerWidget == null) {
                        return const SizedBox.shrink(); // No badges to display
                      }

                      List<Widget> badgeChildren = [];
                      if (pinBadgeWidget != null) {
                        badgeChildren.add(pinBadgeWidget);
                      }
                      if (symbolBadgeInnerWidget != null) {
                        if (pinBadgeWidget != null) {
                          // Pin badge is left of symbol badge
                          badgeChildren.add(const SizedBox(width: 5));
                        }
                        badgeChildren.add(symbolBadgeInnerWidget);
                      }

                      return Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: badgeChildren,
                          ),
                        ),
                      );
                    },
                  ),
                  const Spacer(), // Push remaining content to the bottom
                  // Price change percentage in green/red - minimal spacing
                  if (asset.changePercent != null)
                    AnimatedAlign(
                      alignment: currentLocale.languageCode == 'en'
                          ? Alignment.centerLeft // Left-aligned in English mode
                          : Alignment
                              .centerRight, // Right-aligned in Persian mode
                      duration: const Duration(milliseconds: 400),
                      curve: const Cubic(0.77, 0, 0.175, 1),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: currentLocale.languageCode == 'en'
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.end,
                        children: currentLocale.languageCode == 'en'
                            ? [
                                Text(
                                  '${_formatPercentage(asset.changePercent!, currentLocale.languageCode)}%',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: asset.changePercent! > 0
                                        ? accentColorGreen
                                        : asset.changePercent! < 0
                                            ? accentColorRed
                                            : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  asset.changePercent! > 0
                                      ? CupertinoIcons.arrow_up_right
                                      : asset.changePercent! < 0
                                          ? CupertinoIcons.arrow_down_right
                                          : CupertinoIcons.minus,
                                  color: asset.changePercent! > 0
                                      ? accentColorGreen
                                      : asset.changePercent! < 0
                                          ? accentColorRed
                                          : Colors.grey,
                                  size: 12,
                                ),
                              ]
                            : [
                                Icon(
                                  asset.changePercent! > 0
                                      ? CupertinoIcons.arrow_up_right
                                      : asset.changePercent! < 0
                                          ? CupertinoIcons.arrow_down_right
                                          : CupertinoIcons.minus,
                                  color: asset.changePercent! > 0
                                      ? accentColorGreen
                                      : asset.changePercent! < 0
                                          ? accentColorRed
                                          : Colors.grey,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_formatPercentage(asset.changePercent!, currentLocale.languageCode)}%',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: asset.changePercent! > 0
                                        ? accentColorGreen
                                        : asset.changePercent! < 0
                                            ? accentColorRed
                                            : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                      ),
                    ),

                  // Small space between percentage and price
                  const SizedBox(height: 4),

                  // Price display
                  AnimatedAlign(
                    alignment: currentLocale.languageCode == 'en'
                        ? Alignment.centerLeft // Left-aligned in English mode
                        : Alignment
                            .centerRight, // Right-aligned in Persian mode
                    duration: const Duration(milliseconds: 400),
                    curve: const Cubic(0.77, 0, 0.175, 1),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: numericPrice),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOutQuart,
                        builder: (context, value, child) {
                          final priceText = _formatPrice(
                            value,
                            currentLocale.languageCode,
                          );
                          return Text(
                            priceText,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamily: _containsPersian(priceText)
                                  ? 'Vazirmatn'
                                  : 'SF-Pro',
                            ),
                            maxLines: 1,
                            textAlign: currentLocale.languageCode == 'en'
                                ? TextAlign.left
                                : TextAlign.right,
                          );
                        },
                      ),
                    ),
                  ),

                  // Unit display
                  AnimatedAlign(
                    alignment: currentLocale.languageCode == 'en'
                        ? Alignment.centerLeft // Left-aligned in English mode
                        : Alignment
                            .centerRight, // Right-aligned in Persian mode
                    duration: const Duration(milliseconds: 400),
                    curve: const Cubic(0.77, 0, 0.175, 1),
                    child: Text(
                      displayUnit,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFamily: _containsPersian(displayUnit)
                            ? 'Vazirmatn'
                            : 'SF-Pro',
                      ),
                      textAlign: currentLocale.languageCode == 'en'
                          ? TextAlign.left
                          : TextAlign.right,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// endregion

// region 7. Search Functionality
class AssetSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;
  final int currentTabIndex; // To know which asset type to search
  late final TextEditingController queryTextEditingController;

  AssetSearchDelegate({required this.ref, required this.currentTabIndex}) {
    queryTextEditingController = TextEditingController(text: query);
    queryTextEditingController.addListener(() {
      if (queryTextEditingController.text != query) {
        query = queryTextEditingController.text;
      }
    });
  }

  @override
  void close(BuildContext context, String result) {
    // Reset search query when closing search screen
    ref.read(searchQueryProvider.notifier).state = '';
    queryTextEditingController.dispose();
    super.close(context, result);
  }

  @override
  String get searchFieldLabel =>
      AppLocalizations.of(ref.context)!.searchPlaceholder;

  @override
  List<Widget>? buildActions(BuildContext context) {
    // Hide clear action since we have it in the search field itself
    if (query.isEmpty) return [];

    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 30,
          child: Text(
            AppLocalizations.of(context)!.dialogClose,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 16,
              fontFamily: 'SF-Pro', // iOS system font
              fontWeight: FontWeight.w400,
            ),
          ),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool isRTL = Localizations.localeOf(context).languageCode == 'fa';

    // iOS-style back button
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => close(context, ''),
        child: Icon(
          isRTL ? CupertinoIcons.forward : CupertinoIcons.back,
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
      ),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Check if query has RTL characters and update the textDirection accordingly
    final bool isRTLQuery = _containsPersian(query);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchQueryProvider.notifier).state = query;
    });

    // Determine text direction based on query content
    ui.TextDirection direction =
        isRTLQuery ? ui.TextDirection.rtl : ui.TextDirection.ltr;

    return Directionality(
      textDirection: direction,
      child: _buildFilteredList(context),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Check if query has RTL characters and update the textDirection accordingly
    final bool isRTLQuery = _containsPersian(query);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchQueryProvider.notifier).state = query;
    });

    // Determine text direction based on query content
    ui.TextDirection direction =
        isRTLQuery ? ui.TextDirection.rtl : ui.TextDirection.ltr;

    return Directionality(
      textDirection: direction,
      child: _buildFilteredList(context),
    );
  }

  Widget _buildFilteredList(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Determine which asset list to show based on the tab index when search was initiated
    Widget listToShow;
    switch (currentTabIndex) {
      case 0: // Currency
        listToShow = AssetListPage<CurrencyAsset>(
          provider: currencyProvider,
          assetType: AssetType.currency,
        );
        break;
      case 1: // Gold
        listToShow = AssetListPage<GoldAsset>(
          provider: goldProvider,
          assetType: AssetType.gold,
        );
        break;
      case 2: // Crypto
        listToShow = AssetListPage<CryptoAsset>(
          provider: cryptoProvider,
          assetType: AssetType.crypto,
        );
        break;
      case 3: // Stock - This would need to know the sub-tab index too if search is specific to sub-tabs
        // For simplicity, search across all stock types or just the primary (TSE/IFB)
        // This part requires more complex state management for search within nested tabs.
        // As a placeholder, show TSE/IFB results.
        listToShow = AssetListPage<StockAsset>(
          provider: stockTseIfbProvider,
          assetType: AssetType.stock,
        );
        break;
      default:
        listToShow = Center(child: Text(l10n.searchNoResults));
    }

    if (query.isEmpty) {
      // Show full asset list when no search query is entered
      return listToShow;
    }

    // The AssetListPage itself handles filtering based on searchQueryProvider.
    // So, we just need to display the correct AssetListPage.
    return listToShow;
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // iOS-style search app bar theme
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: isDarkMode
            ? const Color(0xFF1C1C1E) // iOS dark mode navigation bar
            : const Color(0xFFF2F2F7), // iOS light mode navigation bar
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black,
          size: 22, // iOS-style icon size
        ),
        toolbarHeight: 44.0, // Standard iOS nav bar height
      ),
      scaffoldBackgroundColor: isDarkMode
          ? const Color(0xFF1C1C1E) // iOS dark mode background
          : const Color(0xFFF2F2F7), // iOS light mode background
      dividerTheme: DividerThemeData(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
        thickness: 0.5, // iOS-style thin divider
        space: 0.5,
      ),
      textTheme: theme.textTheme.copyWith(
        titleLarge: TextStyle(
          fontFamily: 'SF-Pro', // iOS-style font
          fontWeight: FontWeight.w600, // iOS-style semibold
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: 17, // iOS-style navigation title size
        ),
        bodyMedium: TextStyle(
          fontFamily: 'SF-Pro',
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: 16,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: theme.colorScheme.primary, // Use accent color for cursor
        selectionColor: theme.colorScheme.primary.withAlpha(77),
        selectionHandleColor: theme.colorScheme.primary,
      ),
    );
  }

  // Custom search field with iOS-style design
  @override
  Widget buildSearchField(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Get app colors to match iOS style
    final appConfig = ref.watch(appConfigProvider).asData?.value;
    final bgColor = isDarkMode
        ? const Color(0xFF1C1C1E) // iOS dark mode searchbar color
        : const Color(0xFFE5E5EA); // iOS light mode searchbar color

    // Dynamically detect RTL for current query text
    bool isRTLQuery = _containsPersian(query);
    String fontFamily = isRTLQuery ? 'Vazirmatn' : 'SF-Pro';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      height: 36, // iOS search bar height
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: CupertinoTextField(
        controller: queryTextEditingController,
        padding: EdgeInsets.only(
          top: 8,
          bottom: 8,
          left: isRTLQuery ? 8 : 30, // Account for search icon
          right: isRTLQuery ? 30 : 8,
        ),
        textInputAction: TextInputAction.search,
        textAlign: isRTLQuery ? TextAlign.right : TextAlign.left,
        textAlignVertical: TextAlignVertical.center,
        placeholderStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        prefix: isRTLQuery
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  CupertinoIcons.search,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  size: 18,
                ),
              ),
        suffix: isRTLQuery
            ? Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  CupertinoIcons.search,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  size: 18,
                ),
              )
            : query.isNotEmpty
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 30,
                    child: Icon(
                      CupertinoIcons.clear,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      size: 18,
                    ),
                    onPressed: () {
                      query = '';
                      queryTextEditingController.clear();
                      showSuggestions(context);
                    },
                  )
                : null,
        placeholder: searchFieldLabel,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        cursorColor: theme.colorScheme.primary,
        cursorWidth: 1.5,
        onChanged: (newQuery) {
          query = newQuery;

          // Update text direction and font as user types
          final isRTL = _containsPersian(newQuery);

          // Rebuild the field with updated direction if RTL status changed
          if (isRTL != isRTLQuery) {
            // Force rebuild with new direction
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showSuggestions(context);
            });
          } else {
            showSuggestions(context);
          }
        },
      ),
    );
  }
}
// endregion

// region 8. Localization (AppLocalizations & Delegate)
// This will be generated by `flutter gen-l10n` if you use ARB files.
// For a single file, we define it manually.

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  Map<String, String> _localizedStrings = {};

  Future<bool> load() async {
    // In a real app with ARB files, this would load the ARB file.
    // Here, we define strings directly.
    if (locale.languageCode == 'fa') {
      _localizedStrings = {
        'riyalesAppTitle': 'ریالِس',
        'tabCurrency': 'ارز',
        'tabGold': 'طلا',
        'tabCrypto': 'کریپتو',
        'tabStock': 'بورس',
        'stockTabSymbols': 'نمادها',
        'stockTabDebtSecurities': 'اوراق', //'اوراق بدهی'
        'stockTabFutures': 'آتی',
        'stockTabHousingFacilities': 'تسهیلات', //'تسهیلات مسکن'
        'searchPlaceholder': 'جستجو...',
        'listNoData': 'داده‌ای برای نمایش وجود ندارد.',
        'searchNoResults': 'نتیجه‌ای یافت نشد.',
        'searchStartTyping': 'برای جستجو تایپ کنید.',
        'errorFetchingData': 'خطا در دریافت اطلاعات',
        'retryButton': 'تلاش مجدد',
        'cardTapped': 'کارت لمس شد',
        'settingsTitle': 'تنظیمات',
        'settingsTheme': 'پوسته برنامه',
        'themeLight': 'روشن',
        'themeDark': 'تاریک',
        'settingsLanguage': 'زبان برنامه',
        'dialogClose': 'بستن',
        'settingsCurrencyUnit': 'واحد پول نمایش',
        'currencyUnitToman': 'تومان',
        'currencyUnitUSD': 'دلار',
        'currencyUnitEUR': 'یورو',
        'errorNoInternet': 'اتصال اینترنت برقرار نیست',
        'errorCheckConnection': 'لطفاً اتصال اینترنت خود را بررسی کنید.',
        'errorServerUnavailable': 'سرور در دسترس نیست.',
        'errorServerMessage': 'لطفاً کمی بعد امتحان کنید.',
        'errorGeneric': 'خطا در نمایش اطلاعات',
        'retrying': 'در حال تلاش مجدد...',
        'youreOffline': 'اتصال اینترنت قطع است.',
        'youreBackOnline': 'اتصال به اینترنت برقرار شد.',
        'settingsUpdateAvailable': 'برنامه جدید',
        'settingsTerms': 'شرایط و ضوابط',
        'settingsAppVersion': 'ورژن برنامه',
        'settingsCardCorner': 'زاویه گرد کردن کارت',
        'settingsCardRadius': 'شعاع کارت',
        'settingsCardSmoothness': 'صافی کارت',
        'settingsCardPreview': 'پیش نمایش کارت',
        'settingsTerms': 'قوانین و مقررات',
        'settingsAppVersion': 'نسخه برنامه',
        'settingsUpdateAvailable': 'بروزرسانی موجود است',
      };
    } else {
      // English fallback
      _localizedStrings = {
        'riyalesAppTitle': 'Riyales',
        'tabCurrency': 'Currency',
        'tabGold': 'Gold',
        'tabCrypto': 'Crypto',
        'tabStock': 'Stocks',
        'stockTabSymbols': 'Symbols',
        'stockTabDebtSecurities': 'Securities', //'Debt Securities'
        'stockTabFutures': 'Futures',
        'stockTabHousingFacilities': 'Facilities', //'Housing Facilities'
        'searchPlaceholder': 'Search...',
        'listNoData': 'No data to display.',
        'searchNoResults': 'No results found.',
        'searchStartTyping': 'Start typing to search.',
        'errorFetchingData': 'Error fetching data',
        'retryButton': 'Retry',
        'cardTapped': 'Card tapped',
        'settingsTitle': 'Settings',
        'settingsTheme': 'App Theme',
        'themeLight': 'Light',
        'themeDark': 'Dark',
        'settingsLanguage': 'App Language',
        'dialogClose': 'Close',
        'settingsCurrencyUnit': 'Display Currency Unit',
        'currencyUnitToman': 'Toman',
        'currencyUnitUSD': 'Dollar',
        'currencyUnitEUR': 'Euro',
        'errorNoInternet': 'No Internet Connection',
        'errorCheckConnection': 'Please check your internet connection.',
        'errorServerUnavailable': 'Server Unavailable',
        'errorServerMessage': 'Please try again later.',
        'errorGeneric': 'Could not display data',
        'retrying': 'Retrying automatically...',
        'youreOffline': 'You\'re offline.',
        'youreBackOnline': 'You\'re back online.',
        'settingsTerms': 'Terms & Conditions',
        'settingsAppVersion': 'App Version',
        'settingsUpdateAvailable': 'Update Available',
      };
    }
    return true;
  }

  String get riyalesAppTitle => _localizedStrings['riyalesAppTitle']!;
  String get tabCurrency => _localizedStrings['tabCurrency']!;
  String get tabGold => _localizedStrings['tabGold']!;
  String get tabCrypto => _localizedStrings['tabCrypto']!;
  String get tabStock => _localizedStrings['tabStock']!;
  String get stockTabSymbols => _localizedStrings['stockTabSymbols']!;
  String get stockTabDebtSecurities =>
      _localizedStrings['stockTabDebtSecurities']!;
  String get stockTabFutures => _localizedStrings['stockTabFutures']!;
  String get stockTabHousingFacilities =>
      _localizedStrings['stockTabHousingFacilities']!;
  String get searchPlaceholder => _localizedStrings['searchPlaceholder']!;
  String get listNoData => _localizedStrings['listNoData']!;
  String get searchNoResults => _localizedStrings['searchNoResults']!;
  String get searchStartTyping => _localizedStrings['searchStartTyping']!;
  String get errorFetchingData => _localizedStrings['errorFetchingData']!;
  String get retryButton => _localizedStrings['retryButton']!;
  String get cardTapped => _localizedStrings['cardTapped']!;
  String get settingsTitle => _localizedStrings['settingsTitle']!;
  String get settingsTheme => _localizedStrings['settingsTheme']!;
  String get themeLight => _localizedStrings['themeLight']!;
  String get themeDark => _localizedStrings['themeDark']!;
  String get settingsLanguage => _localizedStrings['settingsLanguage']!;
  String get dialogClose => _localizedStrings['dialogClose']!;
  String get settingsCurrencyUnit => _localizedStrings['settingsCurrencyUnit']!;
  String get currencyUnitToman => _localizedStrings['currencyUnitToman']!;
  String get currencyUnitUSD => _localizedStrings['currencyUnitUSD']!;
  String get currencyUnitEUR => _localizedStrings['currencyUnitEUR']!;
  String get settingsCardCorner => _localizedStrings['settingsCardCorner']!;
  String get settingsCardRadius => _localizedStrings['settingsCardRadius']!;
  String get settingsCardSmoothness =>
      _localizedStrings['settingsCardSmoothness']!;
  String get settingsCardPreview => _localizedStrings['settingsCardPreview']!;
  String get settingsTerms => _localizedStrings['settingsTerms']!;
  String get settingsAppVersion => _localizedStrings['settingsAppVersion']!;
  String get settingsUpdateAvailable =>
      _localizedStrings['settingsUpdateAvailable']!;

  // Error handling messages
  String get errorNoInternet => _localizedStrings['errorNoInternet']!;
  String get errorCheckConnection => _localizedStrings['errorCheckConnection']!;
  String get errorServerUnavailable =>
      _localizedStrings['errorServerUnavailable']!;
  String get errorServerMessage => _localizedStrings['errorServerMessage']!;
  String get errorGeneric => _localizedStrings['errorGeneric']!;
  String get retrying => _localizedStrings['retrying']!;
  String get youreOffline => _localizedStrings['youreOffline']!;
  String get youreBackOnline => _localizedStrings['youreBackOnline']!;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Include all supported languages here
    return ['en', 'fa'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// endregion

// region 9. Utility Functions
String _getGoldIconPath(String symbol) {
  // Map gold symbols to specific SVG icons in assets/icons/
  // Example:
  // if (symbol == 'IR_GOLD_18K') return 'assets/icons/gold_18k.svg';
  // if (symbol == 'XAUUSD') return 'assets/icons/gold_ounce.svg';
  return 'assets/icons/gold_generic.svg'; // Fallback generic gold icon
}

String _formatPrice(num price, String locale, {bool showSign = false}) {
  // Use NumberFormat for locale-aware formatting
  final format = NumberFormat.currency(
    locale: locale == 'fa'
        ? 'fa_IR'
        : 'en_US', // fa_IR for Persian numerals and grouping
    symbol: '', // No currency symbol, unit is separate
    decimalDigits: (price < 10 && price != 0 && price.remainder(1) != 0)
        ? 4
        : (price < 1000 ? 2 : 0), // More decimals for small prices
  );
  String formattedPrice = format.format(price);
  if (showSign && price > 0) {
    formattedPrice = '+$formattedPrice';
  }
  return formattedPrice;
}

String _formatPercentage(num percentage, String locale) {
  final format = NumberFormat("#,##0.##", locale == 'fa' ? 'fa_IR' : 'en_US');
  return format.format(percentage);
}

// Add new helper functions
// Helper for mapping currency codes to country codes
String _getCurrencyCountryCode(String currencyCode) {
  // Map of currency codes to ISO country codes
  Map<String, String> currencyToCountry = {
    'usd': 'us',
    'eur': 'eu', // European Union
    'gbp': 'gb',
    'jpy': 'jp',
    'cad': 'ca',
    'aud': 'au',
    'chf': 'ch',
    'cny': 'cn',
    'aed': 'ae',
    'try': 'tr',
    'rub': 'ru',
    'inr': 'in',
    'brl': 'br',
    'myr': 'my',
    'sgd': 'sg',
    'nzd': 'nz',
    'hkd': 'hk',
    'sek': 'se',
    'nok': 'no',
    'dkk': 'dk',
    'mxn': 'mx',
    'zar': 'za',
    'thb': 'th',
    'krw': 'kr',
    'pkr': 'pk',
    'pln': 'pl',
    'czk': 'cz',
    'ils': 'il',
    'twd': 'tw',
    'idr': 'id',
    'php': 'ph',
    'rsd': 'rs',
    'egp': 'eg',
    'sar': 'sa',
    'qar': 'qa',
    'bhd': 'bh',
    'omr': 'om',
    'kwd': 'kw',
    'irr': 'ir',
    'afn': 'af',
    'dzd': 'dz',
    'jod': 'jo',
    'lbp': 'lb',
    'mad': 'ma',
    'tnd': 'tn',
    'azn': 'az',
  };

  return currencyToCountry[currencyCode] ??
      currencyCode.substring(0, math.min(currencyCode.length, 2));
}

// Helper to detect Persian text
bool _containsPersian(String text) {
  // Unicode range for Arabic and Persian characters
  final RegExp persianChars = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
  );
  return persianChars.hasMatch(text);
}

// region 2.5 Connection Service and Error UI
class ConnectionService {
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

  bool _isOnline = false;
  bool get isOnline => _isOnline;

  final _statusController = StreamController<ConnectionStatus>.broadcast();
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  Future<void> initialize(String apiUrl) async {
    await _checkAndUpdateStatus(apiUrl);

    // Setup periodic check regardless of current status
    _startPeriodicPing(apiUrl);
  }

  Future<void> _checkAndUpdateStatus(String apiUrl) async {
    // Initial ping test
    final apiAvailable = await ping(apiUrl);
    if (apiAvailable) {
      final wasOffline = !_isOnline;
      _isOnline = true;

      // Only notify if state changed
      if (wasOffline) {
        _statusController.add(ConnectionStatus.connected);
      }
    } else {
      // Try pinging Google as fallback
      final internetAvailable = await ping('https://www.google.com');
      if (internetAvailable) {
        _isOnline = false;
        _statusController.add(ConnectionStatus.serverDown);
      } else {
        _isOnline = false;
        _statusController.add(ConnectionStatus.internetDown);
      }
    }
  }

  Timer? _pingTimer;
  void _startPeriodicPing(String apiUrl) {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _checkAndUpdateStatus(apiUrl);
    });
  }

  Future<bool> checkConnection(String apiUrl) async {
    // Use our shared check and update logic
    await _checkAndUpdateStatus(apiUrl);
    return _isOnline;
  }

  Future<bool> ping(String url) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        url,
        options: Options(
          validateStatus: (_) => true,
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode != null && response.statusCode! < 400;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _pingTimer?.cancel();
    _statusController.close();
  }
}

enum ConnectionStatus { connected, serverDown, internetDown }

// Error UI components
class ErrorPlaceholder extends ConsumerWidget {
  final ConnectionStatus status;

  const ErrorPlaceholder({required this.status, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentLocale = ref.watch(localeNotifierProvider);
    final isRTL = currentLocale.languageCode == 'fa';

    String title = '';
    String message = '';
    IconData icon = CupertinoIcons.wifi_slash;
    // Reduced vibrance for the icon, use gray instead of red
    Color iconColor = isDarkMode ? Colors.grey[500]! : Colors.grey[400]!;

    switch (status) {
      case ConnectionStatus.internetDown:
        title = l10n.errorNoInternet;
        message = l10n.errorCheckConnection;
        icon = CupertinoIcons.wifi_slash;
        break;
      case ConnectionStatus.serverDown:
        title = l10n.errorServerUnavailable;
        message = l10n.errorServerMessage;
        icon = CupertinoIcons.exclamationmark_circle;
        break;
      case ConnectionStatus.connected:
        // This shouldn't be shown, but as a fallback
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 50, // reduced size
            color: iconColor,
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18, // smaller
              fontWeight: FontWeight.w500, // lighter
              fontFamily: isRTL ? 'Vazirmatn' : 'SF-Pro',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              fontFamily: isRTL ? 'Vazirmatn' : 'SF-Pro',
            ),
          ),
          const SizedBox(height: 36),
          // iOS-style loading indicator
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CupertinoActivityIndicator(radius: 10),
              const SizedBox(width: 12),
              Text(
                l10n.retrying,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontFamily: isRTL ? 'Vazirmatn' : 'SF-Pro',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ConnectionSnackbar {
  static void show(
    BuildContext context, {
    required bool isConnected,
    required bool isRTL,
  }) {
    // Get safe area
    final safeArea = MediaQuery.of(context).padding;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Remove any existing snackbars
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Show the new snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        duration: const Duration(milliseconds: 2500), // 2.5 seconds
        behavior: SnackBarBehavior.floating,
        backgroundColor: isConnected
            ? Theme.of(context).colorScheme.secondary
            : Theme.of(context).colorScheme.error,
        margin: const EdgeInsets.only(
          bottom: 10, // Reduced margins
          left: 10,
          right: 10,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          textDirection: isRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          children: [
            Icon(
              isConnected ? CupertinoIcons.wifi : CupertinoIcons.wifi_slash,
              color: Colors.white,
              size: 20, // increased size
            ),
            const SizedBox(width: 12),
            Text(
              isConnected
                  ? AppLocalizations.of(context)!.youreBackOnline
                  : AppLocalizations.of(context)!.youreOffline,
              style: TextStyle(
                fontFamily: isRTL ? 'Vazirmatn' : 'SF-Pro',
                color: Colors.white,
              ),
            ),
          ],
        ),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }
}

// Offline indicator overlay
class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        CupertinoIcons.wifi_slash,
        size: 80,
        color: Colors.grey.withOpacity(0.2),
      ),
    );
  }
}

// Network-aware widget wrapper
class NetworkAwareWidget extends ConsumerStatefulWidget {
  final Widget onlineWidget;
  final Widget Function(ConnectionStatus)? offlineBuilder;
  final bool checkOnInit;

  const NetworkAwareWidget({
    super.key,
    required this.onlineWidget,
    this.offlineBuilder,
    this.checkOnInit = false,
  });

  @override
  ConsumerState<NetworkAwareWidget> createState() => _NetworkAwareWidgetState();
}

class _NetworkAwareWidgetState extends ConsumerState<NetworkAwareWidget> {
  late StreamSubscription<ConnectionStatus> _subscription;
  ConnectionStatus _currentStatus = ConnectionStatus.connected;
  bool _showOfflineOverlay = false;
  ConnectionService connectionService = ConnectionService();

  @override
  void initState() {
    super.initState();

    // Force check connection status on widget init
    _checkConnectionOnInit();

    // Listen for connection status changes
    _subscription = connectionService.statusStream.listen((status) {
      if (_currentStatus != status) {
        setState(() {
          _currentStatus = status;
          _showOfflineOverlay = status != ConnectionStatus.connected;
        });

        // Only show snackbar for status changes, not initial status
        if (mounted && context.mounted) {
          final locale = ref.read(localeNotifierProvider);
          final isRTL = locale.languageCode == 'fa';

          ConnectionSnackbar.show(
            context,
            isConnected: status == ConnectionStatus.connected,
            isRTL: isRTL,
          );
        }
      }
    });
  }

  void _checkConnectionOnInit() async {
    if (widget.checkOnInit) {
      final appConfig = ref.read(appConfigProvider).asData?.value;
      if (appConfig != null) {
        final apiUrl = appConfig.apiEndpoints.currencyUrl;
        await connectionService.checkConnection(apiUrl);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check connection again when widget becomes visible (e.g., tab change)
    _checkConnectionOnInit();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStatus == ConnectionStatus.connected) {
      return widget.onlineWidget;
    }

    if (widget.offlineBuilder != null) {
      return widget.offlineBuilder!(_currentStatus);
    }

    // Default offline UI with overlay
    return Stack(
      children: [
        widget.onlineWidget,
        if (_showOfflineOverlay) const OfflineIndicator(),
      ],
    );
  }
}
// endregion

// Connection helper extension for Riverpod
extension ConnectionServiceExtension on WidgetRef {
  // Helper to check connection before loading data
  Future<bool> checkConnectionBeforeLoading(String apiUrl) async {
    final connectionService = ConnectionService();
    final isConnected = await connectionService.checkConnection(apiUrl);
    return isConnected;
  }
}

// AnimatedCardBuilder for smooth card appearances
class AnimatedCardBuilder extends StatefulWidget {
  final int index;
  final Widget child;
  final bool initialLoad;

  const AnimatedCardBuilder({
    super.key,
    required this.index,
    required this.child,
    this.initialLoad = false,
  });

  @override
  State<AnimatedCardBuilder> createState() => _AnimatedCardBuilderState();
}

class _AnimatedCardBuilderState extends State<AnimatedCardBuilder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Simple stagger for fast, natural appearance (iOS-inspired)
    final int staggerDelay = math.min(widget.index * 20, 120);

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(
      begin: 0.98,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: staggerDelay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
      ),
    );
  }
}

// Add this class before the NetworkAwareWidget class
// Smooth scroll behavior for better scrolling experience
class SmoothScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Only show scrollbars on web platform
    if (kIsWeb) {
      switch (axisDirectionToAxis(details.direction)) {
        case Axis.vertical:
          return CupertinoScrollbar(
            // Fade-out scrollbar for web
            thumbVisibility: false,
            thickness: 6.0,
            thicknessWhileDragging: 8.0,
            radius: const Radius.circular(3.0),
            radiusWhileDragging: const Radius.circular(4.0),
            child: child,
          );
        default:
          return child;
      }
    } else {
      // Don't show scrollbars on mobile/desktop
      return child;
    }
  }
}

// Dynamic glow effect widget using palette_generator
class _DynamicGlow extends StatefulWidget {
  final ImageProvider imageProvider;
  final Widget child;
  final double size;
  final Color defaultGlowColor; // This is the ultimate fallback
  final Color?
      preferredGlowColor; // If provided, use this and skip PaletteGenerator

  const _DynamicGlow({
    super.key,
    required this.imageProvider,
    required this.child,
    required this.size,
    required this.defaultGlowColor,
    this.preferredGlowColor, // New parameter
  });
  @override
  State<_DynamicGlow> createState() => _DynamicGlowState();
}

class _DynamicGlowState extends State<_DynamicGlow> {
  Color? _glowColor;

  @override
  void initState() {
    super.initState();
    if (widget.preferredGlowColor != null) {
      // If preferred color exists
      _glowColor = widget.preferredGlowColor;
    } else {
      // Otherwise, initialize with default and try to generate from image
      _glowColor = widget.defaultGlowColor;
      _initPalette();
    }
  }

  Future<void> _initPalette() async {
    // Only called if preferredGlowColor is null
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        widget.imageProvider,
        size: const Size(50, 50), // Resize for faster palette generation
      );
      final color = palette.dominantColor?.color;
      if (mounted && color != null) {
        // Only update if a dominant color was found
        setState(() {
          _glowColor = color;
        });
      }
      // If color is null, _glowColor remains widget.defaultGlowColor (which was set in initState)
    } catch (_) {
      // On error, _glowColor remains widget.defaultGlowColor (set in initState)
      // Optionally log the error: print("PaletteGenerator failed: $_");
    }
  }

  @override
  Widget build(BuildContext context) {
    final glow = _glowColor ?? widget.defaultGlowColor;
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: glow.withOpacity(0.5),
            blurRadius: 60,
            spreadRadius: 6,
          ),
        ],
      ),
      child: widget.child,
    );
  }
}
// end dynamic glow

// Provider to map crypto symbols to bundled asset icon paths
final localCryptoIconProvider = FutureProvider<Map<String, String>>((
  ref,
) async {
  final manifestStr = await rootBundle.loadString('AssetManifest.json');
  final manifestMap = json.decode(manifestStr) as Map<String, dynamic>;
  final regex = RegExp(r"\(([^)]+)\)");
  final map = <String, String>{};
  for (final path in manifestMap.keys) {
    if (path.startsWith('assets/icons/crypto/')) {
      final file = path.split('/').last;
      final match = regex.firstMatch(file);
      if (match != null) {
        map[match.group(1)!.toLowerCase()] = path;
      }
    }
  }
  return map;
});

// Define manual crypto icon mapping constant at top level before AssetCard
// Manually map cryptos to their asset icons by name
const Map<String, CryptoIconInfo> _cryptoIconMap = {
  'bitcoin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/btc.svg',
    color: Color(0xFFF7931A), // Orange/gold for Bitcoin
  ),
  'ethereum': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Ethereum.svg',
    color: Color(0xFF627EEA), // Blue/purple for Ethereum
  ),
  'tether': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Tether.svg',
    color: Color(0xFF50AF95), // Teal for Tether
  ),
  'xrp': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/ripple.svg',
    color: Color(0xFF00AEEF), // Blue for Ripple
  ),
  'binance coin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Binance Coin (BNB).svg',
    color: Color(0xFFF0B90B), // Gold/yellow for Binance Coin
  ),
  'usd coin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/usd.svg',
    color: Color(0xFF2775CA), // Blue for USD Coin
  ),
  'dogecoin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Dogecoin (DOGE).svg',
    color: Color(0xFFCB9800), // Gold for Dogecoin
  ),
  'cardano': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Cardano.svg',
    color: Color(0xFF00AD99), // Teal for Cardano
  ),
  'litecoin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/lite.svg',
    color: Color(0xFFBEBEBE), // Silver for Litecoin
  ),
  'monero': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Monero.svg',
    color: Color(0xFFFF6600), // Orange for Monero
  ),
  'ethereum classic': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Ethereum Classic (ETH).svg',
    color: Color(0xFF325832), // Green for Ethereum Classic
  ),
  'stellar': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Stellar.svg',
    color: Color(0xFF00ADEF), // Blue for Stellar
  ),
  'bitcoin cash': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Bitcoin Cash.svg',
    color: Color(0xFF8DC351), // Green for Bitcoin Cash
  ),
  'litecoin cash': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Litecoin Cash (LCC).svg',
    color: Color(0xFF19191A), // Silver like Litecoin
  ),
  'nem': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/NEM (XEM).svg',
    color: Color(0xFF4FC8AE), // Teal for NEM
  ),
  'nano': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/nano (NANO).svg',
    color: Color(0xFF4A90E2), // Blue for Nano
  ),
  'tezos': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Tezos (XTZ).svg',
    color: Color(0xFFED3D53), // Red/orange for Tezos
  ),
  'eos': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/EOS.svg',
    color: Color(0xFF19191A), // Black/dark gray for EOS
  ),
  'decred': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Decred (DCR).svg',
    color: Color(0xFF4772D6), // Blue/purple for Decred
  ),
  'vechain': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/VeChain (VET).svg',
    color: Color(0xFF1596D5), // Blue for VeChain
  ),
  'ontology': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Ontology (ONT).svg',
    color: Color(0xFF36A9AE), // Teal for Ontology
  ),
  'syscoin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Syscoin (SYS).svg',
    color: Color(0xFF0089BC), // Blue for Syscoin
  ),
  'digibyte': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/DigiByte (DGB).svg',
    color: Color(0xFF0074B4), // Blue for DigiByte
  ),
  'verge': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Verge (XVG).svg',
    color: Color(0xFF40CCEA), // Cyan for Verge
  ),
  'siacoin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Siacoin (SC).svg',
    color: Color(0xFF00CBA1), // Teal for Siacoin
  ),
  'namecoin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Namecoin (NMC).svg',
    color: Color(0xFF4FC8AE), // Teal for Namecoin
  ),
  'enjin coin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Enjin Coin (ENJ).svg',
    color: Color(0xFF6A7995), // Gray/blue for Enjin Coin
  ),
  'horizen': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Horizen (ZEN).svg',
    color: Color(0xFF2C84DF), // Blue for Horizen
  ),
  'waves': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Waves (WAVES).svg',
    color: Color(0xFF2F82DE), // Blue for Waves
  ),
  'nuls': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Nuls (NULS).svg',
    color: Color(0xFF7A6B83), // Purple/gray for NULS
  ),
  'dash': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/dash.svg',
    color: Color(0xFF008CE7), // Blue for Dash
  ),
  'wanchain': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Wanchain.svg',
    color: Color(0xFF266187), // Dark blue for Wanchain
  ),
  'zilliqa': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Zilliqa (ZIL).svg',
    color: Color(0xFF48C9B9), // Teal for Zilliqa
  ),
  'qtum': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Qtum (QTUM).svg',
    color: Color(0xFF00B8DC), // Blue for Qtum
  ),
  'basic attention token': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Basic Attention Token.svg',
    color: Color(0xFFFF5200), // Orange for BAT
  ),
  'neo': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/NEO.svg',
    color: Color(0xFF58B700), // Green for Neo
  ),
  'particl': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Particl (PART).svg',
    color: Color(0xFF50AF95), // Green for Particl
  ),
  'whitecoin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/WhiteCoin (XWC).svg',
    color: Color(0xFF231F20), // Black/navy for WhiteCoin
  ),
  'smartcash': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/SmartCash (SMART).svg',
    color: Color(0xFF1E6796), // Blue for SmartCash
  ),
  'steem': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Steem (STEEM).svg',
    color: Color(0xFF4682B4), // Blue for Steem
  ),
  'steem dollars': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Steem Dollars (SBD).svg',
    color: Color(0xFF4682B4), // Blue for Steem Dollars (same as Steem)
  ),
  'primecoin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Primecoin (XPM).svg',
    color: Color(0xFFF99D1C), // Orange for Primecoin
  ),
  'lbry credits': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/LBRY Credits (LBC).svg',
    color: Color(0xFF19191A), // Orange for LBRY
  ),
  'callisto network': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Callisto Network (CLO).svg',
    color: Color(0xFF51B06F), // Green for Callisto Network
  ),
  'cloakcoin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/CloakCoin (CLOAK).svg',
    color: Color(0xFF32343A), // Dark gray for CloakCoin
  ),
  'colossusxt': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/ColossusXT (COLX).svg',
    color: Color(0xFF700366), // Purple for ColossusXT
  ),
  'counterparty': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Counterparty (XCP).svg',
    color: Color(0xFFF05139), // Red for Counterparty
  ),
  'crown': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Crown (CRW).svg',
    color: Color(0xFF126343), // Dark green for Crown
  ),
  'dero': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Dero (DERO).svg',
    color: Color(0xFF00223B), // Dark blue for Dero
  ),
  'dent': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Dent (DENT).svg',
    color: Color(0xFF19191A), // Green for Dent
  ),
  'electroneum': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Electroneum (ETN).svg',
    color: Color(0xFF2180FF), // Blue for Electroneum
  ),
  'gamecredits': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/GameCredits (GAME).svg',
    color: Color(0xFF19191A), // Orange for GameCredits
  ),
  'golem': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Golem (GNT).svg',
    color: Color(0xFF001D38), // Dark blue for Golem
  ),
  'komodo': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Komodo (KMD).svg',
    color: Color(0xFF306560), // Dark green for Komodo
  ),
  'lisk': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Lisk (LSK).svg',
    color: Color(0xFF007FC3), // Blue for Lisk
  ),
  'monacoin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/MonaCoin (MONA).svg',
    color: Color(0xFF19191A), // Orange for MonaCoin
  ),
  'nimiq': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Nimiq (NIM).svg',
    color: Color(0xFF267BF2), // Blue for Nimiq
  ),
  'omisego': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/OmiseGO (OMG).svg',
    color: Color(0xFF1A53F0), // Blue for OmiseGO
  ),
  'pascal coin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Pascal Coin (PASC).svg',
    color: Color(0xFFF09033), // Orange for Pascal Coin
  ),
  'peercoin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Peercoin (PPC).svg',
    color: Color(0xFF3EB049), // Green for Peercoin
  ),
  'pivx': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/PIVX (PIVX).svg',
    color: Color(0xFF4C2757), // Purple for PIVX
  ),
  'power ledger': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Power Ledger (POWR).svg',
    color: Color(0xFF65AE65), // Green for Power Ledger
  ),
  'prizm': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/PRIZM (PZM).svg',
    color: Color(0xFF47C2F0), // Cyan for PRIZM
  ),
  'quarkchain': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/QuarkChain (QKC).svg',
    color: Color(0xFF0C193C), // Dark blue for QuarkChain
  ),
  'trueusd': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/TrueUSD (TUSD).svg',
    color: Color(0xFF50AF95), // Teal for TrueUSD
  ),
  'vertcoin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Vertcoin (VTC).svg',
    color: Color(0xFF046B2D), // Green for Vertcoin
  ),
  'xtrabytes': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/XTRABYTES (XBY).svg',
    color: Color(0xFF00B0FF), // Blue for XTRABYTES
  ),
  'zclassic': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/ZClassic (ZCL).svg',
    color: Color(0xFF423C32), // Dark brown for ZClassic
  ),
  'aelf': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Baelf (ELF).svg',
    color: Color(0xFF305B9C), // Blue for aelf
  ),
  'bytecoin': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/Bytecoin (BCN).svg',
    color: Color(0xFF402660), // Purple for Bytecoin
  ),
  'zcash': CryptoIconInfo(
    iconPath: 'assets/icons/crypto/zec.svg',
    color: Color(0xFFF3BA2F), // Yellow/gold for Zcash
  ),
};

// Add a custom title widget that handles the sequential animation
// Custom title widget for smooth language transition
class TitleWithLanguageTransition extends StatefulWidget {
  final String title;
  final bool isRTL;

  const TitleWithLanguageTransition({
    super.key,
    required this.title,
    required this.isRTL,
  });

  @override
  State<TitleWithLanguageTransition> createState() =>
      _TitleWithLanguageTransitionState();
}

class _TitleWithLanguageTransitionState
    extends State<TitleWithLanguageTransition>
    with SingleTickerProviderStateMixin {
  String _lastTitle = '';
  String _currentTitle = '';
  bool _isAnimating = false;
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.title;
    _lastTitle = widget.title;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(widget.isRTL ? -1.5 : 1.5, 0),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutQuart),
    );
    _controller.addStatusListener(_handleAnimationStatus);
  }

  @override
  void didUpdateWidget(TitleWithLanguageTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.title != _currentTitle && !_isAnimating) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    if (_controller.isAnimating) return;

    setState(() {
      _lastTitle = _currentTitle;
      _isAnimating = true;
    });

    // Update slide direction based on RTL/LTR
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(widget.isRTL ? 1.5 : -1.5, 0),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutQuart),
    );

    _controller.forward(from: 0.0);
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _currentTitle = widget.title;
        _isAnimating = false;
      });
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_isAnimating)
          SlideTransition(
            position: _slideAnimation,
            child: Text(
              _lastTitle,
              style: TextStyle(
                fontFamily: widget.isRTL ? 'Vazirmatn' : 'SF-Pro',
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (!_isAnimating)
          SlideTransition(
            position: Tween<Offset>(
              begin: Offset(widget.isRTL ? -1.5 : 1.5, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: ReverseAnimation(_controller),
                curve: Curves.easeInOutQuart,
              ),
            ),
            child: Text(
              _currentTitle,
              style: TextStyle(
                fontFamily: widget.isRTL ? 'Vazirmatn' : 'SF-Pro',
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// --- Terms & Conditions Provider ---
class TermsData extends Equatable {
  final String title;
  final String content;
  final String lastUpdated;

  const TermsData({
    required this.title,
    required this.content,
    required this.lastUpdated,
  });

  factory TermsData.fromJson(Map<String, dynamic> json) {
    return TermsData(
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      lastUpdated: json['last_updated'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [title, content, lastUpdated];
}

final termsProvider = FutureProvider.autoDispose.family<TermsData, String>((
  ref,
  languageCode,
) async {
  final dio = ref.watch(dioProvider);
  final appConfig = await ref.watch(appConfigProvider.future);
  final isPersian = languageCode == 'fa';

  final remoteUrl = isPersian
      ? appConfig.apiEndpoints.termsFaUrl
      : appConfig.apiEndpoints.termsEnUrl;
  final localAssetPath =
      isPersian ? 'assets/config/terms_fa.json' : 'assets/config/terms_en.json';

  try {
    if (remoteUrl.isNotEmpty) {
      final response = await dio.get(remoteUrl);
      if (response.statusCode == 200 && response.data is Map) {
        return TermsData.fromJson(response.data as Map<String, dynamic>);
      }
    }
    // Fallback to local if remote fails or URL is empty
    final localConfigString = await rootBundle.loadString(localAssetPath);
    final localConfigJson = jsonDecode(localConfigString)
        as Map<String, dynamic>; // Fixed typo here
    return TermsData.fromJson(localConfigJson);
  } catch (e) {
    // Fallback to local if any error occurs
    try {
      final localConfigString = await rootBundle.loadString(localAssetPath);
      final localConfigJson =
          jsonDecode(localConfigString) as Map<String, dynamic>;
      return TermsData.fromJson(localConfigJson);
    } catch (localError) {
      // If local also fails, provide a default error message
      return TermsData(
        title: isPersian ? 'خطا' : 'Error',
        content: isPersian
            ? 'قادر به بارگیری قوانین و مقررات نیستیم.'
            : 'Could not load terms and conditions.',
        lastUpdated: '',
      );
    }
  }
});

// Screen to display Terms and Conditions
class TermsAndConditionsScreen extends ConsumerWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeNotifierProvider);
    final termsAsyncValue = ref.watch(termsProvider(locale.languageCode));
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isFa = locale.languageCode == 'fa';
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;
    final fadedTextColor = isDarkMode ? Colors.grey[500] : Colors.grey[500];
    final chevronColor = isDarkMode ? Colors.grey[600] : Colors.grey[400];

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: termsAsyncValue.when(
          data: (terms) => Stack(
            children: [
              // Main content (header + scrollable terms)
              Column(
                children: [
                  // Header
                  SizedBox(
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Back icon
                        Align(
                          alignment: isFa
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.of(context).pop(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Icon(
                                isFa
                                    ? CupertinoIcons.chevron_right
                                    : CupertinoIcons.chevron_left,
                                size: 20,
                                color: fadedTextColor,
                              ),
                            ),
                          ),
                        ),
                        // Centered title
                        Center(
                          child: Text(
                            terms.title,
                            style: TextStyle(
                              fontFamily: isFa ? 'Vazirmatn' : 'SF-Pro',
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Spacing between title and content
                  const SizedBox(height: 22),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            terms.content,
                            style: TextStyle(
                              fontFamily: isFa ? 'Vazirmatn' : 'SF-Pro',
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              height: 1.8,
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.92)
                                  : Colors.black87,
                            ),
                            textAlign: isFa ? TextAlign.right : TextAlign.left,
                            textDirection: isFa
                                ? ui.TextDirection.rtl
                                : ui.TextDirection.ltr,
                          ),
                          if (terms.lastUpdated.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 16,
                                bottom: 16,
                              ),
                              child: Center(
                                child: Text(
                                  isFa
                                      ? 'بروزرسانی شده در: ${terms.lastUpdated}'
                                      : 'Last updated: ${terms.lastUpdated}',
                                  style: TextStyle(
                                    fontFamily: isFa ? 'Vazirmatn' : 'SF-Pro',
                                    fontSize: 12,
                                    color: fadedTextColor,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, stack) => Center(
            child: Text(
              isFa ? 'خطا در بارگیری قوانین.' : 'Error loading terms.',
              style: TextStyle(
                fontFamily: isFa ? 'Vazirmatn' : 'SF-Pro',
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
