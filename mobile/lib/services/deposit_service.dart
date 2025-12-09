import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/auth_service.dart';

class DepositService {
  static String get baseUrl => dotenv.env['API_URL'] ?? 'http://10.0.2.2:8080';

  static Future<Map<String, dynamic>> createDeposit({
    required String schoolName,
    required String contactName,
    required String contactPhone,
    required String address,
    required String pickupDate,
    required int binCount,
    required String wasteType,
    File? photo,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/deposits'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields
      request.fields['school_name'] = schoolName;
      request.fields['contact_name'] = contactName;
      request.fields['contact_phone'] = contactPhone;
      request.fields['address'] = address;
      request.fields['pickup_date'] = pickupDate;
      request.fields['bin_count'] = binCount.toString();
      request.fields['waste_type'] = wasteType;

      // Add photo if provided
      if (photo != null) {
        request.files.add(await http.MultipartFile.fromPath('photo', photo.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'],
          'deposit': data['deposit'],
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to create deposit',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getMyDeposits() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/deposits'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'deposits': data['deposits'],
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to get deposits',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getDepositById(String depositId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/deposits/$depositId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'deposit': data['deposit'],
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to get deposit',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getAllDeposits() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/admin/deposits'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'deposits': data['deposits'],
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to get deposits',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> updateDepositStatus(String depositId, {String? status, double? weight}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final body = <String, dynamic>{};
      if (status != null) body['status'] = status;
      if (weight != null) body['weight'] = weight;

      final response = await http.put(
        Uri.parse('$baseUrl/admin/deposits/$depositId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'deposit': data['deposit'],
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to update deposit',
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
