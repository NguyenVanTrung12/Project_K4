import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final data = await _apiService.post(
      '/Auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );

    return Map<String, dynamic>.from(data);
  }
}