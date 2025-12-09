import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';

class NotificationService {
  static String get baseUrl => dotenv.env['API_URL'] ?? 'http://10.0.2.2:8080';

  // Get all notifications
  static Future<Map<String, dynamic>> getNotifications() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'notifications': data['notifications']};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Failed to get notifications'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get unread notification count
  static Future<int> getUnreadCount() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return 0;

      final response = await http.get(
        Uri.parse('$baseUrl/notifications/unread-count'),
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

  // Mark notification as read
  static Future<Map<String, dynamic>> markAsRead(String notifId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$notifId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'message': data['error'] ?? 'Failed to mark as read'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Mark all notifications as read
  static Future<Map<String, dynamic>> markAllAsRead() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/notifications/read-all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'message': data['error'] ?? 'Failed to mark all as read'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
