class LegalServiceModel {
  final int id;
  final int practiceAreaId;
  final String title;
  final String? description;
  final String? detail;
  final double? startingPrice;
  final String? iconKey;
  final int sortOrder;
  final bool isActive;

  LegalServiceModel({
    required this.id,
    required this.practiceAreaId,
    required this.title,
    this.description,
    this.detail,
    this.startingPrice,
    this.iconKey,
    required this.sortOrder,
    required this.isActive,
  });

  factory LegalServiceModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return LegalServiceModel(
      id: json['id'] ?? 0,
      practiceAreaId: json['practiceAreaId'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      detail: json['detail'],
      startingPrice: json['startingPrice'] != null
          ? (json['startingPrice'] as num).toDouble()
          : null,
      iconKey: json['iconKey'],
      sortOrder: json['sortOrder'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'practiceAreaId': practiceAreaId,
      'title': title,
      'description': description,
      'detail': detail,
      'startingPrice': startingPrice,
      'iconKey': iconKey,
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }
}