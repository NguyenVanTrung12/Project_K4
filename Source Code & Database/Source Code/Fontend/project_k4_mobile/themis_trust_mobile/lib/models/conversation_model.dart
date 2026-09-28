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

  factory ConversationModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return ConversationModel(
      id: json['id']?.toString() ?? '',

      clientId:
      json['clientId']?.toString() ?? '',

      clientName:
      json['clientName']?.toString() ??
          'Khách hàng',

      lawyerId:
      json['lawyerId']?.toString() ?? '',

      lawyerName:
      json['lawyerName']?.toString() ??
          'Luật sư',

      lastMessageAt:
      json['lastMessageAt'] != null
          ? DateTime.tryParse(
        json['lastMessageAt'].toString(),
      )
          : null,

      lastMessagePreview:
      json['lastMessagePreview']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'lawyerId': lawyerId,
      'lawyerName': lawyerName,
      'lastMessageAt':
      lastMessageAt?.toIso8601String(),
      'lastMessagePreview':
      lastMessagePreview,
    };
  }
}
