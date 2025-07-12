import 'package:flutter/foundation.dart';
import '../../models/terms_data.dart';
import '../../config/app_config.dart';
import '../../services/api_service.dart';

/// Manages retrieval and state of terms and conditions data.
class TermsNotifier extends ChangeNotifier {
  final AppConfig appConfig;
  final ApiService apiService;
  final String languageCode;

  TermsData? _termsData;
  TermsData? get termsData => _termsData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// Initializes and fetches terms based on language.
  TermsNotifier(
      {required this.appConfig,
      required this.apiService,
      required this.languageCode}) {
    fetchTerms();
  }

  /// Fetches terms JSON from remote source and updates state.
  Future<void> fetchTerms() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final isPersian = languageCode == 'fa';
    final defaultConfigUrl = appConfig.remoteConfigUrl;
    final baseConfigUrl = defaultConfigUrl.contains('/')
        ? defaultConfigUrl.substring(0, defaultConfigUrl.lastIndexOf('/') + 1)
        : '';
    final remoteUrl = isPersian
        ? (appConfig.apiEndpoints.termsFaUrl.isNotEmpty
            ? appConfig.apiEndpoints.termsFaUrl
            : '${baseConfigUrl}terms_fa.json')
        : (appConfig.apiEndpoints.termsEnUrl.isNotEmpty
            ? appConfig.apiEndpoints.termsEnUrl
            : '${baseConfigUrl}terms_en.json');

    try {
      final dynamic response = await apiService.fetchData(remoteUrl);
      if (response is Map<String, dynamic>) {
        _termsData = TermsData.fromJson(response);
        _error = null;
      } else {
        throw Exception('Invalid terms JSON structure');
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
