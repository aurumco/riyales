import 'package:dio/dio.dart';
import 'dart:convert';
import '../config/app_config.dart';
import 'package:riyales/protos/market_data.pb.dart' as market;

/// Extension methods for converting API URLs between JSON and Protobuf formats.
extension _UrlConversion on String {
  bool get isPb => toLowerCase().endsWith('.pb');
  bool get isJson => toLowerCase().endsWith('.json');
  bool get isMarketEndpoint => toLowerCase().contains('/market/');

  /// Convert a v1 JSON raw GitHub URL to its corresponding v2 protobuf raw URL.
  String toPbUrl() {
    if (isPb) return this;

    String url = this;
    url = url.replaceFirst('/api/v1/', '/api/v2/');
    url = url.replaceFirst('.json', '.pb');

    // raw.githubusercontent.com/aurumco/riyales-api/main/ -> raw.githubusercontent.com/aurumco/riyales-api/main/
    // No host change needed, but some configs might still have github.com domain; normalise.
    url = url.replaceFirst('github.com/', 'raw.githubusercontent.com/');
    url = url.replaceFirst('/raw/refs/heads/', '/');
    return url;
  }

  /// Convert a v2 protobuf raw URL to its corresponding v1 JSON raw URL.
  String toJsonUrl() {
    if (isJson) return this;

    String url = this;
    url = url.replaceFirst('/api/v2/', '/api/v1/');
    url = url.replaceFirst('.pb', '.json');

    url = url.replaceFirst('github.com/', 'raw.githubusercontent.com/');
    url = url.replaceFirst('/raw/refs/heads/', '/');
    return url;
  }
}

/// Performs a GET request for JSON and returns the decoded result.
Future<dynamic> _fetchJson(Dio dio, String url) async {
  final response = await dio.get(url);
  if (response.statusCode == 200) {
    return response.data is String
        ? jsonDecode(response.data as String)
        : response.data;
  }
  throw DioException(
    requestOptions: response.requestOptions,
    response: response,
    error: 'JSON request failed with status ${response.statusCode}',
  );
}

/// Performs a GET request for Protobuf and returns a decoded JSON-like structure.
Future<dynamic> _fetchPb(Dio dio, String url) async {
  final response = await dio.get<List<int>>(
    url,
    options: Options(responseType: ResponseType.bytes),
  );
  if (response.statusCode == 200 && response.data != null) {
    return _parseProtobufStatic(url, response.data!);
  }
  throw DioException(
    requestOptions: response.requestOptions,
    response: response,
    error: 'Protobuf request failed with status ${response.statusCode}',
  );
}

/// Static helper so it can be used from top-level function.
dynamic _parseProtobufStatic(String url, List<int> bytes) {
  url = url.toLowerCase();

  if (url.contains('cryptocurrency')) {
    return market.CryptoData.fromBuffer(bytes)
        .items
        .map((e) => e.toProto3Json())
        .toList();
  }
  if (url.contains('currency')) {
    return {
      'items': market.CurrencyData.fromBuffer(bytes)
          .items
          .map((e) => e.toProto3Json())
          .toList(),
    };
  }
  if (url.contains('gold')) {
    return {
      'items': market.GoldData.fromBuffer(bytes)
          .items
          .map((e) => e.toProto3Json())
          .toList(),
    };
  }
  if (url.contains('commodity')) {
    return {
      'metalPrecious': market.CommodityData.fromBuffer(bytes)
          .metalPrecious
          .map((e) => e.toProto3Json())
          .toList(),
    };
  }
  if (url.contains('debt_securities') ||
      url.contains('futures') ||
      url.contains('housing_facilities') ||
      url.contains('tse_ifb_symbols')) {
    return market.StockData.fromBuffer(bytes)
        .items
        .map((e) => e.toProto3Json())
        .toList();
  }
  return bytes; // unknown schema
}

/// Service for fetching data, preferring Protobuf for market endpoints.
/// Falls back to JSON if Protobuf fetch fails.
class ApiService {
  final Dio _dio;
  final ApiEndpoints apiEndpoints;

  ApiService(this._dio, this.apiEndpoints);

  Future<dynamic> fetchData(String url) async {
    try {
      // Normalise URL (remove whitespace etc.)
      url = url.trim();

      // Strategy:
      // 1. If it's a market URL, use the protobuf-first strategy.
      // 2. For all other URLs (config, priority assets), fetch as plain JSON.

      if (url.isMarketEndpoint) {
        if (url.isJson) {
          final pbUrl = url.toPbUrl();
          try {
            return await _fetchPb(_dio, pbUrl);
          } catch (_) {
            return await _fetchJson(_dio, url); // Fallback to original JSON
          }
        }

        if (url.isPb) {
          try {
            return await _fetchPb(_dio, url);
          } catch (_) {
            final jsonUrl = url.toJsonUrl();
            return await _fetchJson(_dio, jsonUrl); // Fallback to derived JSON
          }
        }
      }

      // Fallback for non-market URLs or market URLs that are neither .pb nor .json
      return await _fetchJson(_dio, url);
    } on DioException {
      rethrow;
    }
  }
}
