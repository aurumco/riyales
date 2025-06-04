import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Added Provider
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/currency_unit_provider.dart';
import '../../localization/app_localizations.dart';
import '../screens/terms_screen.dart'; // Will be created later
import '../../utils/color_utils.dart';
import '../../utils/helpers.dart';

// Hardcoded current app version - TODO: consider moving to a config file or build variable
const String currentAppVersion = '0.140.0';


// Settings Sheet (minimal bottom sheet)
class SettingsSheet extends StatelessWidget { // Changed to StatelessWidget
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
  Widget build(BuildContext context) { // WidgetRef ref removed
    final themeNotifier = context.watch<ThemeNotifier>();
    final themeMode = themeNotifier.themeMode;
    final localeNotifier = context.watch<LocaleNotifier>();
    final locale = localeNotifier.locale;
    final currencyUnitNotifier = context.watch<CurrencyUnitNotifier>();
    final currencyUnit = currencyUnitNotifier.unit;
    final appConfig = context.watch<AppConfig>();
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Get teal green color for all accent elements
    final tealGreen = hexToColor( // from utils/color_utils.dart
      isDarkMode
          ? appConfig.themeOptions.dark.accentColorGreen
          : appConfig.themeOptions.light.accentColorGreen,
    );

    // Chevron color and size for all dropdowns and terms row
    final chevronColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    const chevronSize = 0.0; // Original code had 0.0, likely meant to be larger or was an error. Keeping for now.

    // App Version and Update Info
    // String displayVersion = currentAppVersion; // Not used in the original extracted code
    bool updateAvailable = false;
    String updateButtonText = l10n.settingsUpdateAvailable;
    // String changelog = ''; // Not used in the original extracted code

    // appConfig from context.watch with FutureProvider (with initialData & catchError) should not be null.
    if (_isVersionGreaterThan(
      appConfig.updateInfo.latestVersion,
      currentAppVersion,
    )) {
      updateAvailable = true;
      // changelog = locale.languageCode == 'fa' // Not used
      //     ? appConfig.updateInfo.changelogFa
      //     : appConfig.updateInfo.changelogEn;
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
                        context.read<ThemeNotifier>().toggleTheme(), // Using Provider
                  ),
                ],
              ),
            ),
          ),

          // Language selector
          // appConfig from context.watch with FutureProvider (with initialData & catchError) should not be null.
          CupertinoActionSheetAction(
            onPressed: () {
              // Show iOS-style picker for language selection
              _showLanguagePicker(context, localeNotifier, appConfig, l10n);
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
              // ref is no longer passed; context is available in _showCurrencyUnitPicker
              _showCurrencyUnitPicker(context, currencyUnitNotifier, locale, l10n);
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
                                    containsPersian( // from utils/helpers.dart
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
              // Build mailto URL manually to avoid '+' encoding for spaces
              final subject = locale.languageCode == 'fa'
                  ? Uri.encodeComponent('درخواست پشتیبانی')
                  : Uri.encodeComponent('Support Request');
              final body = locale.languageCode == 'fa'
                  ? Uri.encodeComponent('سلام،\n\nلطفاً به من در مورد...')
                  : Uri.encodeComponent('Hello,\n\nPlease assist me with...');
              final emailUrl =
                  'mailto:info@ryls.ir?subject=$subject&body=$body';
              launchUrl(Uri.parse(emailUrl));
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
                // appConfig from context.watch with FutureProvider (with initialData & catchError) should not be null.
                final updateInfo = appConfig.updateInfo;
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
  BuildContext context, // BuildContext is already available
  LocaleNotifier localeNotifier, // Pass Notifier directly
  AppConfig appConfig,
  AppLocalizations l10n,
) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final currentLocale = localeNotifier.locale; // Get locale from Notifier

  showCupertinoModalPopup(
    context: context,
    builder: (BuildContext pickerContext) { // Use a different context name for builder
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
                      l10n.dialogClose, // Use passed l10n
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
                  // Use the passed localeNotifier instance
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

// Helper method to show currency unit picker in iOS style
void _showCurrencyUnitPicker(
  BuildContext context, // BuildContext is available
  CurrencyUnitNotifier currencyUnitNotifier, // Pass Notifier
  Locale currentLocale, // Keep for font decisions based on language
  AppLocalizations l10n,
) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final currentUnit = currencyUnitNotifier.unit; // Get current unit from Notifier

  showCupertinoModalPopup(
    context: context,
    builder: (BuildContext pickerContext) { // Use a different context name
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
                      l10n.dialogClose, // Use passed l10n
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
                  // Use the passed currencyUnitNotifier instance
                  currencyUnitNotifier.setCurrencyUnit(CurrencyUnit.values[index]);
                },
                children: CurrencyUnit.values.map((unit) {
                  String labelText = unit == CurrencyUnit.toman
                      ? l10n.currencyUnitToman
                      : unit == CurrencyUnit.usd
                          ? l10n.currencyUnitUSD
                          : l10n.currencyUnitEUR;

                  bool hasPersianChars = containsPersian(labelText); // from utils/helpers.dart
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
