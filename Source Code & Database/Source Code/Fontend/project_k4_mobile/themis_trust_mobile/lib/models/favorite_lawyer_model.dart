class FavoriteLawyerModel {
  final String clientId;
  final String lawyerId;
  final DateTime createdAt;

  FavoriteLawyerModel({
    required this.clientId,
    required this.lawyerId,
    required this.createdAt,
  });

  factory FavoriteLawyerModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return FavoriteLawyerModel(
      clientId: json['clientId'].toString(),
      lawyerId: json['lawyerId'].toString(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'lawyerId': lawyerId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}