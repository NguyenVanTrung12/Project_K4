class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String? content;
  final String? attachmentUrl;
  final DateTime sentAt;
  final DateTime? readAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.content,
    this.attachmentUrl,
    required this.sentAt,
    this.readAt,
  });

  factory MessageModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return MessageModel(
      id: json['id'].toString(),
      conversationId: json['conversationId'].toString(),
      senderId: json['senderId'].toString(),
      content: json['content'],
      attachmentUrl: json['attachmentUrl'],
      sentAt: DateTime.parse(json['sentAt']),
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'content': content,
      'attachmentUrl': attachmentUrl,
      'sentAt': sentAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }
}