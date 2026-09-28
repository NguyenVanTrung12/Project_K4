import '../models/practice_area_model.dart';
import 'api_service.dart';

class PracticeAreaService {
  final ApiService _api = ApiService();

  Future<List<PracticeAreaModel>> getPracticeAreas() async {
    final data = await _api.get('/PracticeAreas');

    final List<dynamic> list = data;

    return list
        .map(
          (json) => PracticeAreaModel.fromJson(
        json as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  Future<PracticeAreaModel> getPracticeAreaById(
      int id,
      ) async {
    final data = await _api.get(
      '/PracticeAreas/$id',
    );

    return PracticeAreaModel.fromJson(data);
  }
}