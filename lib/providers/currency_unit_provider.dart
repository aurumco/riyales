import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CurrencyUnit { toman, usd, eur }

class CurrencyUnitNotifier extends ChangeNotifier {
  CurrencyUnit _unit = CurrencyUnit.toman; // Default

  CurrencyUnitNotifier() {
    _loadCurrencyUnitPreference();
  }

  CurrencyUnit get unit => _unit;

  Future<void> _loadCurrencyUnitPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final unitString = prefs.getString('currencyUnit');
    if (unitString != null) {
      _unit = CurrencyUnit.values.firstWhere(
        (e) => e.toString() == unitString,
        orElse: () => CurrencyUnit.toman, // Fallback to Toman if string is invalid
      );
    }
    // No need to notifyListeners here if the UI should not react until a selection is made or loaded state is explicitly handled.
    // However, if initial state based on prefs should immediately reflect, uncomment next line.
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
