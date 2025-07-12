import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart'; // To get initial default values

/// Defines radius and smoothness for card corners.
class CardCornerSettings {
  final double radius;
  final double smoothness;

  CardCornerSettings({required this.radius, required this.smoothness});

  CardCornerSettings copyWith({double? radius, double? smoothness}) {
    return CardCornerSettings(
      radius: radius ?? this.radius,
      smoothness: smoothness ?? this.smoothness,
    );
  }
}

/// Manages persistence and updates of card corner settings.
class CardCornerSettingsNotifier extends ChangeNotifier {
  late CardCornerSettings _settings;
  final AppConfig appConfig;

  static const _radiusKey = 'card_corner_radius';
  static const _smoothnessKey = 'card_corner_smoothness';

  CardCornerSettingsNotifier(this.appConfig) {
    _settings = CardCornerSettings(
      radius: appConfig.themeOptions.light.cardBorderRadius,
      smoothness: 0.75,
    );
    _loadSettings();
  }

  CardCornerSettings get settings => _settings;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final radius = prefs.getDouble(_radiusKey);
    final smoothness = prefs.getDouble(_smoothnessKey);

    if (radius != null && smoothness != null) {
      _settings = CardCornerSettings(radius: radius, smoothness: smoothness);
    }
    notifyListeners();
  }

  Future<void> updateRadius(double radius) async {
    if (_settings.radius != radius) {
      _settings = _settings.copyWith(radius: radius);
      await _saveSettings();
      notifyListeners();
    }
  }

  Future<void> updateSmoothness(double smoothness) async {
    if (_settings.smoothness != smoothness) {
      _settings = _settings.copyWith(smoothness: smoothness);
      await _saveSettings();
      notifyListeners();
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_radiusKey, _settings.radius);
    await prefs.setDouble(_smoothnessKey, _settings.smoothness);
  }
}
