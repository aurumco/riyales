import 'package:equatable/equatable.dart';

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
        "terms_en_url":
            "https://raw.githubusercontent.com/aurumco/riyales-api/refs/heads/main/api/v1/config/terms_en.json",
        "terms_fa_url":
            "https://raw.githubusercontent.com/aurumco/riyales-api/refs/heads/main/api/v1/config/terms_fa.json",
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
        "latest_version": "0.140.0", // Placeholder
        "update_url": "https://dl.ryls.ir/", // Placeholder
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

// _hexToColor function removed as it's unused in this file (moved to utils/color_utils.dart)
