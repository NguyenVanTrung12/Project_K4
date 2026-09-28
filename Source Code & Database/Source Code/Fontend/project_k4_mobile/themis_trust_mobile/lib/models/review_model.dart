class ReviewModel {
  final String id;
  final String lawyerId;
  final String clientId;
  final String? caseId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String? clientName;

  ReviewModel({
    required this.id,
    required this.lawyerId,
    required this.clientId,
    this.caseId,
    this.clientName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return ReviewModel(
      id: json['id'].toString(),
      lawyerId: json['lawyerId'].toString(),
      clientId: json['clientId'].toString(),
      clientName: json['clientName']?.toString(),
      caseId: json['caseId']?.toString(),
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lawyerId': lawyerId,
      'clientId': clientId,
      'caseId': caseId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}