import 'package:flutter/material.dart'; // For Locale
import 'package:shared_preferences/shared_preferences.dart';
// No Riverpod imports needed here

class LocaleNotifier extends ChangeNotifier {
  Locale _locale;

  LocaleNotifier(this._locale) {
    _loadLocalePreference();
  }

  Locale get locale => _locale;

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
