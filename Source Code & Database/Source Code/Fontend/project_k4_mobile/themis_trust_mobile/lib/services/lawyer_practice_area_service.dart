import '../models/lawyer_practice_area_model.dart';
import 'api_service.dart';

class LawyerPracticeAreaService {
  final ApiService _api = ApiService();

  Future<List<LawyerPracticeAreaModel>>
  getByLawyer(
      String lawyerId,
      ) async {
    final data = await _api.get(
      '/LawyerPracticeAreas/lawyer/$lawyerId',
    );

    final List<dynamic> list = data;

    return list
        .map(
          (json) =>
          LawyerPracticeAreaModel.fromJson(
            json as Map<String, dynamic>,
          ),
    )
        .toList();
  }

  Future<List<LawyerPracticeAreaModel>>
  getByPracticeArea(
      int practiceAreaId,
      ) async {
    final data = await _api.get(
      '/LawyerPracticeAreas/practice-area/$practiceAreaId',
    );

    final List<dynamic> list = data;

    return list
        .map(
          (json) =>
          LawyerPracticeAreaModel.fromJson(
            json as Map<String, dynamic>,
          ),
    )
        .toList();
  }
}