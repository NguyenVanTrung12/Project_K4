class LawyerModel {
  // =============================================================
  // USER
  // =============================================================
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? gender;
  final bool isActive;
  final DateTime? userCreatedAt;
  final DateTime? updatedAt;

  // =============================================================
  // LAWYER
  // =============================================================
  final String title;
  final String? barLicenseNo;
  final int yearsExp;
  final String? bio;

  // Thông tin cá nhân
  final String? address;
  final String? education;
  final DateTime? birthday;

  // Thống kê
  final double ratingAvg;
  final int casesWon;
  final bool isAvailable;
  final DateTime? lawyerCreatedAt;

  // =============================================================
  // LĨNH VỰC HÀNH NGHỀ
  // =============================================================
  final List<String> practiceAreas;

  LawyerModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.gender,
    required this.isActive,
    this.userCreatedAt,
    this.updatedAt,
    required this.title,
    this.barLicenseNo,
    required this.yearsExp,
    this.bio,
    this.address,
    this.education,
    this.birthday,
    required this.ratingAvg,
    required this.casesWon,
    required this.isAvailable,
    this.lawyerCreatedAt,
    required this.practiceAreas,
  });

  // =============================================================
  // FROM JSON
  // =============================================================
  factory LawyerModel.fromJson(Map<String, dynamic> json) {
    return LawyerModel(
      // ===========================================================
      // USER
      // ===========================================================
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      gender: json['gender']?.toString(),
      isActive: _parseBool(json['isActive'], defaultValue: true),
      userCreatedAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      // ===========================================================
      // LAWYER
      // ===========================================================
      title: json['title']?.toString() ?? '',
      barLicenseNo: json['barLicenseNo']?.toString(),
      yearsExp: _parseInt(json['yearsExp']),
      bio: json['bio']?.toString(),
      address: json['address']?.toString(),
      education: json['education']?.toString(),
      birthday: _parseDateTime(json['birthday']),
      // ===========================================================
      // STATISTICS
      // ===========================================================
      ratingAvg: _parseDouble(json['ratingAvg']),
      casesWon: _parseInt(json['casesWon']),
      isAvailable: _parseBool(json['isAvailable'], defaultValue: true),
      lawyerCreatedAt: _parseDateTime(json['createdAt']),

      // ===========================================================
      // PRACTICE AREAS
      // ===========================================================
      practiceAreas: _parsePracticeAreas(json['practiceAreas']),
    );
  }

  // =============================================================
  // TO JSON
  // =============================================================
  Map<String, dynamic> toJson() {
    return {
      // ===========================================================
      // USER
      // ===========================================================
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'gender': gender,
      'isActive': isActive,
      'createdAt': userCreatedAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      // ===========================================================
      // LAWYER
      // ===========================================================
      'title': title,
      'barLicenseNo': barLicenseNo,
      'yearsExp': yearsExp,
      'bio': bio,
      'address': address,
      'education': education,
      'birthday': birthday?.toIso8601String(),
      'ratingAvg': ratingAvg,
      'casesWon': casesWon,
      'isAvailable': isAvailable,
      // ===========================================================
      // PRACTICE AREAS
      // ===========================================================
      'practiceAreas': practiceAreas,
    };
  }

  // =============================================================
  // PARSE INT
  // =============================================================
  static int _parseInt(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.toInt();
    }
    return int.tryParse(value.toString()) ?? 0;
  }

  // =============================================================
  // PARSE DOUBLE
  // =============================================================
  static double _parseDouble(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    return double.tryParse(value.toString()) ?? 0;
  }

  // =============================================================
  // PARSE BOOL
  // =============================================================
  static bool _parseBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) {
      return defaultValue;
    }
    if (value is bool) {
      return value;
    }
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == '0') {
        return false;
      }
    }
    if (value is int) {
      return value == 1;
    }
    return defaultValue;
  }

  // =============================================================
  // PARSE DATETIME
  // =============================================================
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.tryParse(value.toString());
  }

  // =============================================================
  // PARSE PRACTICE AREAS
  // =============================================================
  static List<String> _parsePracticeAreas(dynamic value) {
    if (value == null) {
      return [];
    }
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return [];
  }
}
