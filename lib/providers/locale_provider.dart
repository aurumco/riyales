import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the application's locale preference.
class LocaleNotifier extends ChangeNotifier {
  Locale _locale;

  LocaleNotifier(this._locale) {
    _loadLocalePreference();
  }

  /// Current locale of the application.
  Locale get locale => _locale;

  /// Loads saved locale preference from storage.
  Future<void> _loadLocalePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode');
    if (languageCode != null) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    _locale = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', newLocale.languageCode);
    notifyListeners();
  }
}
