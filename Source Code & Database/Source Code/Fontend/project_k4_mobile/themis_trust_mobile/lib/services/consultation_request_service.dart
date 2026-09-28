import '../models/consultation_request_model.dart';
import 'api_service.dart';

class ConsultationRequestService {
  final ApiService _api = ApiService();

  // ==========================================================
  // GET ALL REQUESTS
  // ==========================================================

  Future<List<ConsultationRequestModel>> getRequests() async {
    final data = await _api.get(
      '/consultation-requests',
    );

    final List<dynamic> list =
    data as List<dynamic>;

    return list
        .map(
          (json) =>
          ConsultationRequestModel.fromJson(
            json as Map<String, dynamic>,
          ),
    )
        .toList();
  }

  // ==========================================================
  // GET BY ID
  // ==========================================================

  Future<ConsultationRequestModel> getById(
      String id,
      ) async {
    final data = await _api.get(
      '/consultation-requests/$id',
    );

    return ConsultationRequestModel.fromJson(
      data as Map<String, dynamic>,
    );
  }

  // ==========================================================
  // GET BY LAWYER
  // ==========================================================

  Future<List<ConsultationRequestModel>> getByLawyer(
      String lawyerId,
      ) async {
    final data = await _api.get(
      '/consultation-requests/lawyer/$lawyerId',
    );

    final List<dynamic> list =
    data as List<dynamic>;

    return list
        .map(
          (json) =>
          ConsultationRequestModel.fromJson(
            json as Map<String, dynamic>,
          ),
    )
        .toList();
  }

  // ==========================================================
  // GET BY CLIENT
  // ==========================================================

  Future<List<ConsultationRequestModel>> getByClient(
      String clientId,
      ) async {
    final data = await _api.get(
      '/consultation-requests/client/$clientId',
    );

    final List<dynamic> list =
    data as List<dynamic>;

    return list
        .map(
          (json) =>
          ConsultationRequestModel.fromJson(
            json as Map<String, dynamic>,
          ),
    )
        .toList();
  }

  // ==========================================================
  // CREATE CONSULTATION REQUEST
  // ==========================================================

  Future<ConsultationRequestModel> create({
    required String title,
    required String description,
    required String priority,

    int? practiceAreaId,

    String? lawyerId,

    String? attachmentUrl,
  }) async {
    final Map<String, dynamic> body = {
      'title': title,
      'description': description,
      'priority': priority,

      if (practiceAreaId != null)
        'practiceAreaId': practiceAreaId,

      if (lawyerId != null &&
          lawyerId.isNotEmpty)
        'lawyerId': lawyerId,

      if (attachmentUrl != null &&
          attachmentUrl.isNotEmpty)
        'attachmentUrl': attachmentUrl,
    };

    print(
      '[CONSULTATION REQUEST] POST /consultation-requests',
    );

    print(
      '[CONSULTATION REQUEST] body = $body',
    );

    final data = await _api.post(
      '/consultation-requests',
      body: body,
    );

    print(
      '[CONSULTATION REQUEST] response = $data',
    );

    return ConsultationRequestModel.fromJson(
      data as Map<String, dynamic>,
    );
  }

  // ==========================================================
  // UPDATE
  // ==========================================================

  Future<ConsultationRequestModel> update(
      String id,
      Map<String, dynamic> body,
      ) async {
    final data = await _api.put(
      '/consultation-requests/$id',
      body: body,
    );

    return ConsultationRequestModel.fromJson(
      data as Map<String, dynamic>,
    );
  }
}