// import 'dart:convert';
// import 'dart:ffi';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../../core/providers/auth_provider.dart';
import '../models/fanbase_model.dart';
import '../models/fanbase_post_model.dart';
import 'auth_service.dart';

class FanbaseService {
  static Future<List<Fanbase>> getAllFanbases(BuildContext context) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;

      final response = await dio.get('/fanbase');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Fanbase.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load fanbases');
      }
    } on DioException catch (e) {
      throw Exception('Failed to load fanbases: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load fanbases: $e');
    }
  }

  static Future<Fanbase> getFanbaseById(String id, BuildContext context) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;

      final response = await dio.get('/fanbase/$id');

      if (response.statusCode == 200) {
        return Fanbase.fromJson(response.data);
      } else {
        throw Exception('Fanbase not found');
      }
    } on DioException catch (e) {
      throw Exception('Fanbase not found: ${e.message}');
    } catch (e) {
      throw Exception('Fanbase not found: $e');
    }
  }

  static Future<void> createFanbase(
      String name, String topic, BuildContext context,
      {File? imageFile, String? imageUrl}) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;

      if (!authProvider.isAuthenticated || authProvider.token == null) {
        throw Exception('Authentication required. Please log in.');
      }

      // Prepare form data
      final formData = FormData.fromMap({
        'fanbaseName': name,
        'topic': topic,
      });

      // Add image file if provided
      if (imageFile != null) {
        formData.files.add(MapEntry(
          'image',
          await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.path.split('/').last,
          ),
        ));
      } else if (imageUrl != null && imageUrl.isNotEmpty) {
        formData.fields.add(MapEntry('fanbasePhotoUrl', imageUrl));
      }

      final response = await dio.post(
        '/fanbase',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to create fanbase: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      } else {
        final errorMessage =
            e.response?.data?.toString() ?? e.message ?? 'Unknown error';
        throw Exception('Failed to create fanbase: $errorMessage');
      }
    } catch (e) {
      throw Exception('Failed to create fanbase: $e');
    }
  }

  static Future<Fanbase> joinFanbase(
      String fanbaseId, BuildContext context) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;

      final response = await dio.post('/fanbase/$fanbaseId/join');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Fanbase.fromJson(response.data);
      } else {
        throw Exception(
            'Failed to update join status: ${response.statusMessage}');
      }

    } on DioException catch (e) {
      final errorMessage = e.response?.data?['message'] ?? e.message;
      throw Exception('Failed to update join status: $errorMessage');

    } catch (e) {
      throw Exception('Failed to update join status: $e');
    }
  }

  static Future<Fanbase> likeFanbase(
      String fanbaseId, BuildContext context) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;

      final response = await dio.post('/fanbase/$fanbaseId/like');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Fanbase.fromJson(response.data);
      } else {
        throw Exception(
            'Failed to update like status: ${response.statusMessage}');
      }

    } on DioException catch (e) {
      final errorMessage = e.response?.data?['message'] ?? e.message;
      throw Exception('Failed to update like status: $errorMessage');

    } catch (e) {
      throw Exception('Failed to update like status: $e');
    }
  }

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
        return data.map((json) => FanbasePost.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch posts');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch posts: ${e.message}');
    } catch (e) {
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

      print('[DEBUG] Liking fanbase post (from fanbase_service)');
      print('[DEBUG] PostId: $postId');
      print('[DEBUG] FanbaseId: $actualFanbaseId');
      print('[DEBUG] Making POST request to: /fanbase/$actualFanbaseId/posts/$postId/like');
      
      final response = await dio.post('/fanbase/$actualFanbaseId/posts/$postId/like');

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
}
