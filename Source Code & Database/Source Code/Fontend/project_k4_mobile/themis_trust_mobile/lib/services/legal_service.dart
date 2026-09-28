import '../models/legal_service_model.dart';
import 'api_service.dart';

class LegalService {
  final ApiService _api = ApiService();

  // ============================================================
  // GET ALL
  // ============================================================

  Future<List<LegalServiceModel>>
  getLegalServices() async {
    final data = await _api.get(
      '/LegalServices',
    );

    final List<dynamic> list = data;

    return list
        .map(
          (json) => LegalServiceModel.fromJson(
        json as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  // ============================================================
  // GET BY ID
  // ============================================================

  Future<LegalServiceModel> getLegalServiceById(
      int id,
      ) async {
    final data = await _api.get(
      '/LegalServices/$id',
    );

    return LegalServiceModel.fromJson(data);
  }

  // ============================================================
  // GET BY PRACTICE AREA
  // ============================================================

  Future<List<LegalServiceModel>>
  getByPracticeArea(
      int practiceAreaId,
      ) async {
    final data = await _api.get(
      '/LegalServices/practice-area/$practiceAreaId',
    );

    final List<dynamic> list = data;

    return list
        .map(
          (json) => LegalServiceModel.fromJson(
        json as Map<String, dynamic>,
      ),
    )
        .toList();
  }
}