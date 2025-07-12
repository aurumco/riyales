import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:riyales/models/alert.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides alert configuration and manages alert dismissal state.
class AlertProvider extends ChangeNotifier {
  Alert? _alert;
  Alert? get alert => _alert;

  bool _isVisible = true;
  bool get isVisible => _isVisible;

  /// Key for storing dismissed alert's unique identifier.
  static const String _dismissedAlertIdentifierKey =
      'dismissed_alert_identifier';

  /// Generates a unique identifier string for the given alert.
  String _getAlertIdentifier(Alert alert) {
    return '${alert.color}::${alert.en.title}::${alert.en.description}::${alert.fa.title}::${alert.fa.description}';
  }

  /// Fetches alert configuration from remote and updates visibility.
  Future<void> fetchAlert() async {
    try {
      final response = await http.get(Uri.parse(
          'https://raw.githubusercontent.com/aurumco/riyales-api/refs/heads/main/api/v1/config/alert.json'));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        _alert = Alert.fromJson(data);

        if (_alert?.show != true) {
          _isVisible = false;
          notifyListeners();
          return;
        }

        final prefs = await SharedPreferences.getInstance();
        final currentIdentifier = _getAlertIdentifier(_alert!);
        final dismissedIdentifier =
            prefs.getString(_dismissedAlertIdentifierKey);
        _isVisible = dismissedIdentifier != currentIdentifier;
        notifyListeners();
      }
    } catch (e) {
      // Silently fail as this feature is non-critical.
      debugPrint('Failed to fetch alert: $e');
    }
  }

  /// Dismisses the current alert and remembers the dismissal.
  Future<void> dismissAndRememberAlert() async {
    if (_alert == null) return;

    final prefs = await SharedPreferences.getInstance();
    final identifier = _getAlertIdentifier(_alert!);
    await prefs.setString(_dismissedAlertIdentifierKey, identifier);

    _isVisible = false;
    notifyListeners();
  }
}
