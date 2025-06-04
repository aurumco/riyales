import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart'; // To get initial default values

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

class CardCornerSettingsNotifier extends ChangeNotifier {
  late CardCornerSettings _settings;
  // AppConfig is needed to initialize defaults, if SharedPreferences fails or is empty.
  final AppConfig appConfig;

  static const _radiusKey = 'card_corner_radius';
  static const _smoothnessKey = 'card_corner_smoothness';

  // Constructor now requires AppConfig
  CardCornerSettingsNotifier(this.appConfig) {
    // Initialize with defaults from AppConfig first
    _settings = CardCornerSettings(
      radius: appConfig.themeOptions.light.cardBorderRadius,
      smoothness: appConfig.themeOptions.light.cardCornerSmoothness,
    );
    // Then attempt to load saved preferences, which might override defaults
    _loadSettings();
  }

  CardCornerSettings get settings => _settings;

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final radius = prefs.getDouble(_radiusKey);
      final smoothness = prefs.getDouble(_smoothnessKey);

      // If loaded values are valid, update _settings
      if (radius != null && smoothness != null) {
        _settings = CardCornerSettings(radius: radius, smoothness: smoothness);
      }
      // If not, _settings retains the default values from constructor
    } catch (e) {
      // In case of any error, _settings retains defaults. Log error if necessary.
      // print('Error loading card corner settings: $e');
    }
    notifyListeners(); // Notify listeners after attempting to load
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
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_radiusKey, _settings.radius);
      await prefs.setDouble(_smoothnessKey, _settings.smoothness);
    } catch (e) {
      // Handle error, e.g., log it
      // print('Error saving card corner settings: $e');
    }
  }
}
