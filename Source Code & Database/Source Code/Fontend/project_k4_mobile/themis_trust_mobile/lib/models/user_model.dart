class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? phone;

  // ============================================================
  // THÔNG TIN CÁ NHÂN
  // ============================================================

  final String? gender;
  final DateTime? dateOfBirth;
  final String? address;

  // ============================================================
  // THÔNG TIN TÀI KHOẢN
  // ============================================================

  final String? passwordHash;
  final String role;
  final String? avatarUrl;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,

    // Thông tin cá nhân
    this.gender,
    this.dateOfBirth,
    this.address,

    // Thông tin tài khoản
    this.passwordHash,
    required this.role,
    this.avatarUrl,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  // ============================================================
  // FROM JSON
  // ============================================================

  factory UserModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return UserModel(
      // ========================================================
      // BASIC
      // ========================================================

      id: json['id']?.toString() ?? '',

      fullName:
      json['fullName']?.toString() ?? '',

      email:
      json['email']?.toString() ?? '',

      phone:
      json['phone']?.toString(),

      // ========================================================
      // THÔNG TIN CÁ NHÂN
      // ========================================================

      gender:
      json['gender']?.toString(),

      dateOfBirth:
      json['dateOfBirth'] != null
          ? DateTime.tryParse(
        json['dateOfBirth']
            .toString(),
      )
          : null,

      address:
      json['address']?.toString(),

      // ========================================================
      // ACCOUNT
      // ========================================================

      passwordHash:
      json['passwordHash']?.toString(),

      role:
      json['role']?.toString() ?? 'client',

      avatarUrl:
      json['avatarUrl']?.toString(),

      isActive:
      json['isActive'] ?? true,

      // ========================================================
      // TIMESTAMP
      // ========================================================

      createdAt:
      json['createdAt'] != null
          ? DateTime.tryParse(
        json['createdAt']
            .toString(),
      )
          : null,

      updatedAt:
      json['updatedAt'] != null
          ? DateTime.tryParse(
        json['updatedAt']
            .toString(),
      )
          : null,
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      // ========================================================
      // BASIC
      // ========================================================

      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,

      // ========================================================
      // THÔNG TIN CÁ NHÂN
      // ========================================================

      'gender': gender,

      'dateOfBirth':
      dateOfBirth?.toIso8601String(),

      'address': address,

      // ========================================================
      // ACCOUNT
      // ========================================================

      'passwordHash': passwordHash,
      'role': role,
      'avatarUrl': avatarUrl,
      'isActive': isActive,

      // ========================================================
      // TIMESTAMP
      // ========================================================

      'createdAt':
      createdAt?.toIso8601String(),

      'updatedAt':
      updatedAt?.toIso8601String(),
    };
  }
}