import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ThoughtsPostService {
  String get baseUrl {
    if (Platform.isAndroid) {
      return 'https://backend-nestjs-production-8204.up.railway.app';
    }
    return 'http://localhost:3000';
  }

  // Create a new thoughts post
  Future<Map<String, dynamic>> createThoughts({
    required String thoughtsText,
    String? coverImage,
    bool? inAFanbase,
    String? fanbaseID,
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
      if (userData['id'] == null || userData['name'] == null) {
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
          'thoughtsText': thoughtsText,
          if (coverImage != null) 'coverImage': coverImage,
          'inAFanbase': inAFanbase ?? false,
          'FanbaseID': fanbaseID,
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
      return {'success': false, 'message': 'Error sharing thoughts: $e'};
    }
  }

  // Get all thoughts posts
  Future<List<Map<String, dynamic>>> getAllThoughts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/thoughts'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print('Error fetching thoughts: $e');
      return [];
    }
  }

  // Get thoughts by user ID
  Future<List<Map<String, dynamic>>> getThoughtsByUser(String userId) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/thoughts/user/$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print('Error fetching user thoughts: $e');
      return [];
    }
  }

  // Like a thoughts post
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
