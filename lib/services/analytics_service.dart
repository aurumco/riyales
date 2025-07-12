/// Service for buffering, persisting, and dispatching analytics events.
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:riyales/config/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class _AggregatedEvent {
  final String eventType;
  final String eventData;
  int count = 1;

  _AggregatedEvent({
    required this.eventType,
    required this.eventData,
  });

  Map<String, dynamic> toJson() {
    return {
      'event_type': eventType,
      'event_data': eventData,
      'count': count,
    };
  }

  factory _AggregatedEvent.fromJson(Map<String, dynamic> json) {
    return _AggregatedEvent(
      eventType: json['event_type'],
      eventData: json['event_data'],
    )..count = json['count'];
  }
}

class AnalyticsService {
  final Map<String, _AggregatedEvent> _eventBuffer = {};

  AnalyticsService._privateConstructor();
  static final AnalyticsService instance =
      AnalyticsService._privateConstructor();

  static const String _apiKeyKey = 'ryls_api_key';
  static const String _storedEventsKey = 'ryls_analytics_events';
  static const String _lastSendTimeKey = 'ryls_analytics_last_send_time';

  Future<String> _getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    String? apiKey = prefs.getString(_apiKeyKey);
    if (apiKey == null) {
      final String uuid = const Uuid().v4();
      apiKey = 'RYLS-$uuid';
      await prefs.setString(_apiKeyKey, apiKey);
      if (kDebugMode) {
        print('[AnalyticsService] Generated and saved new API Key: $apiKey');
      }
    }
    return apiKey;
  }

  void logEvent(String eventType, Map<String, dynamic> eventData) {
    final eventDataJson = jsonEncode(eventData);
    // Create a unique key for each event type + data combination
    final String eventKey = '$eventType-$eventDataJson';

    if (_eventBuffer.containsKey(eventKey)) {
      _eventBuffer[eventKey]!.count++;
    } else {
      _eventBuffer[eventKey] = _AggregatedEvent(
        eventType: eventType,
        eventData: eventDataJson,
      );
    }
  }

  // Save all in-memory events to SharedPreferences
  Future<void> saveEvents() async {
    if (_eventBuffer.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing stored events, if any
      final storedEventsJson = prefs.getStringList(_storedEventsKey) ?? [];
      final Map<String, _AggregatedEvent> storedEvents = {};

      // Parse stored events
      for (final eventJson in storedEventsJson) {
        final Map<String, dynamic> eventMap = jsonDecode(eventJson);
        final event = _AggregatedEvent.fromJson(eventMap);
        final eventKey = '${event.eventType}-${event.eventData}';
        storedEvents[eventKey] = event;
      }

      // Merge in-memory events with stored events
      for (final entry in _eventBuffer.entries) {
        if (storedEvents.containsKey(entry.key)) {
          storedEvents[entry.key]!.count += entry.value.count;
        } else {
          storedEvents[entry.key] = entry.value;
        }
      }

      // Convert back to JSON and save
      final updatedEventsJson = storedEvents.values
          .map((event) => jsonEncode(event.toJson()))
          .toList();

      await prefs.setStringList(_storedEventsKey, updatedEventsJson);
      // Events persisted; clear buffer.
      _eventBuffer.clear();
    } catch (_) {
      // Suppress errors in production.
    }
  }

  // Load events from previous session and send them
  Future<void> sendPreviousEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedEventsJson = prefs.getStringList(_storedEventsKey) ?? [];

      if (storedEventsJson.isEmpty) {
        // No stored events to send.
        return;
      }

      // Convert stored JSON to event objects
      final List<_AggregatedEvent> events = storedEventsJson
          .map((json) => _AggregatedEvent.fromJson(jsonDecode(json)))
          .toList();

      if (kDebugMode) {
        print(
            '[AnalyticsService] Sending ${events.length} stored events from previous session.');
      }

      // Format events for API
      final List<Map<String, dynamic>> eventList =
          events.map((e) => e.toJson()).toList();
      final body = jsonEncode({'events': eventList});
      final apiKey = await _getApiKey();

      // Body prepared for API call.

      // Send events to server
      final response = await http
          .post(
            Uri.parse(AppConstants.apiBaseUrl + AppConstants.eventEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'X-API-Key': apiKey,
            },
            body: body,
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Events dispatched successfully; clear stored events.
        await prefs.remove(_storedEventsKey);
        await prefs.setString(
            _lastSendTimeKey, DateTime.now().toIso8601String());

        if (kDebugMode) {
          print(
              '[AnalyticsService] Successfully sent stored events from previous session.');
        }
      } else {
        // Dispatch failed; events will be retried later.
      }
    } catch (_) {
      // Suppress errors in production.
    }
  }

  // This method is kept for backward compatibility but now just saves events to storage
  Future<void> sendBatchedEvents() async {
    await saveEvents();
  }
}
