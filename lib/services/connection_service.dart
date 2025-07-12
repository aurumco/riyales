import 'dart:async';
import 'package:dio/dio.dart';

/// Monitors connectivity status for API endpoints and internet, broadcasting changes.
enum ConnectionStatus { connected, serverDown, internetDown }

// Helper extension to convert json URLs to their .pb counterpart.
extension _PingUrlHelper on String {
  String get pbEquivalent {
    final trimmed = trim();
    if (trimmed.toLowerCase().endsWith('.pb')) return trimmed;
    return trimmed
        .replaceFirst('/api/v1/', '/api/v2/')
        .replaceFirst('.json', '.pb')
        .replaceFirst('github.com/', 'raw.githubusercontent.com/')
        .replaceFirst('/raw/refs/heads/', '/');
  }
}

class ConnectionService {
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  final _statusController = StreamController<ConnectionStatus>.broadcast();
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  Timer? _pingTimer;
  String? _lastApiUrl;

  /// Initializes connection monitoring for [apiUrl].
  Future<void> initialize(String apiUrl) async {
    _lastApiUrl = apiUrl;
    await _checkAndUpdateStatus(apiUrl);
    _startPeriodicPing(apiUrl);
  }

  Future<void> _checkAndUpdateStatus(String apiUrl) async {
    final currentApiUrl = apiUrl;
    ConnectionStatus newStatus;

    final apiAvailable = await ping(currentApiUrl);
    if (apiAvailable) {
      newStatus = ConnectionStatus.connected;
    } else {
      bool internetAvailable = await ping('https://www.google.com'); // Primary
      if (!internetAvailable) {
        // Secondary
        internetAvailable = await ping('https://raw.githubusercontent.com');
      }

      if (internetAvailable) {
        newStatus = ConnectionStatus.serverDown;
      } else {
        newStatus = ConnectionStatus.internetDown;
      }
    }

    _isOnline = (newStatus == ConnectionStatus.connected);

    _statusController.add(newStatus);
  }

  void _startPeriodicPing(String apiUrl) {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_lastApiUrl != null) {
        await _checkAndUpdateStatus(_lastApiUrl!);
      }
    });
  }

  /// Checks connectivity to [apiUrl], updates status, and returns online state.
  Future<bool> checkConnection(String apiUrl) async {
    await _checkAndUpdateStatus(apiUrl);
    return _isOnline;
  }

  Future<bool> ping(String url) async {
    url = url.pbEquivalent;
    try {
      final dio = Dio();
      final response = await dio.request(
        url,
        options: Options(
          method: 'HEAD',
          validateStatus: (_) => true,
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      // Consider any 2xx or 3xx as "server reachable", though specific API might 404.
      // For a generic ping, just checking if we got a response is often enough.
      return response.statusCode != null &&
          response.statusCode! < 500; // Exclude server errors (5xx)
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _pingTimer?.cancel();
    _statusController.close();
  }
}
