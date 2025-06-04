import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// No Riverpod imports needed here

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode;

  ThemeNotifier(this._themeMode) {
    _loadThemePreference();
  }

  ThemeMode get themeMode => _themeMode;

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode');
    if (isDarkMode != null) {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _saveThemePreference();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveThemePreference();
    notifyListeners();
  }

  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
  }
}
