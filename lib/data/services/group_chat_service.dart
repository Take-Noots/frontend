import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class GroupChatService {
  static String get baseUrl => '${AppConstants.baseUrl}/chat';

  // Create a new group chat
  Future<Map<String, dynamic>> createGroupChat({
    required String name,
    String? description,
    String? groupIcon,
    required List<String> memberIds,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');

      if (userDataString == null) {
        return {
          'success': false,
          'message': 'User not logged in. Please log in to create group chat.',
        };
      }

      final userData = jsonDecode(userDataString);

      final response = await http.post(
        Uri.parse('$baseUrl/group/create'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'description': description,
          'groupIcon': groupIcon,
          'createdBy': userData['id'],
          'memberIds': memberIds,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'Group chat created successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ?? 'Failed to create group chat',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get all group chats for the current user
  Future<Map<String, dynamic>> getUserGroupChats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');

      if (userDataString == null) {
        return {
          'success': false,
          'message': 'User not logged in. Please log in to view group chats.',
        };
      }

      final userData = jsonDecode(userDataString);
      final userId = userData['id'];

      final response = await http.get(
        Uri.parse('$baseUrl/group/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'Group chats retrieved successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ?? 'Failed to retrieve group chats',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get messages for a specific group chat
  Future<Map<String, dynamic>> getGroupChatMessages(String groupChatId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/group/messages/$groupChatId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'Group messages retrieved successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ?? 'Failed to retrieve group messages',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Send a message to group chat
  Future<Map<String, dynamic>> sendGroupMessage(
      String groupChatId, String text) async {
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
        Uri.parse('$baseUrl/group/send'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'groupChatId': groupChatId,
          'senderId': userData['id'],
          'senderUsername':
              userData['username'] ?? userData['name'] ?? 'Unknown',
          'text': text,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'Group message sent successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ?? 'Failed to send group message',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get group chat details
  Future<Map<String, dynamic>> getGroupChatDetails(String groupChatId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/group/details/$groupChatId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'Group details retrieved successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ?? 'Failed to retrieve group details',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Update group chat details
  Future<Map<String, dynamic>> updateGroupChat({
    required String groupChatId,
    String? name,
    String? description,
    String? groupIcon,
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

      final Map<String, dynamic> updateData = {};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (groupIcon != null) updateData['groupIcon'] = groupIcon;

      final response = await http.put(
        Uri.parse('$baseUrl/group/update/$groupChatId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'Group updated successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ?? 'Failed to update group',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Add member to group
  Future<Map<String, dynamic>> addMemberToGroup(
      String groupChatId, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/group/addMember'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'groupChatId': groupChatId,
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'Member added successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ?? 'Failed to add member',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Remove member from group
  Future<Map<String, dynamic>> removeMemberFromGroup(
      String groupChatId, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/group/removeMember'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'groupChatId': groupChatId,
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'Member removed successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ?? 'Failed to remove member',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Leave group (handles both regular members and group creators)
  Future<Map<String, dynamic>> leaveGroup(
      String groupChatId, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/group/leaveGroup'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'groupChatId': groupChatId,
          'userId': userId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': data['message'] ?? 'Left group successfully',
          'deleted': data['deleted'] ?? false,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ?? errorData['message'] ?? 'Failed to leave group',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Upload group icon using base64
  Future<Map<String, dynamic>> uploadGroupIconBase64({
    required String groupChatId,
    required String imageBase64,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/group/$groupChatId/upload-group-icon-base64'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'imageData': imageBase64,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? true,
          'data': data,
          'message': data['message'] ?? 'Group icon uploaded successfully',
          'imageUrl': data['imageUrl'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to upload group icon',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Upload group icon using file
  Future<Map<String, dynamic>> uploadGroupIconFile({
    required String groupChatId,
    required File imageFile,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/group/$groupChatId/upload-group-icon'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'groupIcon',
          imageFile.path,
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? true,
          'data': data,
          'message': data['message'] ?? 'Group icon uploaded successfully',
          'imageUrl': data['imageUrl'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to upload group icon',
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
