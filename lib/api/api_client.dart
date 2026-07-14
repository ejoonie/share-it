import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../storage/token_storage.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

String buildQueryString(Map<String, dynamic> params) {
  final parts = <String>[];
  params.forEach((k, v) {
    final encodedKey = Uri.encodeQueryComponent(k);
    if (v is List) {
      for (final item in v) {
        parts.add('$encodedKey=${Uri.encodeQueryComponent(item.toString())}');
      }
    } else {
      parts.add('$encodedKey=${Uri.encodeQueryComponent(v.toString())}');
    }
  });
  return parts.join('&');
}

class ApiClient {
  // Base URL for the rails-api. Configure with APP_ENV and API_BASE_URL.
  static String get baseUrl => AppConfig.apiBaseUrl;

  final http.Client _client;
  final TokenStorage? _tokenStorage;

  ApiClient({http.Client? client, TokenStorage? tokenStorage})
      : _client = client ?? http.Client(),
        _tokenStorage = tokenStorage;

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = _tokenStorage?.getToken();
    if (token != null) {
      headers['x-token'] = token;
    }
    return headers;
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client.post(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    var uri = Uri.parse('$baseUrl$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = Uri.parse('${uri.toString()}?${buildQueryString(queryParams)}');
    }
    final response = await _client.get(
      uri,
      headers: _headers(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client.patch(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client.delete(
      uri,
      headers: _headers(),
    );
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final body = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};
    final message = (body['message'] as String?) ?? 'Unknown error';
    throw ApiException(statusCode: response.statusCode, message: message);
  }
}
