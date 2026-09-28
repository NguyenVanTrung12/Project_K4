class ConsultationRequestModel {
  final String id;

  final String clientId;
  final String clientName;
  final String clientEmail;

  final String? phone;

  final int? practiceAreaId;
  final String? practiceAreaName;

  final String? lawyerId;
  final String? lawyerName;

  final String title;
  final String description;

  final String priority;
  final String status;

  final String? attachmentUrl;

  final String? caseId;

  final DateTime? createdAt;

  ConsultationRequestModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    this.phone,
    this.practiceAreaId,
    this.practiceAreaName,
    this.lawyerId,
    this.lawyerName,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    this.attachmentUrl,
    this.caseId,
    this.createdAt,
  });

  factory ConsultationRequestModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return ConsultationRequestModel(
      id: json['id']?.toString() ?? '',

      clientId:
      json['clientId']?.toString() ?? '',

      clientName:
      json['clientName']?.toString() ?? 'Khách hàng',

      clientEmail:
      json['clientEmail']?.toString() ?? '',

      phone:
      json['phone']?.toString(),

      practiceAreaId:
      json['practiceAreaId'] != null
          ? int.tryParse(
        json['practiceAreaId'].toString(),
      )
          : null,

      practiceAreaName:
      json['practiceAreaName']?.toString(),

      lawyerId:
      json['lawyerId']?.toString(),

      lawyerName:
      json['lawyerName']?.toString(),

      title:
      json['title']?.toString() ?? '',

      description:
      json['description']?.toString() ?? '',

      priority:
      json['priority']?.toString() ?? 'normal',

      status:
      json['status']?.toString() ?? 'new',

      attachmentUrl:
      json['attachmentUrl']?.toString(),

      caseId:
      json['caseId']?.toString(),

      createdAt:
      json['createdAt'] != null
          ? DateTime.tryParse(
        json['createdAt'].toString(),
      )
          : null,
    );
  }
}