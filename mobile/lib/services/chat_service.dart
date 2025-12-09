import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';

class ChatService {
  static String get baseUrl => dotenv.env['API_URL'] ?? 'http://10.0.2.2:8080';

  // Get list of chats
  static Future<Map<String, dynamic>> getChatList() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/chat/list'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'chats': data['chats']};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Failed to get chats'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get messages with a user
  static Future<Map<String, dynamic>> getMessages(String userId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/chat/$userId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'messages': data['messages'],
          'user': data['user'],
        };
      } else {
        return {'success': false, 'message': data['error'] ?? 'Failed to get messages'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get unread count
  static Future<int> getUnreadCount() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return 0;

      final response = await http.get(
        Uri.parse('$baseUrl/chat/unread-count'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['unread_count'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // Send a message
  static Future<Map<String, dynamic>> sendMessage(String userId, String message) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/chat/$userId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'message': message}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Failed to send message'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
