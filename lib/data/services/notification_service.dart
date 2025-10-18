import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String baseUrl = 'http://localhost:3000/notifications';

  // Get all notifications for current user
  Future<Map<String, dynamic>> getUserNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
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
      
      final response = await http.get(
        Uri.parse('$baseUrl/$userId?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'Notifications retrieved successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? errorData['error'] ?? 'Failed to retrieve notifications',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get unread notification count
  Future<Map<String, dynamic>> getUnreadCount() async {
    try {
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
      
      final response = await http.get(
        Uri.parse('$baseUrl/$userId/unread-count'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'Unread count retrieved successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? errorData['error'] ?? 'Failed to get unread count',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Mark notification as read
  Future<Map<String, dynamic>> markAsRead(String notificationId) async {
    try {
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
      
      final response = await http.post(
        Uri.parse('$baseUrl/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'Notification marked as read',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? errorData['error'] ?? 'Failed to mark as read',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Mark all notifications as read
  Future<Map<String, dynamic>> markAllAsRead() async {
    try {
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
      
      final response = await http.post(
        Uri.parse('$baseUrl/$userId/mark-all-read'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'All notifications marked as read',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? errorData['error'] ?? 'Failed to mark all as read',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Delete notification
  Future<Map<String, dynamic>> deleteNotification(String notificationId) async {
    try {
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
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'Notification deleted successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? errorData['error'] ?? 'Failed to delete notification',
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