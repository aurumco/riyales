import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

import '../../config/app_config.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/currency_unit_provider.dart';
import '../../localization/l10n_utils.dart';
import '../screens/terms_screen.dart';
import '../../utils/color_utils.dart';
import '../../utils/helpers.dart';
import '../../utils/version_utils.dart';

/// Bottom sheet for app settings and configuration options
class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  bool _updateAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  /// Check if an update is available
  Future<void> _checkForUpdates() async {
    final appConfig = Provider.of<AppConfig>(context, listen: false);
    final remoteVersion = appConfig.updateInfo.latestVersion;
    final isUpdateAvailable =
        await VersionUtils().isUpdateAvailable(remoteVersion);

    if (mounted && isUpdateAvailable) {
      setState(() {
        _updateAvailable = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use context.select for specific values to optimize rebuilds
    final locale =
        context.select<LocaleNotifier, Locale>((notifier) => notifier.locale);
    final currencyUnit = context.select<CurrencyUnitNotifier, CurrencyUnit>(
        (notifier) => notifier.unit);
    final appConfig = context.watch<AppConfig>();
    final l10n = AppLocalizations.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Detect mobile web users
    final isMobileWeb = kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    // Get accent color for UI elements
    final tealGreen = hexToColor(
      isDarkMode
          ? appConfig.themeOptions.dark.accentColorGreen
          : appConfig.themeOptions.light.accentColorGreen,
    );

    // Chevron color for all dropdowns
    final chevronColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    const double chevronSize = 0.0;

    // Update button text
    String updateButtonText = l10n.settingsUpdateAvailable;

    return CupertinoTheme(
      data: CupertinoThemeData(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
      ),
      child: RepaintBoundary(
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
            _buildThemeToggle(context, locale, isDarkMode, l10n, tealGreen),

            // Language selector
            _buildLanguageSelector(
                context, locale, isDarkMode, l10n, appConfig, chevronColor),

            // Currency unit selector
            _buildCurrencyUnitSelector(
                context, locale, isDarkMode, l10n, currencyUnit, chevronColor),

            // Download App button for mobile web users
            if (isMobileWeb)
              _buildDownloadAppButton(
                  context, locale, isDarkMode, chevronColor, chevronSize),

            // Terms and Conditions Button
            _buildTermsButton(
                context, locale, isDarkMode, l10n, chevronColor, chevronSize),

            // Contact Us button
            _buildContactUsButton(
                context, locale, isDarkMode, chevronColor, chevronSize),

            // Update Button
            if (_updateAvailable)
              _buildUpdateButton(context, locale, isDarkMode, updateButtonText,
                  appConfig, chevronColor, chevronSize),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.dialogClose,
              style: TextStyle(
                fontFamily:
                    locale.languageCode == 'fa' ? 'Vazirmatn' : 'SF-Pro',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: tealGreen,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the theme toggle action
  Widget _buildThemeToggle(BuildContext context, Locale locale, bool isDarkMode,
      AppLocalizations l10n, Color tealGreen) {
    return CupertinoActionSheetAction(
      onPressed: () {}, // Empty callback to make it non-dismissible
      isDefaultAction: false,
      child: Padding(
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
              value: Theme.of(context).brightness == Brightness.dark,
              activeTrackColor: tealGreen,
              onChanged: (v) => context
                  .read<ThemeNotifier>()
                  .setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the language selector action
  Widget _buildLanguageSelector(
      BuildContext context,
      Locale locale,
      bool isDarkMode,
      AppLocalizations l10n,
      AppConfig appConfig,
      Color? chevronColor) {
    return CupertinoActionSheetAction(
      onPressed: () => _showLanguagePicker(context, appConfig, l10n),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.settingsLanguage,
            style: TextStyle(
              fontFamily: locale.languageCode == 'fa' ? 'Vazirmatn' : 'SF-Pro',
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
                  fontFamily:
                      locale.languageCode == 'fa' ? 'Vazirmatn' : 'SF-Pro',
                  fontSize: 16,
                  color: chevronColor,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                CupertinoIcons.chevron_down,
                size: 16,
                color: chevronColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the currency unit selector action
  Widget _buildCurrencyUnitSelector(
      BuildContext context,
      Locale locale,
      bool isDarkMode,
      AppLocalizations l10n,
      CurrencyUnit currencyUnit,
      Color? chevronColor) {
    return CupertinoActionSheetAction(
      onPressed: () => _showCurrencyUnitPicker(context, locale, l10n),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.settingsCurrencyUnit,
            style: TextStyle(
              fontFamily: locale.languageCode == 'fa' ? 'Vazirmatn' : 'SF-Pro',
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
                              containsPersian(l10n.currencyUnitToman))
                      ? 'Vazirmatn'
                      : 'SF-Pro',
                  fontSize: 16,
                  color: chevronColor,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                CupertinoIcons.chevron_down,
                size: 16,
                color: chevronColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the download app button for mobile web users
  Widget _buildDownloadAppButton(BuildContext context, Locale locale,
      bool isDarkMode, Color? chevronColor, double chevronSize) {
    return CupertinoActionSheetAction(
      onPressed: () {
        Navigator.pop(context);
        launchUrl(Uri.parse('https://dl.ryls.ir'));
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            locale.languageCode == 'fa' ? 'دانلود اپلیکیشن' : 'Download App',
            style: TextStyle(
              fontFamily: locale.languageCode == 'fa' ? 'Vazirmatn' : 'SF-Pro',
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
    );
  }

  /// Builds the terms and conditions button
  Widget _buildTermsButton(BuildContext context, Locale locale, bool isDarkMode,
      AppLocalizations l10n, Color? chevronColor, double chevronSize) {
    return CupertinoActionSheetAction(
      onPressed: () {
        Navigator.pop(context);
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
              fontFamily: locale.languageCode == 'fa' ? 'Vazirmatn' : 'SF-Pro',
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
    );
  }

  /// Builds the contact us button
  Widget _buildContactUsButton(BuildContext context, Locale locale,
      bool isDarkMode, Color? chevronColor, double chevronSize) {
    return CupertinoActionSheetAction(
      onPressed: () {
        Navigator.pop(context);
        final subject = locale.languageCode == 'fa'
            ? Uri.encodeComponent('درخواست پشتیبانی')
            : Uri.encodeComponent('Support Request');
        final body = locale.languageCode == 'fa'
            ? Uri.encodeComponent('سلام،\n\nلطفاً به من در مورد...')
            : Uri.encodeComponent('Hello,\n\nPlease assist me with...');
        final emailUrl = 'mailto:info@ryls.ir?subject=$subject&body=$body';
        launchUrl(Uri.parse(emailUrl));
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            locale.languageCode == 'fa' ? 'تماس با ما' : 'Contact Us',
            style: TextStyle(
              fontFamily: locale.languageCode == 'fa' ? 'Vazirmatn' : 'SF-Pro',
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
    );
  }

  /// Builds the update button if an update is available
  Widget _buildUpdateButton(
      BuildContext context,
      Locale locale,
      bool isDarkMode,
      String updateButtonText,
      AppConfig appConfig,
      Color? chevronColor,
      double chevronSize) {
    return CupertinoActionSheetAction(
      onPressed: () async {
        Navigator.pop(context);
        final updateInfo = appConfig.updateInfo;
        if (updateInfo.updateMode == 'package') {
          final pkg = updateInfo.updatePackage;
          final storeUri = Uri.parse('market://details?id=$pkg');
          if (await canLaunchUrl(storeUri)) {
            await launchUrl(storeUri);
          } else {
            final webUri = Uri.parse(
              'https://dl.ryls.ir',
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
              fontFamily: locale.languageCode == 'fa' ? 'Vazirmatn' : 'SF-Pro',
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
    );
  }
}

/// Shows language picker
void _showLanguagePicker(
  BuildContext context,
  AppConfig appConfig,
  AppLocalizations l10n,
) {
  final localeNotifier = context.read<LocaleNotifier>();
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final currentLocale = localeNotifier.locale;

  showCupertinoModalPopup(
    context: context,
    useRootNavigator: true,
    builder: (BuildContext pickerContext) {
      int selectedIndex = appConfig.supportedLocales.indexOf(
        currentLocale.languageCode,
      );
      if (selectedIndex < 0) selectedIndex = 0;

      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
        ),
        child: Column(
          children: [
            _buildPickerHeader(context, currentLocale, isDarkMode, l10n),
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
                  localeNotifier.setLocale(locale);
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

/// Shows currency unit picker
void _showCurrencyUnitPicker(
  BuildContext context,
  Locale currentLocale,
  AppLocalizations l10n,
) {
  final currencyUnitNotifier = context.read<CurrencyUnitNotifier>();
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final currentUnit = currencyUnitNotifier.unit;

  showCupertinoModalPopup(
    context: context,
    useRootNavigator: true,
    builder: (BuildContext pickerContext) {
      int selectedIndex = CurrencyUnit.values.indexOf(currentUnit);

      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
        ),
        child: Column(
          children: [
            _buildPickerHeader(context, currentLocale, isDarkMode, l10n),
            Expanded(
              child: CupertinoPicker(
                backgroundColor:
                    isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
                itemExtent: 40,
                scrollController: FixedExtentScrollController(
                  initialItem: selectedIndex,
                ),
                onSelectedItemChanged: (index) {
                  currencyUnitNotifier
                      .setCurrencyUnit(CurrencyUnit.values[index]);
                },
                children: CurrencyUnit.values.map((unit) {
                  String labelText = unit == CurrencyUnit.toman
                      ? l10n.currencyUnitToman
                      : unit == CurrencyUnit.usd
                          ? l10n.currencyUnitUSD
                          : l10n.currencyUnitEUR;

                  bool hasPersianChars = containsPersian(labelText);
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

/// Builds the header for pickers with close button
Widget _buildPickerHeader(
  BuildContext context,
  Locale currentLocale,
  bool isDarkMode,
  AppLocalizations l10n,
) {
  return Container(
    height: 50,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: isDarkMode ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7),
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
              fontFamily:
                  currentLocale.languageCode == 'fa' ? 'Vazirmatn' : 'SF-Pro',
              fontSize: 16,
              color: CupertinoColors.activeBlue,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}
