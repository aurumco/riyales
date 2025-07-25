// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get riyalesAppTitle => 'ریالِس';

  @override
  String get tabCurrency => 'ارز';

  @override
  String get tabGold => 'طلا';

  @override
  String get tabCrypto => 'کریپتو';

  @override
  String get tabStock => 'بورس';

  @override
  String get stockTabSymbols => 'نمادها';

  @override
  String get stockTabDebtSecurities => 'اوراق';

  @override
  String get stockTabFutures => 'آتی';

  @override
  String get stockTabHousingFacilities => 'تسهیلات';

  @override
  String get searchPlaceholder => 'جستجو...';

  @override
  String get listNoData => 'داده‌ای برای نمایش وجود ندارد.';

  @override
  String get searchNoResults => 'نتیجه‌ای یافت نشد.';

  @override
  String get searchStartTyping => 'برای جستجو تایپ کنید.';

  @override
  String get errorFetchingData => 'خطا در دریافت اطلاعات';

  @override
  String get retryButton => 'تلاش مجدد';

  @override
  String get cardTapped => 'کارت لمس شد';

  @override
  String get settingsTitle => 'تنظیمات';

  @override
  String get settingsTheme => 'پوسته تاریک';

  @override
  String get themeLight => 'روشن';

  @override
  String get themeDark => 'تاریک';

  @override
  String get settingsLanguage => 'زبان برنامه';

  @override
  String get dialogClose => 'بستن';

  @override
  String get settingsCurrencyUnit => 'واحد پول نمایش';

  @override
  String get currencyUnitToman => 'تومان';

  @override
  String get currencyUnitUSD => 'دلار';

  @override
  String get currencyUnitEUR => 'یورو';

  @override
  String get errorNoInternet => 'اتصال اینترنت برقرار نیست';

  @override
  String get errorCheckConnection => 'لطفاً اتصال اینترنت خود را بررسی کنید.';

  @override
  String get errorServerUnavailable => 'سرور در دسترس نیست.';

  @override
  String get errorServerMessage => 'لطفاً کمی بعد امتحان کنید.';

  @override
  String get errorGeneric => 'خطا در نمایش اطلاعات';

  @override
  String get retrying => 'در حال تلاش مجدد...';

  @override
  String get youreOffline => 'اتصال اینترنت قطع است.';

  @override
  String get youreBackOnline => 'اتصال به اینترنت برقرار شد.';

  @override
  String get settingsTerms => 'قوانین و مقررات';

  @override
  String get settingsAppVersion => 'نسخه برنامه';

  @override
  String get settingsUpdateAvailable => 'بروزرسانی موجود است';

  @override
  String get fallbackAppConfigMessage => 'پیکربندی برنامه در حالت پیش‌فرض است.';

  @override
  String get error_image_generation_or_sharing =>
      'خطا در تولید یا اشتراک‌گذاری تصویر کارت.';

  @override
  String get card_image_saved_to_downloads =>
      'تصویر کارت با موفقیت در پوشه Downloads ذخیره شد.';

  @override
  String get sortBy => 'مرتب‌سازی';

  @override
  String get sortDefault => 'پیشفرض';

  @override
  String get sortHighestPrice => 'بیشترین قیمت';

  @override
  String get sortLowestPrice => 'کمترین قیمت';

  @override
  String get sortCancel => 'انصراف';

  @override
  String get easterEggMessageEn => 'By order of Aurum Co.';

  @override
  String get easterEggMessageFa => 'به دستور شرکت ارتباطات و راهکارهای مانا.';

  @override
  String get onboardingWhatsNew => 'چه خبر';

  @override
  String get onboardingIn => 'در';

  @override
  String get onboardingAppName => 'ریالس';

  @override
  String get onboardingQuickPin => 'پین سریع';

  @override
  String get onboardingQuickPinDesc =>
      'فقط کافیست دو بار روی یک دارایی ضربه بزنید تا پین شود.';

  @override
  String get onboardingShareCard => 'اشتراک گذاری';

  @override
  String get onboardingShareCardDesc =>
      'با نگه داشتن انگشت خود بر روی یک دارایی، آن را به دوستانتان ارسال کنید.';

  @override
  String get onboardingScrollToTop => 'بازگشت به بالا';

  @override
  String get onboardingScrollToTopDesc =>
      'با یک ضربه روی تَب فعلی، لیست به ابتدای صفحه اسکرول می‌شود.';

  @override
  String get onboardingQuickSettings => 'تنظیمات سریع';

  @override
  String get onboardingQuickSettingsDesc =>
      'برای تغییر زبان، تم و سایر گزینه‌ها روی آیکون پروفایل بزنید.';

  @override
  String get onboardingTermsAccept =>
      'استفاده از اپلیکیشن به منزلهٔ پذیرش قوانین است';

  @override
  String get onboardingContinue => 'ادامه';

  @override
  String get termsErrorLoading => 'خطا در بارگیری اطلاعات.';

  @override
  String termsLastUpdated(String date) {
    return 'آخرین بروزرسانی: $date';
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
  String get forceUpdateTitle => 'بروزرسانی ضروری';

  @override
  String get forceUpdateMessage =>
      'برای استفاده از ریالِس باید نسخه جدید را نصب کنید.\nاین نسخه دیگر پشتیبانی نمی‌شود.';

  @override
  String get forceUpdateMarketBtn => 'بروزرسانی از مارکت';

  @override
  String get forceUpdateSiteBtn => 'بروزرسانی از سایت';
}
