import '../models/appointment_model.dart';
import 'api_service.dart';

class AppointmentService {
  final ApiService _api = ApiService();

  // ==========================================================
  // LẤY DANH SÁCH LỊCH HẸN
  // ==========================================================

  Future<List<AppointmentModel>> getAppointments({
    DateTime? date,
  }) async {
    String endpoint = '/appointments';

    if (date != null) {
      final dateString =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';

      endpoint =
      '/appointments?date=$dateString';
    }

    final data =
    await _api.get(endpoint);

    final List<dynamic> list =
    data as List<dynamic>;

    return list
        .map(
          (json) =>
          AppointmentModel.fromJson(
            json as Map<String, dynamic>,
          ),
    )
        .toList();
  }

  // ==========================================================
  // KIỂM TRA KHUNG GIỜ TRỐNG
  //
  // GET /api/appointments/availability
  // ==========================================================

  Future<List<String>> getAvailability({
    required String lawyerId,
    required DateTime date,
  }) async {
    final dateString =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final endpoint =
        '/appointments/availability'
        '?lawyerId=$lawyerId'
        '&date=${Uri.encodeComponent(dateString)}';

    final data =
    await _api.get(endpoint);

    final List<dynamic> list =
    data as List<dynamic>;

    return list
        .map(
          (item) => item.toString(),
    )
        .toList();
  }

  // ==========================================================
  // ĐẶT LỊCH
  //
  // POST /api/appointments
  // ==========================================================

  Future<AppointmentModel> createAppointment({
    required String clientId,
    required String lawyerId,
    required DateTime scheduledAt,
    int durationMin = 30,
    String? description,
    String? caseId,
  }) async {
    final Map<String, dynamic> body = {
      'clientId': clientId,
      'lawyerId': lawyerId,

      'scheduledAt':
      scheduledAt.toIso8601String(),

      'durationMin':
      durationMin,

      if (description != null &&
          description.trim().isNotEmpty)
        'description':
        description.trim(),

      if (caseId != null &&
          caseId.isNotEmpty)
        'caseId': caseId,
    };

    print(
      '========================================',
    );

    print(
      '[APPOINTMENT] POST /appointments',
    );

    print(
      '[APPOINTMENT] body = $body',
    );

    print(
      '========================================',
    );

    final data =
    await _api.post(
      '/appointments',
      body: body,
    );

    print(
      '[APPOINTMENT] response = $data',
    );

    return AppointmentModel.fromJson(
      data as Map<String, dynamic>,
    );
  }
}