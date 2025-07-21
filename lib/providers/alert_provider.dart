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

  /// Key for storing ad view counts by idAd
  static const String _adViewCountsKey = 'ad_view_counts';

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

  /// Records that an ad with the given idAd has been viewed.
  Future<void> recordAdView(String idAd) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final viewCountsJson = prefs.getString(_adViewCountsKey) ?? '{}';
      final Map<String, dynamic> viewCounts = json.decode(viewCountsJson);

      final currentCount = viewCounts[idAd] ?? 0;
      viewCounts[idAd] = currentCount + 1;

      await prefs.setString(_adViewCountsKey, json.encode(viewCounts));
    } catch (e) {
      // Silent fail
    }
  }

  /// Gets the current view count for an ad with the given idAd.
  Future<int> getAdViewCount(String idAd) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final viewCountsJson = prefs.getString(_adViewCountsKey) ?? '{}';
      final Map<String, dynamic> viewCounts = json.decode(viewCountsJson);
      return viewCounts[idAd] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Checks if an ad can be shown based on its repeat limit.
  Future<bool> canShowAd(AdEntry adEntry) async {
    // If repeatCount is null, it means infinite (no limit)
    if (adEntry.repeatCount == null) {
      return true;
    }

    // If repeatCount is 0, never show
    if (adEntry.repeatCount == 0) {
      return false;
    }

    final currentViews = await getAdViewCount(adEntry.id);
    return currentViews < adEntry.repeatCount!;
  }

  /// Gets available ads that can be shown based on repeat limits.
  Future<List<AdEntry>> getAvailableAds(bool isMobileDevice) async {
    if (_alert?.ad == null || !_alert!.ad!.enabled) {
      return [];
    }

    final availableAds = <AdEntry>[];
    for (final adEntry in _alert!.ad!.entriesForDevice(isMobileDevice)) {
      if (await canShowAd(adEntry)) {
        availableAds.add(adEntry);
      }
    }

    return availableAds;
  }

  /// Clears all ad view counts (useful for testing or reset).
  Future<void> clearAdViewCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_adViewCountsKey);
    } catch (e) {
      // Silent fail
    }
  }
}
