import 'package:shared_preferences/shared_preferences.dart';

import '../models/conversation_model.dart';
import 'api_service.dart';

class ConversationService {
  final ApiService _api = ApiService();

  // ============================================================
  // GET TOKEN
  // ============================================================

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ============================================================
  // GET MY CONVERSATIONS
  //
  // GET /api/Messages/conversations
  // ============================================================

  Future<List<ConversationModel>> getMyConversations() async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Không có token đăng nhập.',
        );
      }

      print('========================================');
      print('GET MY CONVERSATIONS');
      print('Endpoint: /Messages/conversations');
      print('Token: CÓ TOKEN');
      print('========================================');

      final data = await _api.get(
        '/Messages/conversations',
        token: token,
      );

      print('CONVERSATION RESPONSE TYPE: ${data.runtimeType}');
      print('CONVERSATION RESPONSE: $data');

      if (data is! List) {
        throw Exception(
          'Dữ liệu danh sách cuộc trò chuyện không hợp lệ.',
        );
      }

      final conversations = data.map((json) {
        if (json is! Map<String, dynamic>) {
          throw Exception(
            'Một conversation không có định dạng JSON hợp lệ.',
          );
        }

        print('CONVERSATION JSON: $json');

        return ConversationModel.fromJson(json);
      }).toList();

      print(
        'TẢI THÀNH CÔNG: ${conversations.length} conversation',
      );

      return conversations;
    } catch (e, stackTrace) {
      print('========================================');
      print('GET CONVERSATIONS ERROR');
      print('ERROR: $e');
      print('STACK: $stackTrace');
      print('========================================');

      rethrow;
    }
  }

  // ============================================================
  // CREATE / START CONVERSATION
  //
  // POST /api/Messages/conversations
  // ============================================================

  Future<ConversationModel> createConversation({
    required String lawyerId,
    String? caseId,
  }) async {
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Không có token đăng nhập.',
      );
    }

    final data = await _api.post(
      '/Messages/conversations',
      token: token,
      body: {
        'lawyerId': lawyerId,
        'caseId': caseId,
      },
    );

    if (data is! Map<String, dynamic>) {
      throw Exception(
        'Dữ liệu cuộc trò chuyện không hợp lệ.',
      );
    }

    return ConversationModel.fromJson(data);
  }
}