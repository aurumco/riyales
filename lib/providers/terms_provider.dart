import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
// import 'package:dio/dio.dart'; // Dio would be part of ApiService
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

  TermsNotifier({required this.appConfig, required this.apiService, required this.languageCode}) {
    fetchTerms();
  }

  Future<void> fetchTerms() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final isPersian = languageCode == 'fa';
    final remoteUrl = isPersian ? appConfig.apiEndpoints.termsFaUrl : appConfig.apiEndpoints.termsEnUrl;
    final localAssetPath = isPersian ? 'assets/config/terms_fa.json' : 'assets/config/terms_en.json';

    try {
      TermsData? loadedData;
      if (remoteUrl.isNotEmpty) {
        try {
          final dynamic response = await apiService.fetchData(remoteUrl); // ApiService handles decoding
          if (response is Map<String, dynamic>) {
              loadedData = TermsData.fromJson(response);
          }
        } catch (e) {
          // Fallback to local if remote fails
        }
      }

      if (loadedData == null) {
        final localConfigString = await rootBundle.loadString(localAssetPath);
        final localConfigJson = jsonDecode(localConfigString) as Map<String, dynamic>;
        loadedData = TermsData.fromJson(localConfigJson);
      }
      _termsData = loadedData;
      _error = null; // Clear error if successful
    } catch (e) {
      _error = e.toString(); // Capture error from primary attempts
      // Final fallback to local asset, potentially overriding the above error if this succeeds
      try {
        final localConfigString = await rootBundle.loadString(localAssetPath);
        final localConfigJson = jsonDecode(localConfigString) as Map<String, dynamic>;
        _termsData = TermsData.fromJson(localConfigJson);
        _error = null; // Clear error if local fallback succeeds
      } catch (localError) {
         // If local fallback also fails, keep the original error (or update to localError)
         _error = localError.toString();
        _termsData = TermsData( // Provide default error terms
          title: isPersian ? 'خطا' : 'Error',
          content: isPersian ? 'قادر به بارگیری قوانین و مقررات نیستیم.' : 'Could not load terms and conditions.',
          lastUpdated: '',
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
