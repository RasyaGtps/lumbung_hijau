import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static String get baseUrl => dotenv.env['API_URL'] ?? 'http://10.0.2.2:8080';
  static const String _tokenKey = 'auth_token';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Save token
        await saveToken(data['token']);
        return {
          'success': true,
          'token': data['token'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Login gagal',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password, {
    String? schoolName,
  }) async {
    try {
      final body = {
        'name': name,
        'email': email,
        'password': password,
      };
      if (schoolName != null && schoolName.isNotEmpty) {
        body['school_name'] = schoolName;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Save token - user is logged in directly after registration
        if (data['token'] != null) {
          await saveToken(data['token']);
        }
        return {
          'success': true,
          'token': data['token'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Registrasi gagal',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? namaSekolah,
    dynamic photo,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/profile'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['name'] = name;
      if (namaSekolah != null) {
        request.fields['school_name'] = namaSekolah;
      }

      if (photo != null) {
        request.files.add(await http.MultipartFile.fromPath('picture', photo.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Profile updated',
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Update failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getMe() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No token found',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to get user data',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}
