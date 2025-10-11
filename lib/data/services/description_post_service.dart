import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'auth_service.dart';

class ThoughtsPostService {
  final String baseUrl = 'http://localhost:3000';

  // Create a new thoughts post
  Future<Map<String, dynamic>> createThoughts({
    required String thoughtsText,
    String? coverImage,
    String? songName,
    String? artistName,
    String? trackId,
    bool? inAFanbase,
    String? fanbaseID,
    BuildContext? context,
  }) async {
    try {
      // If context is provided, use AuthService with Dio for authenticated requests
      if (context != null) {
        final authService = Provider.of<AuthService>(context, listen: false);
        final dio = authService.dio;
        
        final postData = {
          'thoughtsText': thoughtsText,
          if (coverImage != null) 'coverImage': coverImage,
          if (songName != null) 'songName': songName,
          if (artistName != null) 'artistName': artistName,
          if (trackId != null) 'trackId': trackId,
          'inAFanbase': inAFanbase ?? false,
          'FanbaseID': fanbaseID,
        };
        
        final response = await dio.post('/thoughts', data: postData);
        
        if (response.statusCode == 201 || response.statusCode == 200) {
          final responseData = response.data;
          return {
            'success': true,
            'data': responseData,
            'message': 'Thoughts shared successfully!'
          };
        } else {
          return {
            'success': false,
            'message': 'Failed to share thoughts: ${response.statusMessage}'
          };
        }
      } else {
        // Fallback to http for backward compatibility
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
            if (songName != null) 'songName': songName,
            if (artistName != null) 'artistName': artistName,
            if (trackId != null) 'trackId': trackId,
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
      }
    } catch (e) {
      print('Error creating thoughts post: $e');
      return {
        'success': false,
        'message': 'Error sharing thoughts: $e'
      };
    }
  }

  // Get all thoughts posts
  Future<List<Map<String, dynamic>>> getAllThoughts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/thoughts'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final allPosts = List<Map<String, dynamic>>.from(data);
        
        // Filter out hidden and deleted posts
        final filteredPosts = allPosts.where((post) {
          final isHidden = post['isHidden'] ?? 0;
          final isDeleted = post['isDeleted'] ?? 0;
          return isHidden == 0 && isDeleted == 0;
        }).toList();
        
        return filteredPosts;
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
      final response = await http.get(Uri.parse('$baseUrl/thoughts/user/$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final allPosts = List<Map<String, dynamic>>.from(data);
        
        // Filter out hidden and deleted posts
        final filteredPosts = allPosts.where((post) {
          final isHidden = post['isHidden'] ?? 0;
          final isDeleted = post['isDeleted'] ?? 0;
          return isHidden == 0 && isDeleted == 0;
        }).toList();
        
        return filteredPosts;
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

  // Delete thoughts post
  Future<Map<String, dynamic>> deletePost(String postId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/thoughts/$postId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Post deleted successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ??
              errorData['message'] ??
              'Failed to delete post',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Hide thoughts post
  Future<Map<String, dynamic>> hidePost(String postId) async {
    print('[DEBUG] hidePost called with postId: $postId');
    print('[DEBUG] Making API call to: $baseUrl/thoughts/$postId/hide');
    
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/thoughts/$postId/hide'),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('[DEBUG] API response status: ${response.statusCode}');
      print('[DEBUG] API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Post hidden successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ??
              errorData['message'] ??
              'Failed to hide post',
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
