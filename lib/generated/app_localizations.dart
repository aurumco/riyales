import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fa')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Riyales'**
  String get riyalesAppTitle;

  /// Currency tab title
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get tabCurrency;

  /// Gold tab title
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get tabGold;

  /// Cryptocurrency tab title
  ///
  /// In en, this message translates to:
  /// **'Crypto'**
  String get tabCrypto;

  /// Stocks tab title
  ///
  /// In en, this message translates to:
  /// **'Stocks'**
  String get tabStock;

  /// Stock symbols tab title
  ///
  /// In en, this message translates to:
  /// **'Symbols'**
  String get stockTabSymbols;

  /// Debt securities tab title
  ///
  /// In en, this message translates to:
  /// **'Securities'**
  String get stockTabDebtSecurities;

  /// Futures tab title
  ///
  /// In en, this message translates to:
  /// **'Futures'**
  String get stockTabFutures;

  /// Housing facilities tab title
  ///
  /// In en, this message translates to:
  /// **'Facilities'**
  String get stockTabHousingFacilities;

  /// Placeholder text for search field
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchPlaceholder;

  /// Message shown when there is no data to display
  ///
  /// In en, this message translates to:
  /// **'No data to display.'**
  String get listNoData;

  /// Message shown when search returns no results
  ///
  /// In en, this message translates to:
  /// **'No results found.'**
  String get searchNoResults;

  /// Message shown when user should start typing to search
  ///
  /// In en, this message translates to:
  /// **'Start typing to search.'**
  String get searchStartTyping;

  /// Message shown when there is an error fetching data
  ///
  /// In en, this message translates to:
  /// **'Error fetching data'**
  String get errorFetchingData;

  /// Text for retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// Message shown when a card is tapped
  ///
  /// In en, this message translates to:
  /// **'Card tapped'**
  String get cardTapped;

  /// Title for settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Label for theme settings
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get settingsTheme;

  /// Label for light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Label for dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Label for language settings
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get settingsLanguage;

  /// Button text to close a dialog
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get dialogClose;

  /// Label for currency unit settings
  ///
  /// In en, this message translates to:
  /// **'Display Currency Unit'**
  String get settingsCurrencyUnit;

  /// Label for Toman currency unit
  ///
  /// In en, this message translates to:
  /// **'Toman'**
  String get currencyUnitToman;

  /// Label for USD currency unit
  ///
  /// In en, this message translates to:
  /// **'Dollar'**
  String get currencyUnitUSD;

  /// Label for Euro currency unit
  ///
  /// In en, this message translates to:
  /// **'Euro'**
  String get currencyUnitEUR;

  /// Message shown when there is no internet connection
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get errorNoInternet;

  /// Message asking user to check internet connection
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection.'**
  String get errorCheckConnection;

  /// Message shown when server is unavailable
  ///
  /// In en, this message translates to:
  /// **'Server Unavailable'**
  String get errorServerUnavailable;

  /// Message asking user to try again later
  ///
  /// In en, this message translates to:
  /// **'Please try again later.'**
  String get errorServerMessage;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Could not display data'**
  String get errorGeneric;

  /// Message shown when app is retrying an operation
  ///
  /// In en, this message translates to:
  /// **'Retrying automatically...'**
  String get retrying;

  /// Message shown when user is offline
  ///
  /// In en, this message translates to:
  /// **'You\'re offline.'**
  String get youreOffline;

  /// Message shown when user is back online
  ///
  /// In en, this message translates to:
  /// **'You\'re back online.'**
  String get youreBackOnline;

  /// Label for terms and conditions in settings
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get settingsTerms;

  /// Label for app version in settings
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get settingsAppVersion;

  /// Message shown when an update is available
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get settingsUpdateAvailable;

  /// Message shown when the app is using the fallback configuration (e.g., failed to load remote config).
  ///
  /// In en, this message translates to:
  /// **'App configuration is using fallback.'**
  String get fallbackAppConfigMessage;

  /// Error message shown when card image generation or sharing fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate or share card image.'**
  String get error_image_generation_or_sharing;

  /// Message shown when a card image is successfully saved to the Downloads folder.
  ///
  /// In en, this message translates to:
  /// **'Card image saved to Downloads folder.'**
  String get card_image_saved_to_downloads;

  /// Title for the sort options dialog.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// Label for the default sort option.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get sortDefault;

  /// Label for the highest price sort option.
  ///
  /// In en, this message translates to:
  /// **'Highest Price'**
  String get sortHighestPrice;

  /// Label for the lowest price sort option.
  ///
  /// In en, this message translates to:
  /// **'Lowest Price'**
  String get sortLowestPrice;

  /// Label for the cancel button in the sort dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get sortCancel;

  /// Easter egg message shown in English when the app title is tapped multiple times.
  ///
  /// In en, this message translates to:
  /// **'By order of Aurum Co.'**
  String get easterEggMessageEn;

  /// Easter egg message shown in Farsi when the app title is tapped multiple times.
  ///
  /// In en, this message translates to:
  /// **'به دستور شرکت ارتباطات و راهکارهای مانا.'**
  String get easterEggMessageFa;

  /// Onboarding: Title for what's new section.
  ///
  /// In en, this message translates to:
  /// **'What\'s New'**
  String get onboardingWhatsNew;

  /// Onboarding: 'in' for 'What's New in Riyales'.
  ///
  /// In en, this message translates to:
  /// **'in'**
  String get onboardingIn;

  /// Onboarding: App name for title.
  ///
  /// In en, this message translates to:
  /// **'Riyales'**
  String get onboardingAppName;

  /// Onboarding: Quick Pin feature title.
  ///
  /// In en, this message translates to:
  /// **'Quick Pin'**
  String get onboardingQuickPin;

  /// Onboarding: Quick Pin feature description.
  ///
  /// In en, this message translates to:
  /// **'Double-tap any asset card to pin or unpin it.'**
  String get onboardingQuickPinDesc;

  /// Onboarding: Share Card feature title.
  ///
  /// In en, this message translates to:
  /// **'Share Card'**
  String get onboardingShareCard;

  /// Onboarding: Share Card feature description.
  ///
  /// In en, this message translates to:
  /// **'Long-press any asset card to share its image.'**
  String get onboardingShareCardDesc;

  /// Onboarding: Scroll to Top feature title.
  ///
  /// In en, this message translates to:
  /// **'Scroll to Top'**
  String get onboardingScrollToTop;

  /// Onboarding: Scroll to Top feature description.
  ///
  /// In en, this message translates to:
  /// **'Tap the active tab again to instantly scroll back to top.'**
  String get onboardingScrollToTopDesc;

  /// Onboarding: Quick Settings feature title.
  ///
  /// In en, this message translates to:
  /// **'Quick Settings'**
  String get onboardingQuickSettings;

  /// Onboarding: Quick Settings feature description.
  ///
  /// In en, this message translates to:
  /// **'Tap the profile icon to adjust language, theme, and more.'**
  String get onboardingQuickSettingsDesc;

  /// Onboarding: Terms acceptance text.
  ///
  /// In en, this message translates to:
  /// **'By using the app you accept the Terms of Service'**
  String get onboardingTermsAccept;

  /// Onboarding: Continue button label.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// Terms screen: Error message when loading fails.
  ///
  /// In en, this message translates to:
  /// **'Error loading data.'**
  String get termsErrorLoading;

  /// Terms screen: Last updated label. {date} is the date string.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String termsLastUpdated(String date);

  /// Subject for support email in English.
  ///
  /// In en, this message translates to:
  /// **'Support Request'**
  String get supportEmailSubject;

  /// Body for support email in English.
  ///
  /// In en, this message translates to:
  /// **'Hello,\n\nPlease assist me with...'**
  String get supportEmailBody;

  /// Subject for support email in Farsi.
  ///
  /// In en, this message translates to:
  /// **'درخواست پشتیبانی'**
  String get supportEmailSubjectFa;

  /// Body for support email in Farsi.
  ///
  /// In en, this message translates to:
  /// **'سلام،\n\nلطفاً به من در مورد...'**
  String get supportEmailBodyFa;

  /// Title for the force update screen.
  ///
  /// In en, this message translates to:
  /// **'Mandatory Update'**
  String get forceUpdateTitle;

  /// Message for the force update screen.
  ///
  /// In en, this message translates to:
  /// **'A new version of the app is required.\nThis version is no longer supported.'**
  String get forceUpdateMessage;

  /// Button label for updating from market.
  ///
  /// In en, this message translates to:
  /// **'Update from Market'**
  String get forceUpdateMarketBtn;

  /// Button label for updating from website.
  ///
  /// In en, this message translates to:
  /// **'Update from Website'**
  String get forceUpdateSiteBtn;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
