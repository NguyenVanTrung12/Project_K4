class PracticeAreaModel {
  final int id;
  final String name;
  final String? iconKey;
  final int sortOrder;

  PracticeAreaModel({
    required this.id,
    required this.name,
    this.iconKey,
    required this.sortOrder,
  });

  factory PracticeAreaModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return PracticeAreaModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      iconKey: json['iconKey'],
      sortOrder: json['sortOrder'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconKey': iconKey,
      'sortOrder': sortOrder,
    };
  }
}