import '../models/lawyer_model.dart';
import 'api_service.dart';

class LawyerService {
  final ApiService _api = ApiService();

  // ============================================================
  // GET ALL LAWYERS
  // ============================================================

  Future<List<LawyerModel>> getAll() async {
    final data = await _api.get('/Lawyers');

    final List<dynamic> list = data;

    return list
        .map(
          (json) => LawyerModel.fromJson(
        json as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  Future<List<LawyerModel>> GetLatest() async {
    final data = await _api.get(
      '/Lawyers/latest',
      queryParameters: {
        'take': '4',
      },
    );

    final List<dynamic> list = data;

    return list
        .map(
          (json) => LawyerModel.fromJson(
        json as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  // ============================================================
  // GET LAWYER BY ID
  // ============================================================

  Future<LawyerModel> getLawyerById(
      String id,
      ) async {
    final data = await _api.get('/Lawyers/$id');

    return LawyerModel.fromJson(data);
  }

  // ============================================================
  // GET LAWYER PROFILE
  // ============================================================

  Future<LawyerModel> getProfile(
      String lawyerId,
      ) async {
    final data = await _api.get(
      '/Lawyers/$lawyerId',
    );

    return LawyerModel.fromJson(data);
  }
}