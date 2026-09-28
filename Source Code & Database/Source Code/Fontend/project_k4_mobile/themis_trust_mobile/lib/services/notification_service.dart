import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_model.dart';
import 'api_service.dart';

class NotificationService {
  final ApiService _api = ApiService();

  // ============================================================
  // GET MY NOTIFICATIONS
  // GET /api/Notifications
  // ============================================================

  Future<List<NotificationModel>> getMine({
    bool? unreadOnly,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final queryParameters = <String, String>{};

    if (unreadOnly != null) {
      queryParameters['unreadOnly'] = unreadOnly.toString();
    }

    final data = await _api.get(
      '/Notifications',
      queryParameters: queryParameters.isEmpty
          ? null
          : queryParameters,
      token: token,
    );

    if (data is! List) {
      throw Exception('Dữ liệu thông báo không hợp lệ');
    }

    return data
        .map(
          (json) => NotificationModel.fromJson(
        json as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  // ============================================================
  // GET UNREAD COUNT
  // GET /api/Notifications/unread-count
  // ============================================================

  Future<int> getUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final data = await _api.get(
      '/Notifications/unread-count',
      token: token,
    );

    if (data is int) {
      return data;
    }

    return int.tryParse(data.toString()) ?? 0;
  }

  // ============================================================
  // MARK AS READ
  // PATCH /api/Notifications/{id}/read
  // ============================================================

  Future<void> markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    await _api.patch(
      '/Notifications/$id/read',
      token: token,
    );
  }

  // ============================================================
  // MARK ALL AS READ
  // PATCH /api/Notifications/read-all
  // ============================================================

  Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    await _api.patch(
      '/Notifications/read-all',
      token: token,
    );
  }
}