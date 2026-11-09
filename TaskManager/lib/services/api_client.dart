import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String? _cachedBaseUrl;

  Future<String> getBaseUrl() async {
    if (_cachedBaseUrl != null && _cachedBaseUrl!.isNotEmpty) {
      return _cachedBaseUrl!;
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.keyBaseUrl);
    _cachedBaseUrl = (saved != null && saved.isNotEmpty) ? saved : AppConstants.defaultBaseUrl;
    return _cachedBaseUrl!;
  }

  Future<void> setBaseUrl(String newUrl) async {
    _cachedBaseUrl = newUrl.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyBaseUrl, _cachedBaseUrl!);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyAuthToken);
  }

  Future<void> setToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove(AppConstants.keyAuthToken);
    } else {
      await prefs.setString(AppConstants.keyAuthToken, token);
    }
  }

  Future<Map<String, String>> _buildHeaders({bool requiresAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  dynamic _processResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      body = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    String message = 'Đã xảy ra lỗi (${response.statusCode})';
    if (body is Map && body.containsKey('message')) {
      message = body['message'].toString();
    }

    throw ApiException(message, statusCode: response.statusCode);
  }

  Future<dynamic> get(String endpoint, {bool requiresAuth = true}) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _buildHeaders(requiresAuth: requiresAuth);

    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Không thể kết nối đến máy chủ: $e');
    }
  }

  Future<dynamic> post(String endpoint,
      {dynamic body, bool requiresAuth = true}) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _buildHeaders(requiresAuth: requiresAuth);

    try {
      final response = await http
          .post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Không thể kết nối đến máy chủ: $e');
    }
  }

  Future<dynamic> put(String endpoint,
      {dynamic body, bool requiresAuth = true}) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _buildHeaders(requiresAuth: requiresAuth);

    try {
      final response = await http
          .put(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Không thể kết nối đến máy chủ: $e');
    }
  }

  Future<dynamic> patch(String endpoint,
      {dynamic body, bool requiresAuth = true}) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _buildHeaders(requiresAuth: requiresAuth);

    try {
      final response = await http
          .patch(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Không thể kết nối đến máy chủ: $e');
    }
  }

  Future<dynamic> delete(String endpoint, {bool requiresAuth = true}) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _buildHeaders(requiresAuth: requiresAuth);

    try {
      final response = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Không thể kết nối đến máy chủ: $e');
    }
  }
}
