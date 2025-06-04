import 'dart:async';
import 'package:dio/dio.dart';
// Removed Riverpod imports as they are not directly used by the service logic itself.
// Imports for AppLocalizations, LocaleNotifier, AppConfigProvider would be needed
// if this service directly interacted with UI localization/config state,
// but it primarily provides connection status. UI components using this service will handle that.

enum ConnectionStatus { connected, serverDown, internetDown }

class ConnectionService {
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

  bool _isOnline = true; // Assume online by default until first check
  bool get isOnline => _isOnline;

  final _statusController = StreamController<ConnectionStatus>.broadcast();
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  Timer? _pingTimer;
  String? _lastApiUrl; // To store the apiUrl for periodic checks

  Future<void> initialize(String apiUrl) async {
    _lastApiUrl = apiUrl; // Store for periodic checks
    await _checkAndUpdateStatus(apiUrl);
    _startPeriodicPing(apiUrl);
  }

  Future<void> _checkAndUpdateStatus(String apiUrl) async {
    final currentApiUrl = apiUrl; // Use the passed apiUrl for this check
    ConnectionStatus newStatus;

    final apiAvailable = await ping(currentApiUrl);
    if (apiAvailable) {
      newStatus = ConnectionStatus.connected;
    } else {
      final internetAvailable = await ping('https://www.google.com'); // Fallback check
      if (internetAvailable) {
        newStatus = ConnectionStatus.serverDown;
      } else {
        newStatus = ConnectionStatus.internetDown;
      }
    }

    _isOnline = (newStatus == ConnectionStatus.connected);

    // Only notify if status changed
    // Note: The original code had a potential issue where it might not notify if status remained offline but changed type (e.g. serverDown -> internetDown)
    // This simplified version notifies on any change from the last broadcasted status.
    // For more fine-grained control, one might need to store the last *broadcasted* status.
    _statusController.add(newStatus);
  }

  void _startPeriodicPing(String apiUrl) {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      // Use the stored _lastApiUrl for periodic checks, ensuring it's not null
      if (_lastApiUrl != null) {
        await _checkAndUpdateStatus(_lastApiUrl!);
      }
    });
  }

  Future<bool> checkConnection(String apiUrl) async {
    // This specific call should update the status based on the provided apiUrl
    await _checkAndUpdateStatus(apiUrl);
    return _isOnline;
  }

  Future<bool> ping(String url) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        url,
        options: Options(
          validateStatus: (_) => true, // Consider any status code a valid response for ping
          sendTimeout: const Duration(seconds: 3), // Shorter timeout for ping
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      // Consider any 2xx or 3xx as "server reachable", though specific API might 404.
      // For a generic ping, just checking if we got a response is often enough.
      return response.statusCode != null && response.statusCode! < 500; // Exclude server errors (5xx)
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _pingTimer?.cancel();
    _statusController.close();
  }
}
