import 'package:shared_preferences/shared_preferences.dart';

import '../models/message_model.dart';
import 'api_service.dart';

class MessageService {
  final ApiService _api = ApiService();

  // ============================================================
  // GET TOKEN
  // ============================================================

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ============================================================
  // GET CONVERSATIONS
  //
  // GET /api/Messages/conversations
  //
  // Backend tự xác định lawyer hiện tại từ JWT.
  // Không cần truyền lawyerId.
  // ============================================================

  Future<List<ConversationModel>> getConversations() async {
    final token = await _getToken();

    final data = await _api.get('/Messages/conversations', token: token);

    if (data is! List) {
      throw Exception('Dữ liệu danh sách cuộc trò chuyện không hợp lệ');
    }

    return data
        .map((json) => ConversationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // GET MESSAGES BY CONVERSATION
  //
  // GET /api/Messages/conversations/{conversationId}
  // ============================================================

  Future<List<MessageModel>> getByConversation(String conversationId) async {
    final token = await _getToken();

    final data = await _api.get(
      '/Messages/conversations/$conversationId',
      token: token,
    );

    if (data is! List) {
      throw Exception('Dữ liệu tin nhắn không hợp lệ');
    }

    return data
        .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // SEND MESSAGE
  //
  // POST /api/Messages
  // ============================================================

  Future<MessageModel> sendMessage({
    required String conversationId,
    String? content,
    String? attachmentUrl,
  }) async {
    final token = await _getToken();

    final data = await _api.post(
      '/Messages',
      token: token,
      body: {
        'conversationId': conversationId,
        'content': content,
        'attachmentUrl': attachmentUrl,
      },
    );

    return MessageModel.fromJson(data as Map<String, dynamic>);
  }

  // ============================================================
  // CREATE / START CONVERSATION
  //
  // POST /api/Messages/conversations
  // ============================================================

  Future<String> createConversation({
    required String lawyerId,
    String? caseId,
  }) async {
    final token = await _getToken();

    final data = await _api.post(
      '/Messages/conversations',
      token: token,
      body: {'lawyerId': lawyerId, 'caseId': caseId},
    );

    if (data is! Map<String, dynamic>) {
      throw Exception('Dữ liệu cuộc trò chuyện không hợp lệ');
    }

    final conversationId = data['id']?.toString();

    if (conversationId == null || conversationId.isEmpty) {
      throw Exception('Không nhận được conversationId');
    }

    return conversationId;
  }

  // ============================================================
  // MARK CONVERSATION AS READ
  //
  // POST /api/Messages/conversations/{conversationId}/read
  //
  // Đánh dấu tất cả tin nhắn do người khác gửi là đã đọc.
  // ============================================================

  Future<void> markConversationAsRead(String conversationId) async {
    final token = await _getToken();

    await _api.post(
      '/Messages/conversations/$conversationId/read',
      token: token,
    );
  }
}

// ============================================================
// CONVERSATION MODEL
// ============================================================

class ConversationModel {
  final String id;
  final String clientId;
  final String clientName;
  final String lawyerId;
  final String lawyerName;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;

  ConversationModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.lawyerId,
    required this.lawyerName,
    this.lastMessageAt,
    this.lastMessagePreview,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id']?.toString() ?? '',
      clientId: json['clientId']?.toString() ?? '',
      clientName: json['clientName']?.toString() ?? 'Khách hàng',
      lawyerId: json['lawyerId']?.toString() ?? '',
      lawyerName: json['lawyerName']?.toString() ?? 'Luật sư',
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'].toString())?.toLocal()
          : null,
      lastMessagePreview: json['lastMessagePreview']?.toString(),
    );
  }
}
