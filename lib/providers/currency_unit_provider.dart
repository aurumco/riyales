import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CurrencyUnit { toman, usd, eur }

/// Provides user preference for currency unit.
class CurrencyUnitNotifier extends ChangeNotifier {
  CurrencyUnit _unit = CurrencyUnit.toman;

  CurrencyUnitNotifier() {
    _loadCurrencyUnitPreference();
  }

  /// The currently selected currency unit.
  CurrencyUnit get unit => _unit;

  /// Loads the saved currency unit preference.
  Future<void> _loadCurrencyUnitPreference() async {
    notifyListeners();
  }

  Future<void> setCurrencyUnit(CurrencyUnit newUnit) async {
    if (_unit != newUnit) {
      _unit = newUnit;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currencyUnit', newUnit.toString());
      notifyListeners();
    }
  }
}
