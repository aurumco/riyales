import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the application's theme mode preference.
class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode;

  /// Current theme mode (light or dark).
  ThemeNotifier(this._themeMode) {
    _loadThemePreference();
  }

  /// The current theme mode.
  ThemeMode get themeMode => _themeMode;

  /// Toggles between light and dark modes and persists preference.
  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _saveThemePreference();
    notifyListeners();
  }

  /// Sets a specific theme mode and persists preference.
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveThemePreference();
    notifyListeners();
  }

  /// Loads the saved theme preference from storage.
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode');
    if (isDarkMode != null) {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    }
  }

  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
  }
}
