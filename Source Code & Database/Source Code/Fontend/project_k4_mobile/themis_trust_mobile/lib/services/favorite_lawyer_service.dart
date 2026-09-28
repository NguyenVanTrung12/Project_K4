import '../models/favorite_lawyer_model.dart';
import 'api_service.dart';

class FavoriteLawyerService {
  final ApiService _api = ApiService();

  // ============================================================
  // GET FAVORITES
  // ============================================================

  Future<List<FavoriteLawyerModel>>
  getByClient(
      String clientId,
      ) async {
    final data = await _api.get(
      '/FavoriteLawyers/client/$clientId',
    );

    final List<dynamic> list = data;

    return list
        .map(
          (json) =>
          FavoriteLawyerModel.fromJson(
            json as Map<String, dynamic>,
          ),
    )
        .toList();
  }

  // ============================================================
  // ADD FAVORITE
  // ============================================================

  Future<FavoriteLawyerModel> add({
    required String clientId,
    required String lawyerId,
  }) async {
    final data = await _api.post(
      '/FavoriteLawyers',
      body: {
        'clientId': clientId,
        'lawyerId': lawyerId,
      },
    );

    return FavoriteLawyerModel.fromJson(data);
  }

  // ============================================================
  // REMOVE FAVORITE
  // ============================================================

  Future<void> remove({
    required String clientId,
    required String lawyerId,
  }) async {
    await _api.delete(
      '/FavoriteLawyers/$clientId/$lawyerId',
    );
  }
}