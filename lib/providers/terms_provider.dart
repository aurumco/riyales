import 'package:flutter/foundation.dart';
import '../../models/terms_data.dart';
import '../../config/app_config.dart';
import '../../services/api_service.dart';

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

  TermsNotifier(
      {required this.appConfig,
      required this.apiService,
      required this.languageCode}) {
    fetchTerms();
  }

  Future<void> fetchTerms() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final isPersian = languageCode == 'fa';
    // Determine remote URL for terms JSON: use apiEndpoints if set, otherwise derive from remoteConfigUrl
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
      // Remote fetch failed
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
