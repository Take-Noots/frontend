import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';
class NotificationService {
  
  // Initialize secure storage
  static const _secureStorage = FlutterSecureStorage();
  static final String baseUrl = AppConstants.baseUrl + '/notifications';

  // Get authorization headers with Bearer token
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _secureStorage.read(key: 'access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Get all notifications for current user using authenticated endpoint
  Future<Map<String, dynamic>> getUserNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/my-notifications?page=$page&limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'], // The new endpoint returns data wrapped in a 'data' field
          'message': 'Notifications retrieved successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ??
              errorData['error'] ??
              'Failed to retrieve notifications',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get unread notification count using authenticated endpoint
  Future<Map<String, dynamic>> getUnreadCount() async {
    try {
      final headers = await _getAuthHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/my-notifications/unread-count'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'], // The new endpoint returns data wrapped in a 'data' field
          'message': 'Unread count retrieved successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ??
              errorData['error'] ??
              'Failed to get unread count',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Mark notification as read using authenticated endpoint
  Future<Map<String, dynamic>> markAsRead(String notificationId) async {
    try {
      final headers = await _getAuthHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/mark-as-read/$notificationId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': 'Notification marked as read',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ??
              errorData['error'] ??
              'Failed to mark as read',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Mark all notifications as read using authenticated endpoint
  Future<Map<String, dynamic>> markAllAsRead() async {
    try {
      final headers = await _getAuthHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/mark-all-read'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': 'All notifications marked as read',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ??
              errorData['error'] ??
              'Failed to mark all as read',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Delete notification (keeping old endpoint as backend doesn't have authenticated version yet)
  Future<Map<String, dynamic>> deleteNotification(String notificationId) async {
    try {
      final headers = await _getAuthHeaders();

      // Get user data for fallback if needed
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');

      if (userDataString == null) {
        return {
          'success': false,
          'message': 'User not logged in.',
        };
      }

      final userData = jsonDecode(userDataString);
      final userId = userData['id'];

      final response = await http.delete(
        Uri.parse('$baseUrl/$notificationId'),
        headers: headers,
        body: jsonEncode({
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? data,
          'message': 'Notification deleted successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ??
              errorData['error'] ??
              'Failed to delete notification',
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
