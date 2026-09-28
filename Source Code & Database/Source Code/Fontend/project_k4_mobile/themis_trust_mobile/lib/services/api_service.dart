import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ============================================================
  // BASE URL
  // ============================================================

  // Android Emulator
  static const String baseUrl =
      'http://10.0.2.2:5000/api';

  // Nếu chạy Flutter Windows:
  // static const String baseUrl =
  //     'http://localhost:5000/api';

  // ============================================================
  // GET
  // ============================================================
  Future<dynamic> patch(
      String endpoint, {
        Map<String, dynamic>? body,
        String? token,
      }) async {
    final authToken = await _getToken(token);

    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers(authToken),
      body: body != null ? jsonEncode(body) : null,
    );

    return _handleResponse(response);
  }

  Future<dynamic> get(
      String endpoint, {
        Map<String, String>? queryParameters,
        String? token,
      }) async {
    Uri uri = Uri.parse('$baseUrl$endpoint');

    if (queryParameters != null) {
      uri = uri.replace(
        queryParameters: queryParameters,
      );
    }

    final authToken = await _getToken(token);

    final response = await http.get(
      uri,
      headers: _headers(authToken),
    );

    return _handleResponse(response);
  }

  // ============================================================
  // POST
  // ============================================================

  Future<dynamic> post(
      String endpoint, {
        Map<String, dynamic>? body,
        String? token,
      }) async {
    /*
      Nếu token được truyền vào thì dùng token đó.

      Nếu không truyền token:
      ApiService tự lấy token đã lưu trong
      SharedPreferences.
    */

    final authToken = await _getToken(token);

    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers(authToken),
      body: body != null
          ? jsonEncode(body)
          : null,
    );

    return _handleResponse(response);
  }

  // ============================================================
  // PUT
  // ============================================================

  Future<dynamic> put(
      String endpoint, {
        Map<String, dynamic>? body,
        String? token,
      }) async {
    final authToken = await _getToken(token);

    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers(authToken),
      body: body != null
          ? jsonEncode(body)
          : null,
    );

    return _handleResponse(response);
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<dynamic> delete(
      String endpoint, {
        String? token,
      }) async {
    final authToken = await _getToken(token);

    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers(authToken),
    );

    return _handleResponse(response);
  }

  // ============================================================
  // GET TOKEN
  // ============================================================

  Future<String?> _getToken(String? token) async {
    // Nếu request truyền token riêng
    if (token != null && token.isNotEmpty) {
      return token;
    }

    // Nếu không truyền token,
    // lấy token đã lưu sau khi đăng nhập
    final prefs = await SharedPreferences.getInstance();

    final savedToken = prefs.getString('token');

    return savedToken;
  }

  // ============================================================
  // HEADERS
  // ============================================================

  Map<String, String> _headers(String? token) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // ============================================================
  // RESPONSE
  // ============================================================

  dynamic _handleResponse(
      http.Response response,
      ) {
    final statusCode = response.statusCode;

    dynamic data;

    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = response.body;
      }
    }

    // ==========================================================
    // SUCCESS
    // ==========================================================

    if (statusCode >= 200 && statusCode < 300) {
      return data;
    }

    // ==========================================================
    // ERROR
    // ==========================================================

    throw ApiException(
      statusCode: statusCode,
      message: _extractErrorMessage(data),
    );
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  String _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message']?.toString() ??
          data['title']?.toString() ??
          data['error']?.toString() ??
          data['detail']?.toString() ??
          'API request failed';
    }

    if (data != null) {
      return data.toString();
    }

    return 'API request failed';
  }
}


// ============================================================
// API EXCEPTION
// ============================================================

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() {
    return 'ApiException [$statusCode]: $message';
  }

}