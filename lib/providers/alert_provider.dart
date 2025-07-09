import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:riyales/models/alert.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlertProvider with ChangeNotifier {
  Alert? _alert;
  Alert? get alert => _alert;

  bool _isVisible = true;
  bool get isVisible => _isVisible;

  // Keys for storing dismissed alert's unique identifier.
  static const String _dismissedAlertIdentifierKey =
      'dismissed_alert_identifier';

  String _getAlertIdentifier(Alert alert) {
    // Create a unique string from the alert's content.
    return '${alert.color}::${alert.en.title}::${alert.en.description}::${alert.fa.title}::${alert.fa.description}';
  }

  Future<void> fetchAlert() async {
    try {
      final response = await http.get(Uri.parse(
          'https://raw.githubusercontent.com/aurumco/riyales-api/refs/heads/main/api/v1/config/alert.json'));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        _alert = Alert.fromJson(data);

        if (_alert == null || !_alert!.show) {
          _isVisible = false;
          notifyListeners();
          return;
        }

        // Check if this specific alert has been dismissed before.
        final prefs = await SharedPreferences.getInstance();
        final dismissedIdentifier =
            prefs.getString(_dismissedAlertIdentifierKey);
        final currentIdentifier = _getAlertIdentifier(_alert!);

        if (dismissedIdentifier == currentIdentifier) {
          // This alert is the same as the one the user dismissed. Keep it hidden.
          _isVisible = false;
        } else {
          // This is a new alert, so it should be visible.
          _isVisible = true;
        }
        notifyListeners();
      }
    } catch (e) {
      // Silently fail, as this is not a critical feature
      debugPrint('Failed to fetch alert: $e');
    }
  }

  Future<void> dismissAndRememberAlert() async {
    if (_alert == null) return;

    final prefs = await SharedPreferences.getInstance();
    final identifier = _getAlertIdentifier(_alert!);
    await prefs.setString(_dismissedAlertIdentifierKey, identifier);

    _isVisible = false;
    notifyListeners();
  }
}
