import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../models/user_model.dart';
import 'api_service.dart';
import 'package:http/http.dart' as http;

class UserService {
  final ApiService _api = ApiService();

  Future<List<UserModel>> getUsers() async {
    final data = await _api.get('/Users');

    final List<dynamic> list = data;

    return list
        .map(
          (json) => UserModel.fromJson(
        json as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  Future<UserModel> getUserById(String id) async {
    final data = await _api.get('/Users/$id');

    return UserModel.fromJson(data);
  }

  Future<UserModel> updateProfile(
      String id,
      Map<String, dynamic> data,
      ) async {
    final result = await _api.patch(
      '/Users/$id/profile',
      body: data,
    );

    return UserModel.fromJson(result);
  }

  Future<String> uploadAvatar(
      String id,
      File file,
      ) async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('Không có token đăng nhập');
    }

    final uri = Uri.parse(
      '${ApiService.baseUrl}/Users/$id/avatar',
    );

    final request = http.MultipartRequest(
      'POST',
      uri,
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
      ),
    );

    final response = await request.send();

    final responseBody = await response.stream.bytesToString();

    dynamic data;

    try {
      data = jsonDecode(responseBody);
    } catch (_) {
      data = null;
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      final message =
      data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Không thể cập nhật ảnh đại diện';

      throw Exception(message);
    }

    if (data is Map && data['avatarUrl'] != null) {
      return data['avatarUrl'].toString();
    }

    throw Exception('API không trả về avatarUrl');
  }
}