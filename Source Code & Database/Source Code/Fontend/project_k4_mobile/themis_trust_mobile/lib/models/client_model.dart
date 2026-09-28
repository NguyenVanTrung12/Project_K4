class ClientModel {
  // =========================
  // USER
  // =========================

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final String? avatarUrl;
  final bool isActive;
  final DateTime createdAt;

  // =========================
  // CLIENT
  // =========================

  final String? idNumber;
  final String? address;
  final DateTime? dateOfBirth;

  // =========================
  // GENDER
  // =========================

  final String? gender;

  ClientModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    this.avatarUrl,
    required this.isActive,
    this.idNumber,
    this.address,
    this.dateOfBirth,
    this.gender,
    required this.createdAt,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      isActive: json['isActive'] == true,

      idNumber: json['idNumber']?.toString(),
      address: json['address']?.toString(),

      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString())
          : null,

      gender: json['gender']?.toString(),

      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // USER
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'avatarUrl': avatarUrl,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),

      // CLIENT
      'idNumber': idNumber,
      'address': address,
      'dateOfBirth': dateOfBirth?.toIso8601String(),

      // GENDER
      'gender': gender,
    };
  }
}