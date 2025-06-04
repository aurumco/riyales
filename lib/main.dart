import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

// Configs
import './config/app_config.dart'; // For AppConfig type
import './providers/app_config_provider.dart'; // For fetchAppConfig function

// UI Theme
import './ui/theme/app_theme.dart' as ui_theme_pkg;
import './ui/theme/smooth_scroll_behavior.dart'; // Direct import for SmoothScrollBehavior

// Screens
import './ui/screens/splash_screen.dart';

// Providers
import './providers/theme_provider.dart';
import './providers/locale_provider.dart';
import './providers/search_provider.dart';
import './providers/currency_unit_provider.dart';
import './providers/favorites_provider.dart';
import './providers/card_corner_settings_provider.dart';
import './providers/terms_provider.dart';
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
import './localization/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        FutureProvider<AppConfig>(
          create: (_) => fetchAppConfig(),
          initialData: AppConfig.defaultConfig(),
          catchError: (context, error) {
            // Consider logging error to a service
            // print('Critical Error: AppConfig FutureProvider failed: $error');
            return AppConfig.defaultConfig();
          },
        ),
        ChangeNotifierProvider<ThemeNotifier>(
          create: (_) => ThemeNotifier(ThemeMode.system),
        ),
        ChangeNotifierProvider<LocaleNotifier>(
          create: (_) => LocaleNotifier(
              const Locale('en')), // Default, prefs will override
        ),
        ChangeNotifierProvider(create: (_) => SearchQueryNotifier()),
        ChangeNotifierProvider(create: (_) => CurrencyUnitNotifier()),
        ChangeNotifierProvider(create: (_) => FavoritesNotifier()),

        Provider<Dio>(create: (_) => Dio()),

        // ConnectionService provided via ProxyProvider, initialized once AppConfig is available
        ProxyProvider<AppConfig, ConnectionService>(
          update: (context, appConfig, previousConnectionService) {
            // Use a new instance or update existing. If ConnectionService has internal state
            // that should be preserved across AppConfig updates, this might need adjustment.
            // For now, creating a new one or re-initializing is fine.
            final cs =
                ConnectionService(); // It's a singleton, so this gets the instance
            if (appConfig.appName != "Riyales Default Fallback" &&
                appConfig.remoteConfigUrl.isNotEmpty) {
              // Check if it's not the default config before initializing
              cs.initialize(appConfig.apiEndpoints.currencyUrl);
            }
            return cs;
          },
          // dispose: (_, cs) => cs.dispose(), // Add if ConnectionService has a dispose method
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
    // AppConfig is watched by the parent MultiProvider's FutureProvider.
    // Here, we can assume it's loaded or using initialData (defaultConfig).
    final appConfig = context.watch<AppConfig>();

    // If AppConfig is the default/fallback because the future failed or is still loading with initialData,
    // we might want to show a specific UI. The FutureProvider's catchError handles one aspect of this.
    // Here, we check if it's still the default one to decide on a basic UI.
    if (appConfig.appName == AppConfig.defaultConfig().appName &&
        appConfig.remoteConfigUrl ==
            AppConfig.defaultConfig().remoteConfigUrl) {
      // This implies that the fetched config might not be ready or failed, and we are using the hardcoded default.
      // Depending on requirements, could show a loading/error or proceed with defaults.
      // For now, SplashScreen handles initial app appearance. If config is critical before that,
      // this check is one way to show a minimal holding screen.
      // Let's assume SplashScreen is okay with a default config.
    }

    final themeNotifier = context.watch<ThemeNotifier>();
    final localeNotifier = context.watch<LocaleNotifier>();

    final materialTheme = Theme.of(context); // Base theme
    final themeData = materialTheme.copyWith(
      // Global overrides
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );

    return Theme(
        data: themeData, // Apply global overrides
        child: MaterialApp(
          title: appConfig.appName,
          theme: ui_theme_pkg.AppTheme.getThemeData(
            appConfig.themeOptions.light,
            localeNotifier.locale.languageCode == 'fa'
                ? appConfig.fonts.persianFontFamily
                : appConfig.fonts.englishFontFamily,
            localeNotifier.locale.languageCode == 'fa'
                ? 'Vazirmatn'
                : 'Onest', // Title font
            false, // isDarkMode
          ),
          darkTheme: ui_theme_pkg.AppTheme.getThemeData(
            appConfig.themeOptions.dark,
            localeNotifier.locale.languageCode == 'fa'
                ? appConfig.fonts.persianFontFamily
                : appConfig.fonts.englishFontFamily,
            localeNotifier.locale.languageCode == 'fa'
                ? 'Vazirmatn'
                : 'Onest', // Title font
            true, // isDarkMode
          ),
          themeMode: themeNotifier.themeMode,
          locale: localeNotifier.locale,
          supportedLocales:
              appConfig.supportedLocales.map((loc) => Locale(loc)),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          debugShowCheckedModeBanner: false,
          home: SplashScreen(config: appConfig.splashScreen),
          builder: (context, child) {
            final animated = AnimatedTheme(
              data: Theme.of(context), // Ensures theme changes animate
              duration: const Duration(milliseconds: 30), // Faster transition
              curve: Curves.linear, // Smoother, consistent speed
              child: child!,
            );
            // Disable implicit animations for smoother UX in bottom sheets etc.
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: animated,
            );
          },
        ));
  }
}
