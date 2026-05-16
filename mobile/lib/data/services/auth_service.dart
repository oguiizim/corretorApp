import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  const AuthService(this._apiClient);

  final ApiClient _apiClient;

  Future<void> login({required String email, required String password}) {
    return _apiClient.login(email: email, password: password);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _apiClient.register(name: name, email: email, password: password);
  }

  Future<User> getCurrentUser() {
    return _apiClient.getCurrentUser();
  }

  Future<User> updateProfile({
    required int id,
    required String name,
    required String email,
    required String password,
  }) {
    return _apiClient.updateUser(
      id: id,
      name: name,
      email: email,
      password: password,
    );
  }
}
