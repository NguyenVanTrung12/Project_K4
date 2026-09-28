import '../models/case_model.dart';
import 'api_service.dart';

class CaseService {
  final ApiService _api = ApiService();

  // ============================================================
  // GET ALL CASES
  // ============================================================

  Future<List<CaseModel>> getCases() async {
    final data = await _api.get('/Cases');

    final List<dynamic> list = data;

    return list
        .map(
          (json) => CaseModel.fromJson(
        json as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  // ============================================================
  // GET CASE BY ID
  // ============================================================

  Future<CaseModel> getCaseById(
      String id,
      ) async {
    final data = await _api.get('/Cases/$id');

    return CaseModel.fromJson(data);
  }

  // ============================================================
  // GET CASES BY LAWYER
  // ============================================================

  Future<List<CaseModel>> getCasesByLawyer(
      String lawyerId,
      ) async {
    final data = await _api.get(
      '/Cases/lawyer/$lawyerId',
    );

    final List<dynamic> list = data;

    return list
        .map(
          (json) => CaseModel.fromJson(
        json as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  // ============================================================
  // GET CASES BY CLIENT
  // ============================================================

  Future<List<CaseModel>> getCasesByClient(
      String clientId,
      ) async {
    final data = await _api.get(
      '/Cases/client/$clientId',
    );

    final List<dynamic> list = data;

    return list
        .map(
          (json) => CaseModel.fromJson(
        json as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<CaseModel> createCase(
      Map<String, dynamic> body,
      ) async {
    final data = await _api.post(
      '/Cases',
      body: body,
    );

    return CaseModel.fromJson(data);
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<CaseModel> updateCase(
      String id,
      Map<String, dynamic> body,
      ) async {
    final data = await _api.put(
      '/Cases/$id',
      body: body,
    );

    return CaseModel.fromJson(data);
  }
}