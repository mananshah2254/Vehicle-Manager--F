import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vehicle_manager/services/config.dart';

class ApiService {
  static String get baseUrl => ApiConfig.getBaseUrl();
  
  static String? _token;

  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (includeAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    try {
      final body = json.decode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return body;
      } else {
        final errorMessage = body['error'] ?? body['message'] ?? 'Request failed';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to parse response: ${response.body}');
    }
  }

  static Uri _buildUri(String path) {
    // If baseUrl starts with '/', it's a relative path - use current origin
    // If baseUrl starts with 'http', it's absolute - use as is
    if (baseUrl.startsWith('/')) {
      return Uri.parse('$baseUrl$path');
    } else {
      return Uri.parse('$baseUrl$path');
    }
  }

  // Auth endpoints
  static Future<Map<String, dynamic>> signUp(String email, String password) async {
    final response = await http.post(
      _buildUri('/auth/signup'),
      headers: _getHeaders(includeAuth: false),
      body: json.encode({'email': email, 'password': password}),
    );
    
    final result = await _handleResponse(response);
    if (result['token'] != null) {
      await setToken(result['token']);
    }
    return result;
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      _buildUri('/auth/login'),
      headers: _getHeaders(includeAuth: false),
      body: json.encode({'email': email, 'password': password}),
    );
    
    final result = await _handleResponse(response);
    if (result['token'] != null) {
      await setToken(result['token']);
    }
    return result;
  }

  // Vehicle endpoints
  static Future<List<dynamic>> getVehicles() async {
    await getToken(); // Ensure token is loaded
    final response = await http.get(
      _buildUri('/vehicles'),
      headers: _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data;
    } else {
      final body = json.decode(response.body);
      throw Exception(body['error'] ?? 'Request failed');
    }
  }

  static Future<void> addVehicle(Map<String, dynamic> vehicle) async {
    await getToken();
    final response = await http.post(
      _buildUri('/vehicles'),
      headers: _getHeaders(),
      body: json.encode(vehicle),
    );
    
    await _handleResponse(response);
  }

  static Future<void> updateVehicle(String id, Map<String, dynamic> vehicle) async {
    await getToken();
    final response = await http.put(
      _buildUri('/vehicles/$id'),
      headers: _getHeaders(),
      body: json.encode(vehicle),
    );
    
    await _handleResponse(response);
  }

  static Future<void> deleteVehicle(String id) async {
    await getToken();
    final response = await http.delete(
      _buildUri('/vehicles/$id'),
      headers: _getHeaders(),
    );
    
    await _handleResponse(response);
  }
}

