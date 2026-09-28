class LawyerPracticeAreaModel {
  final String lawyerId;
  final int practiceAreaId;
  final bool isPrimary;

  LawyerPracticeAreaModel({
    required this.lawyerId,
    required this.practiceAreaId,
    required this.isPrimary,
  });

  factory LawyerPracticeAreaModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return LawyerPracticeAreaModel(
      lawyerId: json['lawyerId'].toString(),
      practiceAreaId: json['practiceAreaId'] ?? 0,
      isPrimary: json['isPrimary'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lawyerId': lawyerId,
      'practiceAreaId': practiceAreaId,
      'isPrimary': isPrimary,
    };
  }
}