import 'package:dio/dio.dart';
import 'dart:convert'; // For jsonDecode if response.data is String
import '../config/app_config.dart'; // Corrected import path for AppConfig/ApiEndpoints

class ApiService {
  final Dio _dio;
  final ApiEndpoints apiEndpoints;

  ApiService(this._dio, this.apiEndpoints);

  Future<dynamic> fetchData(String url) async {
    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        if (response.data is String) {
          // If server returns a JSON string, decode it
          return jsonDecode(response.data as String);
        }
        // If Dio is configured to automatically parse JSON, response.data is already a Map/List
        return response.data;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'API request failed with status code ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      // Handle Dio specific errors (network, timeout, etc.)
      // Consider logging this error to a service
      // print('DioException in ApiService for $url: ${e.message}');
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        // Specific timeout error
      } else if (e.type == DioExceptionType.unknown) {
        // covers no internet, DNS issues
        // No internet or host not found
      }
      rethrow; // Rethrow to be caught by the caller (e.g., DataNotifier)
    } catch (e) {
      // Handle other errors
      // print('Generic error in ApiService for $url: $e');
      rethrow;
    }
  }
}
