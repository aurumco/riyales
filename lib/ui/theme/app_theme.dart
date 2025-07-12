import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_config.dart';
import '../../utils/color_utils.dart';

/// Utility class to generate app themes based on configuration and mode.
class AppTheme {
  /// Creates a [TextTheme] with the specified [fontFamily] and [textColor].
  static TextTheme _createTextTheme(String fontFamily, Color textColor) {
    return TextTheme(
      displayLarge: TextStyle(
          fontFamily: fontFamily,
          color: textColor,
          fontSize: 57,
          fontWeight: FontWeight.w400),
      displayMedium: TextStyle(
          fontFamily: fontFamily,
          color: textColor,
          fontSize: 45,
          fontWeight: FontWeight.w400),
      displaySmall: TextStyle(
          fontFamily: fontFamily,
          color: textColor,
          fontSize: 36,
          fontWeight: FontWeight.w400),
      headlineLarge: TextStyle(
          fontFamily: fontFamily,
          color: textColor,
          fontSize: 32,
          fontWeight: FontWeight.w400),
      headlineMedium: TextStyle(
          fontFamily: fontFamily,
          color: textColor,
          fontSize: 28,
          fontWeight: FontWeight.w400),
      headlineSmall: TextStyle(
          fontFamily: fontFamily,
          color: textColor,
          fontSize: 24,
          fontWeight: FontWeight.w700),
      titleLarge: TextStyle(
          fontFamily: fontFamily,
          color: textColor,
          fontSize: 22,
          fontWeight: FontWeight.w500),
      titleMedium: TextStyle(
          fontFamily: fontFamily,
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w700),
      titleSmall: TextStyle(
          fontFamily: fontFamily,
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(
          fontFamily: fontFamily,
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(
          fontFamily: fontFamily,
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w400),
      bodySmall: TextStyle(
          fontFamily: fontFamily,
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w400),
      labelLarge: TextStyle(
          fontFamily: fontFamily,
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w500),
      labelMedium: TextStyle(
          fontFamily: fontFamily,
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500),
      labelSmall: TextStyle(
          fontFamily: fontFamily,
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w400),
    );
  }

  /// Returns [ThemeData] configured from [themeConfig], using [fontFamily] for text and [isDarkMode].
  static ThemeData getThemeData(ThemeConfig themeConfig, String fontFamily,
      String defaultFontFamilyForThemeTitle, bool isDarkMode) {
    final primaryColor = hexToColor(themeConfig.primaryColor);
    final scaffoldBackgroundColor =
        hexToColor(themeConfig.scaffoldBackgroundColor);
    final Color appBarColor = hexToColor(themeConfig.appBarColor);
    final Color cardColor = hexToColor(themeConfig.cardColor);
    final Color textColor = hexToColor(themeConfig.textColor);
    final Color secondaryTextColor = hexToColor(themeConfig.secondaryTextColor);
    final Color accentColorGreen = hexToColor(themeConfig.accentColorGreen);
    final Color accentColorRed = hexToColor(themeConfig.accentColorRed);

    // Dark mode: use pure black backgrounds for app bar, scaffold, and card
    final finalScaffoldBackgroundColor =
        isDarkMode ? const Color(0xFF090909) : scaffoldBackgroundColor;
    final finalCardColor = isDarkMode ? const Color(0xFF161616) : cardColor;
    final finalAppBarColor = isDarkMode ? const Color(0xFF090909) : appBarColor;

    final textTheme = _createTextTheme(fontFamily, textColor);

    return ThemeData(
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: finalScaffoldBackgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: finalAppBarColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
          fontFamily: defaultFontFamilyForThemeTitle,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: finalScaffoldBackgroundColor,
          statusBarIconBrightness:
              isDarkMode ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: finalScaffoldBackgroundColor,
          systemNavigationBarIconBrightness:
              isDarkMode ? Brightness.light : Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: finalCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(themeConfig.cardBorderRadius),
        ),
      ),
      textTheme: textTheme,
      colorScheme: isDarkMode
          ? ColorScheme.dark(
              primary: primaryColor,
              secondary: accentColorGreen,
              surface: finalCardColor,
              onPrimary: textColor,
              onSecondary: textColor,
              onSurface: textColor,
              error: accentColorRed,
              onError: textColor,
            )
          : ColorScheme.light(
              primary: primaryColor,
              secondary: accentColorGreen,
              surface: finalCardColor,
              onPrimary: textColor,
              onSecondary: Colors.white,
              onSurface: textColor,
              error: accentColorRed,
              onError: Colors.white,
            ),
      iconTheme: IconThemeData(color: secondaryTextColor),
      dividerColor: Colors.transparent,
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        ),
      ),
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );
  }
}
