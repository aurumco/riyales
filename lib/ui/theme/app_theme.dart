import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For SystemUiOverlayStyle
import '../../config/app_config.dart'; // For ThemeConfig, FontsConfig etc.
import '../../utils/color_utils.dart'; // For hexToColor
import '../../utils/color_extensions.dart'; // For darken, lighten extensions

class AppTheme {
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

  static ThemeData getThemeData(ThemeConfig themeConfig, String fontFamily,
      String defaultFontFamilyForThemeTitle, bool isDarkMode) {
    final Color primaryColor = hexToColor(themeConfig.primaryColor);
    hexToColor(themeConfig.backgroundColor);
    final Color scaffoldBackgroundColor =
        hexToColor(themeConfig.scaffoldBackgroundColor);
    final Color appBarColor = hexToColor(themeConfig.appBarColor);
    final Color cardColor = hexToColor(themeConfig.cardColor);
    final Color textColor = hexToColor(themeConfig.textColor);
    final Color secondaryTextColor = hexToColor(themeConfig.secondaryTextColor);
    final Color accentColorGreen = hexToColor(themeConfig.accentColorGreen);
    final Color accentColorRed = hexToColor(themeConfig.accentColorRed);

    // Apply darkening for dark theme as in original code
    final finalScaffoldBackgroundColor = isDarkMode
        ? scaffoldBackgroundColor.darken(10)
        : scaffoldBackgroundColor;
    final finalCardColor = isDarkMode ? cardColor.darken(5) : cardColor;
    final finalAppBarColor = isDarkMode
        ? appBarColor.darken(10)
        : appBarColor; // Assuming appbar also darkens like scaffold

    final textTheme = _createTextTheme(fontFamily, textColor);

    return ThemeData(
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: finalScaffoldBackgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor:
            finalAppBarColor, // Use potentially darkened scaffold/appbar color
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
          fontFamily:
              defaultFontFamilyForThemeTitle, // Use the specific font for titles (Vazirmatn or Onest)
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor:
              finalScaffoldBackgroundColor, // Status bar matches scaffold
          statusBarIconBrightness:
              isDarkMode ? Brightness.light : Brightness.dark,
          systemNavigationBarColor:
              finalScaffoldBackgroundColor, // Nav bar matches scaffold
          systemNavigationBarIconBrightness:
              isDarkMode ? Brightness.light : Brightness.dark,
        ),
      ),
      cardTheme: CardTheme(
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
              surface: finalCardColor, // Use potentially darkened card color
              onPrimary: textColor,
              onSecondary: textColor, // Ensure good contrast
              onSurface: textColor,
              error: accentColorRed,
              onError: textColor,
            )
          : ColorScheme.light(
              primary: primaryColor,
              secondary: accentColorGreen,
              surface: finalCardColor,
              onPrimary: textColor,
              onSecondary: Colors.white, // Common for light themes
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
