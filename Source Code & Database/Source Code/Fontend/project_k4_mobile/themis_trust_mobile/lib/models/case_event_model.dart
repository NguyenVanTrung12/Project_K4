class CaseEventModel {
  final String id;
  final String caseId;
  final String title;
  final DateTime? eventDate;
  final String? note;
  final bool isDone;
  final int sortOrder;
  final DateTime? createdAt;

  CaseEventModel({
    required this.id,
    required this.caseId,
    required this.title,
    this.eventDate,
    this.note,
    required this.isDone,
    required this.sortOrder,
    this.createdAt,
  });

  factory CaseEventModel.fromJson(Map<String, dynamic> json) {
    return CaseEventModel(
      id: json['id']?.toString() ?? '',
      caseId: json['caseId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      eventDate: _parseDate(
        json['eventDate'] ?? json['EventDate'],
      ),
      note: (json['note'] ?? json['Note'])?.toString(),
      isDone: json['isDone'] == true || json['IsDone'] == true,
      sortOrder: _parseInt(
        json['sortOrder'] ?? json['SortOrder'],
      ),
      createdAt: _parseDate(
        json['createdAt'] ?? json['CreatedAt'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caseId': caseId,
      'title': title,
      'eventDate': eventDate?.toIso8601String(),
      'note': note,
      'isDone': isDone,
      'sortOrder': sortOrder,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    try {
      return DateTime.parse(text);
    } catch (e) {
      print('Không parse được ngày: $value');
      return null;
    }
  }

  static int _parseInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString()) ?? 0;
  }
}