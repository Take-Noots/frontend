import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ThoughtsService {
  final String baseUrl = 'http://localhost:3000';

  // Create a new thoughts post
  Future<Map<String, dynamic>> createThoughts({
    required String text,
    String? songName,
    String? artistName,
  }) async {
    try {
      // Get user data from shared preferences 
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      // Check if user is logged in
      if (userDataString == null) {
        return {
          'success': false,
          'message': 'User not logged in. Please log in to share thoughts.',
        };
      }
      
      final userData = jsonDecode(userDataString);
      
      // Validate that we have the required user data
      if (userData['id'] == null) {
        return {
          'success': false,
          'message': 'Invalid user data. Please log in again.',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/thoughts'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userData['id'],
          'text': text,
          if (songName != null) 'songName': songName,
          if (artistName != null) 'artistName': artistName,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
          'message': 'Thoughts shared successfully!'
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to share thoughts: ${response.reasonPhrase}'
        };
      }
    } catch (e) {
      print('Error creating thoughts post: $e');
      return {
        'success': false,
        'message': 'Error sharing thoughts: $e'
      };
    }
  }

  // Helper to robustly check 'success' field
  bool isSuccess(dynamic val) {
    try {
      if (val is bool) return val;
      if (val is int) return val == 1;
      if (val is double) return val == 1.0;
      if (val is String) {
        final lower = val.toLowerCase();
        return lower == 'true' || lower == '1';
      }
      final str = val.toString().toLowerCase();
      return str == 'true' || str == '1';
    } catch (e) {
      print('isSuccess type check error: $e');
      return false;
    }
  }

  // Get thoughts posts from followers
  Future<Map<String, dynamic>> getFollowerThoughts(String userId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/thoughts/followers/$userId'),
      headers: {'Content-Type': 'application/json'},
    );
    print('Raw response.body: ${response.body}');
    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (decoded is List) {
        // Backend returned a raw array
        return {
          'success': true,
          'data': decoded,
          'message': 'Follower thoughts posts retrieved successfully',
        };
      } else if (decoded is Map && isSuccess(decoded['success'])) {
        // Backend returned an object with success/data
        return {
          'success': true,
          'data': decoded['data'],
          'message': 'Follower thoughts posts retrieved successfully',
        };
      }
    }
    return {
      'success': false,
      'message': 'Failed to retrieve follower thoughts posts',
    };
  } catch (e) {
    print('Error fetching follower thoughts posts: $e');
    return {
      'success': false,
      'message': 'Network error: $e',
    };
  }
}

  // Like/unlike a thoughts post
  Future<bool> likeThoughts(String postId, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/thoughts/$postId/like'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error liking thoughts: $e');
      return false;
    }
  }

  // Add comment to thoughts post
  Future<bool> addComment(String postId, String userId, String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/thoughts/$postId/comments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'text': text,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error adding comment: $e');
      return false;
    }
  }
}
