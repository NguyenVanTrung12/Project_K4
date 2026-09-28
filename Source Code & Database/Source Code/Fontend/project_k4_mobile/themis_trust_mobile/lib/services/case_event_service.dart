import '../models/case_event_model.dart';
import 'api_service.dart';

class CaseEventService {
  final ApiService _api = ApiService();

  Future<List<CaseEventModel>> getByCase(
      String caseId,
      ) async {
    final data = await _api.get(
      '/CaseEvents/case/$caseId',
    );

    final List<dynamic> list = data;

    return list
        .map(
          (json) => CaseEventModel.fromJson(
        json as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  Future<CaseEventModel> getById(
      String id,
      ) async {
    final data = await _api.get(
      '/CaseEvents/$id',
    );

    return CaseEventModel.fromJson(data);
  }

  Future<CaseEventModel> create(
      Map<String, dynamic> body,
      ) async {
    final data = await _api.post(
      '/CaseEvents',
      body: body,
    );

    return CaseEventModel.fromJson(data);
  }

  Future<CaseEventModel> update(
      String id,
      Map<String, dynamic> body,
      ) async {
    final data = await _api.put(
      '/CaseEvents/$id',
      body: body,
    );

    return CaseEventModel.fromJson(data);
  }
}