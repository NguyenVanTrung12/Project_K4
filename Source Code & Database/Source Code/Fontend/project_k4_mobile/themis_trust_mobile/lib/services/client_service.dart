import '../models/client_model.dart';
import 'api_service.dart';

class ClientService {
  final ApiService _api = ApiService();

  Future<List<ClientModel>> getClients() async {
    final data = await _api.get('/Clients');

    final List<dynamic> list = data;

    return list
        .map(
          (json) => ClientModel.fromJson(
        json as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  Future<ClientModel> getClientById(
      String id,
      ) async {
    final data = await _api.get('/Clients/$id');

    return ClientModel.fromJson(data);
  }

  Future<ClientModel> updateClient(
      String id,
      Map<String, dynamic> data,
      ) async {
    final result = await _api.put(
      '/Clients/$id',
      body: data,
    );

    return ClientModel.fromJson(result);
  }
}