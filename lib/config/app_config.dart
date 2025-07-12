import 'package:equatable/equatable.dart';

/// Application configuration and endpoints parsed from JSON.
class AppConfig extends Equatable {
  /// The application name displayed in the UI and metadata.
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
  final UpdateInfoConfig updateInfo;
  final List<String> priorityCurrency;
  final List<String> priorityGold;
  final List<String> priorityCrypto;
  final List<String> priorityCommodity;

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
    required this.updateInfo,
    required this.priorityCurrency,
    required this.priorityGold,
    required this.priorityCrypto,
    required this.priorityCommodity,
  });

  /// Parses JSON and merges top-level `app_version` into update info if provided.
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
      supportedLocales: ['en', 'fa'],
      defaultLocale: 'fa',
      themeOptions: ThemeOptions.defaultOptions(),
      fonts: FontsConfig.defaultFonts(),
      splashScreen: SplashScreenConfig.defaultConfig(),
      itemsPerLazyLoad: 24,
      initialItemsToLoad: 24,
      cryptoIconFilter: CryptoIconFilterConfig.defaultConfig(),
      featureFlags: FeatureFlags.defaultConfig(),
      updateInfo: UpdateInfoConfig.fromJson(updateMap),
      priorityCurrency:
          List<String>.from(json['priority_currency'] as List<dynamic>? ?? []),
      priorityGold:
          List<String>.from(json['priority_gold'] as List<dynamic>? ?? []),
      priorityCrypto:
          List<String>.from(json['priority_crypto'] as List<dynamic>? ?? []),
      priorityCommodity:
          List<String>.from(json['priority_commodity'] as List<dynamic>? ?? []),
    );
  }

  /// Returns a default fallback AppConfig with hardcoded values.
  factory AppConfig.defaultConfig() {
    // Priority lists default to empty; they are populated at runtime from priority_assets.json.
    return AppConfig.fromJson(const {
      "app_name": "Riyales",
      "remote_config_url":
          "https://raw.githubusercontent.com/aurumco/riyales-api/refs/heads/main/api/v1/config/app_config.json",
      "api_endpoints": {
        "currency_url":
            "https://raw.githubusercontent.com/aurumco/riyales-api/main/api/v2/market/currency.pb",
        "gold_url":
            "https://raw.githubusercontent.com/aurumco/riyales-api/main/api/v2/market/gold.pb",
        "commodity_url":
            "https://raw.githubusercontent.com/aurumco/riyales-api/main/api/v2/market/commodity.pb",
        "crypto_url":
            "https://raw.githubusercontent.com/aurumco/riyales-api/main/api/v2/market/cryptocurrency.pb",
        "stock_debt_securities_url":
            "https://raw.githubusercontent.com/aurumco/riyales-api/main/api/v2/market/stock/debt_securities.pb",
        "stock_futures_url":
            "https://raw.githubusercontent.com/aurumco/riyales-api/main/api/v2/market/stock/futures.pb",
        "stock_housing_facilities_url":
            "https://raw.githubusercontent.com/aurumco/riyales-api/main/api/v2/market/stock/housing_facilities.pb",
        "stock_tse_ifb_symbols_url":
            "https://raw.githubusercontent.com/aurumco/riyales-api/main/api/v2/market/stock/tse_ifb_symbols.pb",
        "priority_assets_url":
            "https://raw.githubusercontent.com/aurumco/riyales-api/refs/heads/main/api/v1/config/priority_assets.json",
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
      "itemsPerLazyLoad": 24,
      "initialItemsToLoad": 24,
      "cryptoIconFilter": {
        "brightness": 0.0,
        "contrast": 0.0,
        "saturation": -0.2,
      },
      "feature_flags": {"enable_chat": false, "enable_notifications": true},
      "update_info": {
        "latest_version": "0.0.0",
        "update_url": "https://dl.ryls.ir/",
        "changelog_en": "Initial release.",
        "changelog_fa": "نسخه اولیه.",
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
        updateInfo,
        priorityCurrency,
        priorityGold,
        priorityCrypto,
        priorityCommodity,
      ];

  /// Returns a copy of this config updating priority asset lists.
  AppConfig copyWithPriorityAssets({
    List<String>? priorityCurrency,
    List<String>? priorityGold,
    List<String>? priorityCrypto,
    List<String>? priorityCommodity,
  }) {
    return AppConfig(
      appName: appName,
      remoteConfigUrl: remoteConfigUrl,
      apiEndpoints: apiEndpoints,
      priceUpdateIntervalMinutes: priceUpdateIntervalMinutes,
      updateIntervalMs: updateIntervalMs,
      supportedLocales: supportedLocales,
      defaultLocale: defaultLocale,
      themeOptions: themeOptions,
      fonts: fonts,
      splashScreen: splashScreen,
      itemsPerLazyLoad: itemsPerLazyLoad,
      initialItemsToLoad: initialItemsToLoad,
      cryptoIconFilter: cryptoIconFilter,
      featureFlags: featureFlags,
      updateInfo: updateInfo,
      priorityCurrency: priorityCurrency ?? this.priorityCurrency,
      priorityGold: priorityGold ?? this.priorityGold,
      priorityCrypto: priorityCrypto ?? this.priorityCrypto,
      priorityCommodity: priorityCommodity ?? this.priorityCommodity,
    );
  }
}

/// API endpoints for market data and configuration resources.
/// Ensures URLs are converted to protobuf endpoints when applicable.
///
/// Parsed from JSON in AppConfig.fromJson.
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

  /// URL for English terms and conditions JSON.
  final String termsEnUrl;

  /// URL for Persian terms and conditions JSON.
  final String termsFaUrl;

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
    required this.termsEnUrl,
    required this.termsFaUrl,
  });

  factory ApiEndpoints.fromJson(Map<String, dynamic> json) {
    String toPbUrlForce(String url) {
      if (url.isEmpty) return url;
      if (url.toLowerCase().endsWith('.pb')) return url;
      url = url.replaceFirst('/api/v1/', '/api/v2/');
      url = url.replaceFirst('.json', '.pb');
      url = url.replaceFirst('github.com/', 'raw.githubusercontent.com/');
      url = url.replaceFirst('/raw/refs/heads/', '/');
      return url;
    }

    return ApiEndpoints(
      currencyUrl: toPbUrlForce(json['currency_url'] as String? ?? ''),
      goldUrl: toPbUrlForce(json['gold_url'] as String? ?? ''),
      commodityUrl: toPbUrlForce(json['commodity_url'] as String? ?? ''),
      cryptoUrl: toPbUrlForce(json['crypto_url'] as String? ?? ''),
      stockDebtSecuritiesUrl:
          toPbUrlForce(json['stock_debt_securities_url'] as String? ?? ''),
      stockFuturesUrl: toPbUrlForce(json['stock_futures_url'] as String? ?? ''),
      stockHousingFacilitiesUrl:
          toPbUrlForce(json['stock_housing_facilities_url'] as String? ?? ''),
      stockTseIfbSymbolsUrl:
          toPbUrlForce(json['stock_tse_ifb_symbols_url'] as String? ?? ''),
      priorityAssetsUrl: json['priority_assets_url'] as String? ?? '',
      termsEnUrl: json['terms_en_url'] as String? ?? '',
      termsFaUrl: json['terms_fa_url'] as String? ?? '',
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
        termsEnUrl,
        termsFaUrl,
      ];
}

/// Theme configuration for light and dark modes.
class ThemeOptions extends Equatable {
  final String defaultTheme;
  final ThemeConfig light;
  final ThemeConfig dark;

  const ThemeOptions({
    required this.defaultTheme,
    required this.light,
    required this.dark,
  });

  factory ThemeOptions.defaultOptions() {
    return ThemeOptions(
      defaultTheme: 'dark',
      light: ThemeConfig.fromJson(const {
        "brightness": "light",
        "primaryColor": "#FFFFFF",
        "backgroundColor": "#F2F2F7",
        "scaffoldBackgroundColor": "#F2F2F7",
        "appBarColor": "#F2F2F7",
        "cardColor": "#FFFFFF",
        "textColor": "#000000",
        "secondaryTextColor": "#8E8E93",
        "accentColorGreen": "#00C851",
        "accentColorRed": "#FF4444",
        "cardBorderRadius": 21.0,
        "shadowColor": "#000000",
        "cardCornerSmoothness": 0.90
      }),
      dark: ThemeConfig.fromJson(const {
        "brightness": "dark",
        "primaryColor": "#1C1C1E",
        "backgroundColor": "#1C1C1E",
        "scaffoldBackgroundColor": "#1C1C1E",
        "appBarColor": "#1C1C1E",
        "cardColor": "#2C2C2E",
        "textColor": "#E5E5EA",
        "secondaryTextColor": "#8E8E93",
        "accentColorGreen": "#00E676",
        "accentColorRed": "#FF5252",
        "cardBorderRadius": 21.0,
        "shadowColor": "#000000",
        "backgroundGradientColors": ["#1C1C1E", "#2C2C2E"],
        "cardCornerSmoothness": 0.90
      }),
    );
  }

  @override
  List<Object?> get props => [defaultTheme, light, dark];
}

/// Configuration for individual theme properties, such as colors and radii.
/// Supports optional gradient backgrounds and squircle smoothness.
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

  /// Controls the squircle corner smoothness (0 = square, 1 = circle).
  final double cardCornerSmoothness;

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
    this.cardCornerSmoothness = 0.7,
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

/// Configuration for default Persian and English font families.
class FontsConfig extends Equatable {
  final String persianFontFamily;
  final String englishFontFamily;

  const FontsConfig({
    required this.persianFontFamily,
    required this.englishFontFamily,
  });

  factory FontsConfig.defaultFonts() {
    return FontsConfig(
      persianFontFamily: 'Vazirmatn',
      englishFontFamily: 'SF-Pro',
    );
  }
  @override
  List<Object?> get props => [persianFontFamily, englishFontFamily];
}

/// Configuration for splash screen duration, icon, and indicator color.
class SplashScreenConfig extends Equatable {
  final double durationSeconds;
  final String iconPath;
  final String loadingIndicatorColor;

  const SplashScreenConfig({
    required this.durationSeconds,
    required this.iconPath,
    required this.loadingIndicatorColor,
  });

  factory SplashScreenConfig.defaultConfig() {
    return SplashScreenConfig(
      durationSeconds: 1.5,
      iconPath: 'assets/images/splash-screen-light.svg',
      loadingIndicatorColor: '#FBC02D',
    );
  }
  @override
  List<Object?> get props => [durationSeconds, iconPath, loadingIndicatorColor];
}

/// Filter settings for cryptocurrency icons (brightness, contrast, saturation).
class CryptoIconFilterConfig extends Equatable {
  final double brightness;
  final double contrast;
  final double saturation;

  const CryptoIconFilterConfig({
    required this.brightness,
    required this.contrast,
    required this.saturation,
  });

  factory CryptoIconFilterConfig.defaultConfig() {
    return CryptoIconFilterConfig(
      brightness: 0.0,
      contrast: 0.0,
      saturation: -0.2,
    );
  }
  @override
  List<Object?> get props => [brightness, contrast, saturation];
}

/// Toggles for enabling or disabling optional application features.
class FeatureFlags extends Equatable {
  final bool enableChat;
  final bool enableNotifications;

  const FeatureFlags({
    required this.enableChat,
    required this.enableNotifications,
  });

  factory FeatureFlags.defaultConfig() {
    return FeatureFlags(
      enableChat: false,
      enableNotifications: true,
    );
  }
  @override
  List<Object?> get props => [enableChat, enableNotifications];
}

/// Configuration for application update information and URLs.
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
