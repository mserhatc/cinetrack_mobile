import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String? _authToken;

  Future<void> initToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  void setToken(String? token) {
    _authToken = token;
  }

  String? get token => _authToken;

  Map<String, String> _getHeaders({Map<String, String>? extraHeaders}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      AppConstants.apiKeyHeader: AppConstants.apiKey,
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    Uri uri = Uri.parse('${AppConstants.apiBaseUrl}$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      final stringParams = queryParams.map((k, v) => MapEntry(k, v.toString()));
      uri = uri.replace(queryParameters: stringParams);
    }

    try {
      final response = await http.get(uri, headers: _getHeaders());
      return _processResponse(response);
    } catch (e) {
      throw Exception('Ağ bağlantı hatası: $e');
    }
  }

  Future<dynamic> post(String endpoint, {dynamic body}) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}$endpoint');
    try {
      final response = await http.post(
        uri,
        headers: _getHeaders(),
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('Ağ bağlantı hatası: $e');
    }
  }

  Future<dynamic> put(String endpoint, {dynamic body}) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}$endpoint');
    try {
      final response = await http.put(
        uri,
        headers: _getHeaders(),
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('Ağ bağlantı hatası: $e');
    }
  }

  Future<dynamic> delete(String endpoint, {dynamic body}) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}$endpoint');
    try {
      final response = await http.delete(
        uri,
        headers: _getHeaders(),
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('Ağ bağlantı hatası: $e');
    }
  }

  dynamic _processResponse(http.Response response) {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    } else {
      final message = decoded is Map && decoded.containsKey('message')
          ? decoded['message']
          : 'Bir hata oluştu (HTTP ${response.statusCode})';
      throw Exception(message);
    }
  }
}

