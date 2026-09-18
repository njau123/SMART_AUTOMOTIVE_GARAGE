import '../../../../core/services/api_client.dart';
class AuthApiDataSource {
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final data = await ApiClient.post('auth/login/', body: {'email': email, 'password': password});
      return data as Map<String, dynamic>;
    } catch (_) { return null; }
  }
  Future<Map<String, dynamic>?> register({required String email, required String password, required String firstName, required String lastName, required String phone}) async {
    try {
      final data = await ApiClient.post('auth/register/', body: {'email': email, 'password': password, 'first_name': firstName, 'last_name': lastName, 'phone': phone});
      return data as Map<String, dynamic>;
    } catch (_) { return null; }
  }
  Future<Map<String, dynamic>?> refreshToken(String refresh) async {
    try {
      final data = await ApiClient.post('auth/token/refresh/', body: {'refresh': refresh});
      return data as Map<String, dynamic>;
    } catch (_) { return null; }
  }
}
