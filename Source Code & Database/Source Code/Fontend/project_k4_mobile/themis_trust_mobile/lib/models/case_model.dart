import 'case_event_model.dart';

class CaseModel {
  final String id;
  final String docketNo;
  final String title;

  final String clientId;
  final String clientName;

  final String lawyerId;
  final String? lawyerName;

  final int? practiceAreaId;
  final String? practiceAreaName;

  final String status;
  final String? nextStep;
  final String? courtName;

  final DateTime? openedAt;
  final DateTime? closedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final List<CaseEventModel> events;

  CaseModel({
    required this.id,
    required this.docketNo,
    required this.title,
    required this.clientId,
    required this.clientName,
    required this.lawyerId,
    this.lawyerName,
    this.practiceAreaId,
    this.practiceAreaName,
    required this.status,
    this.nextStep,
    this.courtName,
    this.openedAt,
    this.closedAt,
    this.createdAt,
    this.updatedAt,
    this.events = const [],
  });

  // ============================================================
  // FROM JSON
  // ============================================================

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    return CaseModel(
      id: json['id']?.toString() ?? '',
      docketNo: json['docketNo']?.toString() ?? '',
      title: json['title']?.toString() ?? '',

      clientId: json['clientId']?.toString() ?? '',
      clientName: json['clientName']?.toString() ?? '',

      lawyerId: json['lawyerId']?.toString() ?? '',
      lawyerName: json['lawyerName']?.toString(),

      practiceAreaId: _parseInt(
        json['practiceAreaId'],
      ),

      practiceAreaName:
      json['practiceAreaName']?.toString(),

      status:
      json['status']?.toString() ?? 'filed',

      nextStep:
      json['nextStep']?.toString(),

      courtName:
      json['courtName']?.toString(),

      openedAt:
      _parseDate(json['openedAt']),

      closedAt:
      _parseDate(json['closedAt']),

      createdAt:
      _parseDate(json['createdAt']),

      updatedAt:
      _parseDate(json['updatedAt']),

      events: _parseEvents(
        json['events'] ?? json['Events'],
      ),
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'docketNo': docketNo,
      'title': title,

      'clientId': clientId,
      'clientName': clientName,

      'lawyerId': lawyerId,
      'lawyerName': lawyerName,

      'practiceAreaId': practiceAreaId,
      'practiceAreaName': practiceAreaName,

      'status': status,
      'nextStep': nextStep,
      'courtName': courtName,

      'openedAt': openedAt?.toIso8601String(),

      'closedAt': closedAt?.toIso8601String(),

      'createdAt': createdAt?.toIso8601String(),

      'updatedAt': updatedAt?.toIso8601String(),

      'events': events.map((e) => e.toJson()).toList(),
    };
  }

  // ============================================================
  // PARSE DATE
  // ============================================================

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }

    try {
      return DateTime.parse(text);
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // PARSE INT
  // ============================================================

  static int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  // ============================================================
  // PARSE EVENTS
  // ============================================================

  static List<CaseEventModel> _parseEvents(dynamic value) {
    print('================ PARSE EVENTS ================');
    print('RAW EVENTS: $value');
    print('RAW EVENTS TYPE: ${value.runtimeType}');

    if (value == null) {
      print('EVENTS = NULL');
      return [];
    }

    if (value is! List) {
      print('EVENTS KHÔNG PHẢI LIST');
      return [];
    }

    print('EVENT COUNT: ${value.length}');

    final result = <CaseEventModel>[];

    for (final item in value) {
      print('---------------------------------------------');
      print('RAW EVENT: $item');

      if (item is! Map) {
        print('EVENT KHÔNG PHẢI MAP');
        continue;
      }

      try {
        final event = CaseEventModel.fromJson(
          Map<String, dynamic>.from(item),
        );

        print('EVENT PARSED OK');
        print('ID: ${event.id}');
        print('TITLE: ${event.title}');
        print('DATE: ${event.eventDate}');
        print('NOTE: ${event.note}');
        print('DONE: ${event.isDone}');

        result.add(event);
      } catch (e, stackTrace) {
        print('EVENT PARSE ERROR: $e');
        print(stackTrace);
      }
    }

    result.sort(
          (a, b) => a.sortOrder.compareTo(b.sortOrder),
    );

    print('==============================================');
    print('FINAL EVENTS COUNT: ${result.length}');
    print('==============================================');

    return result;
  }
}
