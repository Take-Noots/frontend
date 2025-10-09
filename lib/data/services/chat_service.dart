import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  static const String baseUrl = 'http://localhost:3000/chat';
  static const String userBaseUrl = 'http://localhost:3000/user'; // Fixed: changed from 'users' to 'user'

  // Search users by username
  Future<Map<String, dynamic>> searchUsers(String query) async {
    try {
      print('🔍 Searching for users with query: $query'); // Debug log
      
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      if (userDataString == null) {
        return {
          'success': false,
          'message': 'User not logged in. Please log in to search users.',
        };
      }
      
      final url = '$userBaseUrl/search?q=$query';
      print('🌐 Making request to: $url'); // Debug log
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📡 Response status: ${response.statusCode}'); // Debug log
      print('📡 Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Search successful, found ${data.length} users'); // Debug log
        return {
          'success': true,
          'data': data,
          'message': 'Users retrieved successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        print('❌ Search failed: ${errorData}'); // Debug log
        return {
          'success': false,
          'message': errorData['message'] ?? errorData['error'] ?? 'Failed to search users',
        };
      }
    } catch (e) {
      print('❌ Network error during search: $e'); // Debug log
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get all chats for the current user
  Future<Map<String, dynamic>> getUserChats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      if (userDataString == null) {
        return {
          'success': false,
          'message': 'User not logged in. Please log in to view chats.',
        };
      }
      
      final userData = jsonDecode(userDataString);
      final userId = userData['id'];
      
      final response = await http.get(
        Uri.parse('$baseUrl/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'Chats retrieved successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ?? 'Failed to retrieve chats',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get messages for a specific chat
  Future<Map<String, dynamic>> getChatMessages(String chatId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/messages/$chatId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'Messages retrieved successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ?? 'Failed to retrieve messages',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Send a message
  Future<Map<String, dynamic>> sendMessage(String chatId, String text) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      if (userDataString == null) {
        return {
          'success': false,
          'message': 'User not logged in. Please log in to send messages.',
        };
      }
      
      final userData = jsonDecode(userDataString);
      
      final response = await http.post(
        Uri.parse('$baseUrl/send'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'chatId': chatId,
          'senderId': userData['id'],
          'senderUsername': userData['username'] ?? userData['name'] ?? 'Unknown',
          'text': text,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'Message sent successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ?? 'Failed to send message',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Create a new chat
  Future<Map<String, dynamic>> createChat(String receiverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      if (userDataString == null) {
        return {
          'success': false,
          'message': 'User not logged in. Please log in to create chat.',
        };
      }
      
      final userData = jsonDecode(userDataString);
      
      final response = await http.post(
        Uri.parse('$baseUrl/create'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'senderId': userData['id'],
          'receiverId': receiverId,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'Chat created successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ?? 'Failed to create chat',
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