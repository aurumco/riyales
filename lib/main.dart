import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

// App configuration
import './config/app_config.dart';
import './providers/app_config_provider.dart';

// UI theme utilities
import './ui/theme/app_theme.dart' as ui_theme_pkg;
import './ui/theme/smooth_scroll_behavior.dart';

// UI screens
import './ui/screens/splash_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:seo/seo.dart';
import 'package:url_strategy/url_strategy.dart';

// Providers
import './providers/theme_provider.dart';
import './providers/locale_provider.dart';
import './providers/search_provider.dart';
import './providers/currency_unit_provider.dart';
import './providers/favorites_provider.dart';
import './providers/card_corner_settings_provider.dart';
import './providers/terms_provider.dart';
import './providers/alert_provider.dart';
import './providers/data_providers/currency_data_provider.dart';
import './providers/data_providers/gold_data_provider.dart';
import './providers/data_providers/crypto_data_provider.dart';
import './providers/data_providers/stock_tse_ifb_data_provider.dart';
import './providers/data_providers/stock_debt_securities_data_provider.dart';
import './providers/data_providers/stock_futures_data_provider.dart';
import './providers/data_providers/stock_housing_facilities_data_provider.dart';

// Services
import './services/api_service.dart';
import './services/connection_service.dart';

// Localization
import './localization/l10n_utils.dart';

/// Determines the initial locale based on platform conventions.
Locale getInitialLocale() {
  final platform = defaultTargetPlatform;
  if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
    return const Locale('en');
  }
  return const Locale('fa');
}

