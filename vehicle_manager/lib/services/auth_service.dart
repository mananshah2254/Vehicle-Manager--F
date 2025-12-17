import 'package:vehicle_manager/services/api_service.dart';

class AuthService {
  static String? lastError;

  static Future<bool> signUp(String email, String password) async {
    try {
      lastError = null;
      await ApiService.signUp(email, password);
      return true;
    } catch (e) {
      lastError = e.toString().replaceAll('Exception: ', '');
      return false;
    }
  }

  static Future<bool> login(String email, String password) async {
    try {
      lastError = null;
      await ApiService.login(email, password);
      return true;
    } catch (e) {
      lastError = e.toString().replaceAll('Exception: ', '');
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
