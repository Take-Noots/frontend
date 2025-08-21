// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
// import '../../core/providers/auth_provider.dart';
import '../models/fanbase_post_model.dart';
import 'auth_service.dart';

class FanbasePostService {
  final String baseUrl = 'http://localhost:3000';

  // Create a fanbase post
  static Future<FanbasePost> createFanbasePost({
    required String fanbaseId,
    required String topic,
    required String description,
    String? spotifyTrackId,
    String? songName,
    String? artistName,
    String? albumArt,
    required BuildContext context,
  }) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;

      final postData = {
        'topic': topic.trim(),
        'description': description.trim(),
        'fanbaseId': fanbaseId,
        if (spotifyTrackId != null) 'spotifyTrackId': spotifyTrackId,
        if (songName != null) 'songName': songName,
        if (artistName != null) 'artistName': artistName,
        if (albumArt != null) 'albumArt': albumArt,
      };

      final response = await dio.post('/fanbase/posts', data: postData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return FanbasePost.fromJson(response.data);
      } else {
        throw Exception('Failed to create post: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['message'] ?? e.message;
      throw Exception('Failed to create post: $errorMessage');
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  // Get posts for a fanbase
  static Future<List<FanbasePost>> getFanbasePosts(
    String fanbaseId,
    BuildContext context, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;

      final response = await dio.get(
        '/fanbase/$fanbaseId/posts',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['posts'] ?? response.data;

        // Add debug logging here
        print('=== FanbasePostService Debug ===');
        print('Raw API response: ${response.data}');
        print('Posts data: $data');

        final posts = data.map((json) {
          print('Processing post JSON: $json');
          final post = FanbasePost.fromJson(json);
          print(
              'Parsed post - Comments: ${post.comments.length}, CommentsCount: ${post.commentsCount}');
          return post;
        }).toList();

        return posts;
      } else {
        throw Exception('Failed to fetch posts');
      }
    } on DioException catch (e) {
      print('DioException in getFanbasePosts: ${e.message}');
      print('Response data: ${e.response?.data}');
      throw Exception('Failed to fetch posts: ${e.message}');
    } catch (e) {
      print('General exception in getFanbasePosts: $e');
      throw Exception('Failed to fetch posts: $e');
    }
  }

  // Like/Unlike a fanbase post
  static Future<FanbasePost> likeFanbasePost(
    String postId,
    BuildContext context, {
    String? fanbaseId,
  }) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;

      String actualFanbaseId = fanbaseId ?? '';
      
      // If fanbaseId is not provided, try to get it from the post
      if (actualFanbaseId.isEmpty) {
        try {
          final postResponse = await dio.get('/fanbase/posts/$postId');
          final postData = postResponse.data;
          actualFanbaseId = postData['fanbaseId'] ?? '';
        } catch (e) {
          print('[DEBUG] Could not fetch post to get fanbaseId: $e');
        }
      }

      if (actualFanbaseId.isEmpty) {
        throw Exception('FanbaseId is required to like a post');
      }

      print('[DEBUG] Liking fanbase post');
      print('[DEBUG] PostId: $postId');
      print('[DEBUG] FanbaseId: $actualFanbaseId');
      print('[DEBUG] Making POST request to: /fanbase/$actualFanbaseId/posts/$postId/like');
      
      final response = await dio.post('/fanbase/$actualFanbaseId/posts/$postId/like');
      
      print('[DEBUG] Response status: ${response.statusCode}');
      print('[DEBUG] Response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return FanbasePost.fromJson(response.data);
      } else {
        throw Exception('Failed to like post: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['message'] ?? e.message;
      throw Exception('Failed to like post: $errorMessage');
    } catch (e) {
      throw Exception('Failed to like post: $e');
    }
  }

  // Add comment to a fanbase post
  static Future<FanbasePost> addComment(
    String postId,
    String comment,
    BuildContext context, {
    String? fanbaseId,
  }) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;

      String actualFanbaseId = fanbaseId ?? '';
      
      // If fanbaseId is not provided, try to get it from the post
      if (actualFanbaseId.isEmpty) {
        try {
          final postResponse = await dio.get('/fanbase/posts/$postId');
          final postData = postResponse.data;
          actualFanbaseId = postData['fanbaseId'] ?? '';
        } catch (e) {
          print('[DEBUG] Could not fetch post to get fanbaseId: $e');
        }
      }

      if (actualFanbaseId.isEmpty) {
        throw Exception('FanbaseId is required to add a comment');
      }

      print('[DEBUG] Adding comment to fanbase post');
      print('[DEBUG] PostId: $postId');
      print('[DEBUG] FanbaseId: $actualFanbaseId');
      print('[DEBUG] Comment: $comment');
      print('[DEBUG] Making POST request to: /fanbase/$actualFanbaseId/posts/$postId/comment');
      
      final response = await dio.post('/fanbase/$actualFanbaseId/posts/$postId/comment', data: {
        'comment': comment.trim(),
      });
      
      print('[DEBUG] Response status: ${response.statusCode}');
      print('[DEBUG] Response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return FanbasePost.fromJson(response.data);
      } else {
        throw Exception('Failed to add comment: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['message'] ?? e.message;
      throw Exception('Failed to add comment: $errorMessage');
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  // Get a specific fanbase post
  static Future<FanbasePost> getFanbasePost(
    String postId,
    BuildContext context,
  ) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;

      final response = await dio.get('/fanbase/posts/$postId');

      if (response.statusCode == 200) {
        return FanbasePost.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch post');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch post: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch post: $e');
    }
  }
}