/// Application entry point.
/// Initializes bindings and runs the app with required providers.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use path URL strategy for clean URLs (better SEO on web)
  if (kIsWeb) {
    setPathUrlStrategy();
  }

  // Make system status & navigation bars fully transparent at app launch
  // so that our UI can draw edge-to-edge immediately.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(
    MultiProvider(
      providers: [
        FutureProvider<AppConfig>(
          create: (_) => fetchAppConfig(),
          initialData: AppConfig.defaultConfig(),
          catchError: (_, __) => AppConfig.defaultConfig(),
        ),
        ChangeNotifierProvider<ThemeNotifier>(
          create: (_) => ThemeNotifier(ThemeMode.system),
        ),
        ChangeNotifierProvider<LocaleNotifier>(
          create: (_) => LocaleNotifier(getInitialLocale()),
        ),
        ChangeNotifierProvider(create: (_) => SearchQueryNotifier()),
        ChangeNotifierProvider(create: (_) => CurrencyUnitNotifier()),
        ChangeNotifierProvider(create: (_) => FavoritesNotifier()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),

        Provider<Dio>(create: (_) => Dio()),

        // ConnectionService provided via ProxyProvider, initialized once AppConfig is available
        ProxyProvider<AppConfig, ConnectionService>(
          update: (context, appConfig, previousConnectionService) {
            final cs = ConnectionService();
            if (appConfig.appName != "Riyales Default Fallback" &&
                appConfig.remoteConfigUrl.isNotEmpty) {
              cs.initialize(appConfig.apiEndpoints.currencyUrl);
            }
            return cs;
          },
          dispose: (_, cs) => cs.dispose(),
        ),

        ProxyProvider2<Dio, AppConfig, ApiService>(
          update: (context, dio, appConfig, previous) =>
              ApiService(dio, appConfig.apiEndpoints),
        ),

        ChangeNotifierProxyProvider<AppConfig, CardCornerSettingsNotifier>(
          create: (context) => CardCornerSettingsNotifier(
              Provider.of<AppConfig>(context, listen: false)),
          update: (context, appConfig, previousNotifier) =>
              CardCornerSettingsNotifier(appConfig),
        ),

        ChangeNotifierProxyProvider3<AppConfig, ApiService, ConnectionService,
            CurrencyDataNotifier>(
          create: (context) => CurrencyDataNotifier(
            appConfig: Provider.of<AppConfig>(context, listen: false),
            apiService: Provider.of<ApiService>(context, listen: false),
            connectionService:
                Provider.of<ConnectionService>(context, listen: false),
          ),
          update: (context, appConfig, apiService, connService, previous) =>
              CurrencyDataNotifier(
                  appConfig: appConfig,
                  apiService: apiService,
                  connectionService: connService),
        ),
        ChangeNotifierProxyProvider3<AppConfig, ApiService, ConnectionService,
            GoldDataNotifier>(
          create: (context) => GoldDataNotifier(
            appConfig: Provider.of<AppConfig>(context, listen: false),
            apiService: Provider.of<ApiService>(context, listen: false),
            connectionService:
                Provider.of<ConnectionService>(context, listen: false),
          ),
          update: (context, appConfig, apiService, connService, previous) =>
              GoldDataNotifier(
                  appConfig: appConfig,
                  apiService: apiService,
                  connectionService: connService),
        ),
        ChangeNotifierProxyProvider3<AppConfig, ApiService, ConnectionService,
            CryptoDataNotifier>(
          create: (context) => CryptoDataNotifier(
            appConfig: Provider.of<AppConfig>(context, listen: false),
            apiService: Provider.of<ApiService>(context, listen: false),
            connectionService:
                Provider.of<ConnectionService>(context, listen: false),
          ),
          update: (context, appConfig, apiService, connService, previous) =>
              CryptoDataNotifier(
                  appConfig: appConfig,
                  apiService: apiService,
                  connectionService: connService),
        ),
        ChangeNotifierProxyProvider3<AppConfig, ApiService, ConnectionService,
            StockTseIfbDataNotifier>(
          create: (context) => StockTseIfbDataNotifier(
            appConfig: Provider.of<AppConfig>(context, listen: false),
            apiService: Provider.of<ApiService>(context, listen: false),
            connectionService:
                Provider.of<ConnectionService>(context, listen: false),
          ),
          update: (context, appConfig, apiService, connService, previous) =>
              StockTseIfbDataNotifier(
                  appConfig: appConfig,
                  apiService: apiService,
                  connectionService: connService),
        ),
        ChangeNotifierProxyProvider3<AppConfig, ApiService, ConnectionService,
            StockDebtSecuritiesDataNotifier>(
          create: (context) => StockDebtSecuritiesDataNotifier(
            appConfig: Provider.of<AppConfig>(context, listen: false),
            apiService: Provider.of<ApiService>(context, listen: false),
            connectionService:
                Provider.of<ConnectionService>(context, listen: false),
          ),
          update: (context, appConfig, apiService, connService, previous) =>
              StockDebtSecuritiesDataNotifier(
                  appConfig: appConfig,
                  apiService: apiService,
                  connectionService: connService),
        ),
        ChangeNotifierProxyProvider3<AppConfig, ApiService, ConnectionService,
            StockFuturesDataNotifier>(
          create: (context) => StockFuturesDataNotifier(
            appConfig: Provider.of<AppConfig>(context, listen: false),
            apiService: Provider.of<ApiService>(context, listen: false),
            connectionService:
                Provider.of<ConnectionService>(context, listen: false),
          ),
          update: (context, appConfig, apiService, connService, previous) =>
              StockFuturesDataNotifier(
                  appConfig: appConfig,
                  apiService: apiService,
                  connectionService: connService),
        ),
        ChangeNotifierProxyProvider3<AppConfig, ApiService, ConnectionService,
            StockHousingFacilitiesDataNotifier>(
          create: (context) => StockHousingFacilitiesDataNotifier(
            appConfig: Provider.of<AppConfig>(context, listen: false),
            apiService: Provider.of<ApiService>(context, listen: false),
            connectionService:
                Provider.of<ConnectionService>(context, listen: false),
          ),
          update: (context, appConfig, apiService, connService, previous) =>
              StockHousingFacilitiesDataNotifier(
                  appConfig: appConfig,
                  apiService: apiService,
                  connectionService: connService),
        ),

        ChangeNotifierProxyProvider3<AppConfig, ApiService, LocaleNotifier,
            TermsNotifier>(
          create: (context) => TermsNotifier(
            appConfig: Provider.of<AppConfig>(context, listen: false),
            apiService: Provider.of<ApiService>(context, listen: false),
            languageCode: Provider.of<LocaleNotifier>(context, listen: false)
                .locale
                .languageCode,
          ),
          update: (context, appConfig, apiService, localeNotifier, previous) =>
              TermsNotifier(
            appConfig: appConfig,
            apiService: apiService,
            languageCode: localeNotifier.locale.languageCode,
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

class RiyalesApp extends StatelessWidget {
  const RiyalesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appConfig = context.watch<AppConfig>();

    final themeNotifier = context.watch<ThemeNotifier>();
    final localeNotifier = context.watch<LocaleNotifier>();

    final materialTheme = Theme.of(context);
    final themeData = materialTheme.copyWith(
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );

    final lightTheme = ui_theme_pkg.AppTheme.getThemeData(
      appConfig.themeOptions.light,
      localeNotifier.locale.languageCode == 'fa'
          ? appConfig.fonts.persianFontFamily
          : appConfig.fonts.englishFontFamily,
      localeNotifier.locale.languageCode == 'fa' ? 'Vazirmatn' : 'Onest',
      false,
    );

    final darkTheme = ui_theme_pkg.AppTheme.getThemeData(
      appConfig.themeOptions.dark,
      localeNotifier.locale.languageCode == 'fa'
          ? appConfig.fonts.persianFontFamily
          : appConfig.fonts.englishFontFamily,
      localeNotifier.locale.languageCode == 'fa' ? 'Vazirmatn' : 'Onest',
      true,
    );

    return Theme(
      data: themeData,
      child: SeoController(
        enabled: kIsWeb,
        tree: WidgetTree(context: context),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: appConfig.appName,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeNotifier.themeMode,
          locale: localeNotifier.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: SplashScreen(config: appConfig.splashScreen),
          builder: (context, child) {
            // Update status bar style based on current theme
            final isDark = Theme.of(context).brightness == Brightness.dark;
            SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
              statusBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
              systemNavigationBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
              statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            ));

            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: false),
              child: AnimatedTheme(
                data: Theme.of(context),
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOutQuart,
                child: child!,
              ),
            );
          },
        ),
      ),
    );
  }
}
