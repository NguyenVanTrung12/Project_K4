class AppointmentModel {
  // ============================================================
  // APPOINTMENT
  // ============================================================

  final String id;

  // ============================================================
  // CLIENT
  // ============================================================

  final String clientId;
  final String clientName;
  final String clientPhone;
  final String clientEmail;
  final String clientAvatarUrl;

  // ============================================================
  // LAWYER
  // ============================================================

  final String lawyerId;
  final String lawyerName;

  // ============================================================
  // CASE
  // ============================================================

  final String? caseId;

  // ============================================================
  // APPOINTMENT INFORMATION
  // ============================================================

  final DateTime scheduledAt;
  final int durationMin;
  final String status;
  final String? description;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  AppointmentModel({
    required this.id,

    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    required this.clientEmail,
    required this.clientAvatarUrl,

    required this.lawyerId,
    required this.lawyerName,

    this.caseId,

    required this.scheduledAt,
    required this.durationMin,
    required this.status,
    this.description,
  });

  // ============================================================
  // FROM JSON
  // ============================================================

  factory AppointmentModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return AppointmentModel(
      // ========================================================
      // APPOINTMENT
      // ========================================================

      id: json['id']?.toString() ?? '',

      // ========================================================
      // CLIENT
      // ========================================================

      clientId:
      json['clientId']?.toString() ?? '',

      clientName:
      json['clientName']?.toString() ??
          'Khách hàng',

      clientPhone:
      json['clientPhone']?.toString() ?? '',

      clientEmail:
      json['clientEmail']?.toString() ?? '',

      clientAvatarUrl:
      json['clientAvatarUrl']?.toString() ?? '',

      // ========================================================
      // LAWYER
      // ========================================================

      lawyerId:
      json['lawyerId']?.toString() ?? '',

      lawyerName:
      json['lawyerName']?.toString() ??
          'Luật sư',

      // ========================================================
      // CASE
      // ========================================================

      caseId:
      json['caseId']?.toString(),

      // ========================================================
      // APPOINTMENT INFORMATION
      // ========================================================

      scheduledAt:
      DateTime.tryParse(
        json['scheduledAt']?.toString() ?? '',
      ) ??
          DateTime.now(),

      durationMin:
      int.tryParse(
        json['durationMin']?.toString() ?? '',
      ) ??
          30,

      status:
      json['status']?.toString() ??
          'pending',

      description:
      json['description']?.toString(),
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,

      'clientId': clientId,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'clientEmail': clientEmail,
      'clientAvatarUrl': clientAvatarUrl,

      'lawyerId': lawyerId,
      'lawyerName': lawyerName,

      'caseId': caseId,

      'scheduledAt':
      scheduledAt.toIso8601String(),

      'durationMin': durationMin,

      'status': status,

      'description': description,
    };
  }
}