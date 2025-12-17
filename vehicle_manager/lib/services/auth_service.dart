import 'package:vehicle_manager/services/api_service.dart';

class AuthService {
  static Future<bool> signUp(String email, String password) async {
    try {
      await ApiService.signUp(email, password);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> login(String email, String password) async {
    try {
      await ApiService.login(email, password);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> logout() async {
    await ApiService.clearToken();
  }

  static Future<bool> isLoggedIn() async {
    final token = await ApiService.getToken();
    return token != null && token.isNotEmpty;
  }
}
