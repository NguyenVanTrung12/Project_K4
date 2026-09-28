import '../models/case_document_model.dart';
import 'api_service.dart';

class CaseDocumentService {
  final ApiService _api = ApiService();

  Future<List<CaseDocumentModel>> getByCase(
      String caseId,
      ) async {
    final data = await _api.get(
      '/CaseDocuments/case/$caseId',
    );

    final List<dynamic> list = data;

    return list
        .map(
          (json) => CaseDocumentModel.fromJson(
        json as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  Future<CaseDocumentModel> getById(
      String id,
      ) async {
    final data = await _api.get(
      '/CaseDocuments/$id',
    );

    return CaseDocumentModel.fromJson(data);
  }

  Future<CaseDocumentModel> create(
      Map<String, dynamic> body,
      ) async {
    final data = await _api.post(
      '/CaseDocuments',
      body: body,
    );

    return CaseDocumentModel.fromJson(data);
  }

  Future<void> delete(
      String id,
      ) async {
    await _api.delete(
      '/CaseDocuments/$id',
    );
  }
}