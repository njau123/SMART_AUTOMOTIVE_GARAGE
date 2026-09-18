import '../../../../core/services/api_client.dart';
class VehicleApiDataSource {
  Future<List<dynamic>> getVehicles(String accessToken) async {
    try {
      final data = await ApiClient.get('vehicles/', headers: {'Authorization': 'Bearer $accessToken'});
      if (data is List) return data;
      if (data is Map && data['results'] != null) return data['results'] as List;
      return [];
    } catch (_) { return []; }
  }
}
