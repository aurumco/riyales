import 'package:flutter/widgets.dart'; // For Locale, Localizations, LocalizationsDelegate

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
        // 'settingsUpdateAvailable': 'برنامه جدید', // Removed older duplicate
        // 'settingsTerms': 'شرایط و ضوابط', // Removed older duplicate
        // 'settingsAppVersion': 'ورژن برنامه', // Removed older duplicate
        'settingsCardCorner': 'زاویه گرد کردن کارت',
        'settingsCardRadius': 'شعاع کارت',
        'settingsCardSmoothness': 'صافی کارت',
        'settingsCardPreview': 'پیش نمایش کارت',
        'settingsTerms': 'قوانین و مقررات', // Kept later definition
        'settingsAppVersion': 'نسخه برنامه', // Kept later definition
        'settingsUpdateAvailable': 'بروزرسانی موجود است', // Kept later definition
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
        // Added missing English localization for card settings
        'settingsCardCorner': 'Card Corner Style',
        'settingsCardRadius': 'Card Radius',
        'settingsCardSmoothness': 'Card Smoothness',
        'settingsCardPreview': 'Card Preview',
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
