// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get riyalesAppTitle => 'Riyales';

  @override
  String get tabCurrency => 'Currency';

  @override
  String get tabGold => 'Gold';

  @override
  String get tabCrypto => 'Crypto';

  @override
  String get tabStock => 'Stocks';

  @override
  String get stockTabSymbols => 'Symbols';

  @override
  String get stockTabDebtSecurities => 'Securities';

  @override
  String get stockTabFutures => 'Futures';

  @override
  String get stockTabHousingFacilities => 'Facilities';

  @override
  String get searchPlaceholder => 'Search...';

  @override
  String get listNoData => 'No data to display.';

  @override
  String get searchNoResults => 'No results found.';

  @override
  String get searchStartTyping => 'Start typing to search.';

  @override
  String get errorFetchingData => 'Error fetching data';

  @override
  String get retryButton => 'Retry';

  @override
  String get cardTapped => 'Card tapped';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTheme => 'Dark Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsLanguage => 'App Language';

  @override
  String get dialogClose => 'Close';

  @override
  String get settingsCurrencyUnit => 'Display Currency Unit';

  @override
  String get currencyUnitToman => 'Toman';

  @override
  String get currencyUnitUSD => 'Dollar';

  @override
  String get currencyUnitEUR => 'Euro';

  @override
  String get errorNoInternet => 'No Internet Connection';

  @override
  String get errorCheckConnection => 'Please check your internet connection.';

  @override
  String get errorServerUnavailable => 'Server Unavailable';

  @override
  String get errorServerMessage => 'Please try again later.';

  @override
  String get errorGeneric => 'Could not display data';

  @override
  String get retrying => 'Retrying automatically...';

  @override
  String get youreOffline => 'You\'re offline.';

  @override
  String get youreBackOnline => 'You\'re back online.';

  @override
  String get settingsTerms => 'Terms & Conditions';

  @override
  String get settingsAppVersion => 'App Version';

  @override
  String get settingsUpdateAvailable => 'Update Available';

  @override
  String get fallbackAppConfigMessage => 'App configuration is using fallback.';

  @override
  String get error_image_generation_or_sharing =>
      'Failed to generate or share card image.';

  @override
  String get card_image_saved_to_downloads =>
      'Card image saved to Downloads folder.';

  @override
  String get sortBy => 'Sort By';

  @override
  String get sortDefault => 'Default';

  @override
  String get sortHighestPrice => 'Highest Price';

  @override
  String get sortLowestPrice => 'Lowest Price';

  @override
  String get sortCancel => 'Cancel';

  @override
  String get easterEggMessageEn => 'By order of Aurum Co.';

  @override
  String get easterEggMessageFa => 'به دستور شرکت ارتباطات و راهکارهای مانا.';

  @override
  String get onboardingWhatsNew => 'What\'s New';

  @override
  String get onboardingIn => 'in';

  @override
  String get onboardingAppName => 'Riyales';

  @override
  String get onboardingQuickPin => 'Quick Pin';

  @override
  String get onboardingQuickPinDesc =>
      'Double-tap any asset card to pin or unpin it.';

  @override
  String get onboardingShareCard => 'Share Card';

  @override
  String get onboardingShareCardDesc =>
      'Long-press any asset card to share its image.';

  @override
  String get onboardingScrollToTop => 'Scroll to Top';

  @override
  String get onboardingScrollToTopDesc =>
      'Tap the active tab again to instantly scroll back to top.';

  @override
  String get onboardingQuickSettings => 'Quick Settings';

  @override
  String get onboardingQuickSettingsDesc =>
      'Tap the profile icon to adjust language, theme, and more.';

  @override
  String get onboardingTermsAccept =>
      'By using the app you accept the Terms of Service';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get termsErrorLoading => 'Error loading data.';

  @override
  String termsLastUpdated(String date) {
    return 'Last updated: $date';
  }

  @override
  String get supportEmailSubject => 'Support Request';

  @override
  String get supportEmailBody => 'Hello,\n\nPlease assist me with...';

  @override
  String get supportEmailSubjectFa => 'درخواست پشتیبانی';

  @override
  String get supportEmailBodyFa => 'سلام،\n\nلطفاً به من در مورد...';

  @override
  String get forceUpdateTitle => 'Mandatory Update';

  @override
  String get forceUpdateMessage =>
      'A new version of the app is required.\nThis version is no longer supported.';

  @override
  String get forceUpdateMarketBtn => 'Update from Market';

  @override
  String get forceUpdateSiteBtn => 'Update from Website';
}
