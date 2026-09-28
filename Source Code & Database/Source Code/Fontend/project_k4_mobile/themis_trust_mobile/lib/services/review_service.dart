import '../models/review_model.dart';
import 'api_service.dart';

class ReviewService {
  final ApiService _api = ApiService();

  Future<List<ReviewModel>> getByLawyer(
      String lawyerId,
      ) async {
    final data = await _api.get(
      '/Reviews/lawyer/$lawyerId',
    );

    final List<dynamic> list = data;

    return list
        .map(
          (json) => ReviewModel.fromJson(
        json as Map<String, dynamic>,
      ),
    )
        .toList();
  }


  Future<List<ReviewModel>> getReviews() async {
    final data = await _api.get(
      '/Reviews/latest',
      queryParameters: {
        'take': '3',
      },
    );

    final List<dynamic> list = data;

    return list
        .map(
          (json) => ReviewModel.fromJson(
        json as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  Future<ReviewModel> create(
      Map<String, dynamic> body,
      ) async {
    final data = await _api.post(
      '/Reviews',
      body: body,
    );

    return ReviewModel.fromJson(data);
  }
}