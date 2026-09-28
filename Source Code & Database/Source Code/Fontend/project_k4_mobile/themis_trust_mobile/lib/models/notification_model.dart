class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String? body;
  final String? refId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.body,
    this.refId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'].toString(),
      userId: json['userId'].toString(),
      type: json['type'] ?? 'system',
      title: json['title'] ?? '',
      body: json['body'],
      refId: json['refId']?.toString(),
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'refId': refId,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
