import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/color_extractor.dart';
import 'auth_service.dart';

class SongPostService {
  final String baseUrl = AppConstants.baseUrl;

  Future<Map<String, dynamic>> createPost({
    required String trackId,
    required String songName,
    required String artists,
    String? albumImage,
    String? caption,
    BuildContext? context,
  }) async {
    try {
      // use AuthService with Dio for authenticated requests
      if (context != null) {
        final authService = Provider.of<AuthService>(context, listen: false);
        final dio = authService.dio;

        // Get user ID from AuthProvider
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        String? currentUserId = authProvider.user?.id;

        if (currentUserId == null) {
          final prefs = await SharedPreferences
              .getInstance(); //if user id not in the AuthProvider, get it from SharedPreferences(AuthProvider not ready yet)
          final userDataString = prefs.getString('user_data');
          if (userDataString != null) {
            final userData = jsonDecode(userDataString);
            currentUserId = userData['id'];
          }
        }

        if (currentUserId == null) {
          return {
            'success': false,
            'message': 'User not logged in. Please log in to create a post.',
          };
        }

        // Extract background color from album image
        String? backgroundColor;
        if (albumImage != null && albumImage.isNotEmpty) {
          backgroundColor =
              await ColorExtractor.extractBackgroundColor(albumImage);
        }

        // use default color
        if (backgroundColor == null && context != null) {
          backgroundColor = ColorExtractor.getDefaultBackgroundColor(context);
        }

        final postData = {
          'trackId': trackId,
          'songName': songName,
          'artists': artists,
          'userId': currentUserId,
          if (albumImage != null) 'albumImage': albumImage,
          if (caption != null) 'caption': caption,
          if (backgroundColor != null) 'backgroundColor': backgroundColor,
        };

        final response = await dio.post('/song-posts', data: postData);

        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = response.data;
          return {
            'success': true,
            'data': data,
            'message': 'Post created successfully',
          };
        } else {
          final errorData = response.data;
          return {
            'success': false,
            'message': errorData['error'] ??
                errorData['message'] ??
                'Failed to create post',
          };
        }
      } else {
        // Fallback to http for backward compatibility
        // Get user data from shared preferences
        final prefs = await SharedPreferences.getInstance();
        final userDataString = prefs.getString('user_data');

        // Check if user is logged
        if (userDataString == null) {
          return {
            'success': false,
            'message': 'User not logged in. Please log in to create a post.',
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

        // Extract background color from album image
        String? backgroundColor;
        if (albumImage != null && albumImage.isNotEmpty) {
          backgroundColor =
              await ColorExtractor.extractBackgroundColor(albumImage);
        }

        // use default color
        if (backgroundColor == null && context != null) {
          backgroundColor = ColorExtractor.getDefaultBackgroundColor(context);
        }

        final response = await http.post(
          Uri.parse('$baseUrl/song-posts'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'trackId': trackId,
            'songName': songName,
            'artists': artists,
            'albumImage': albumImage,
            'caption': caption,
            'userId': userData['id'],
            if (backgroundColor != null) 'backgroundColor': backgroundColor,
          }),
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return {
            'success': true,
            'data': data,
            'message': 'Post created successfully',
          };
        } else {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['error'] ??
                errorData['message'] ??
                'Failed to create post',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getAllPosts() async {
    try {
      //print('Fetching all posts from: $baseUrl');

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      //print('Response status: ${response.statusCode}');
      //print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Ensure data is a list
        if (data is List) {
          // Filter out hidden and deleted posts
          final filteredData = data.where((post) {
            final isHidden = post['isHidden'] ?? 0;
            final isDeleted = post['isDeleted'] ?? 0;
            return isHidden == 0 && isDeleted == 0;
          }).toList();

          //print('Successfully fetched ${filteredData.length} posts from all users');
          return {
            'success': true,
            'data': filteredData,
            'message': 'Posts retrieved successfully',
          };
        } else {
          return {
            'success': false,
            'message': 'Invalid data format received from server',
          };
        }
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ??
              errorData['message'] ??
              'Failed to retrieve posts',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getPostsByUserId(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/song-posts/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Filter out hidden and deleted posts
        final filteredData = data.where((post) {
          final isHidden = post['isHidden'] ?? 0;
          final isDeleted = post['isDeleted'] ?? 0;
          return isHidden == 0 && isDeleted == 0;
        }).toList();

        return {
          'success': true,
          'data': filteredData,
          'message': 'User posts retrieved successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to retrieve user posts',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getPostById(String postId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/song-posts/$postId/details'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'data': data['data'],
            'message': 'Post retrieved successfully',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to retrieve post',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to retrieve post',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> likePost(String postId, String userId,
      [BuildContext? context]) async {
    try {
      if (context != null) {
        final authService = Provider.of<AuthService>(context, listen: false);
        final dio = authService.dio;

        final response = await dio.post('/song-posts/$postId/like');

        if (response.statusCode == 200 || response.statusCode == 201) {
          return response.data;
        } else {
          return {
            'success': false,
            'message': response.data['message'] ?? 'Failed to like post',
          };
        }
      } else {
        // Fallback to http for backward compatibility
        final response = await http.post(
          Uri.parse('$baseUrl/song-posts/$postId/like'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userId': userId}),
        );
        return jsonDecode(response.body);
      }
    } catch (e) {
      if (e is DioException) {}
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> addComment(
      String postId, String userId, String username, String text,
      [BuildContext? context]) async {
    try {
      // If context is provided, use AuthService with Dio for authenticated requests
      if (context != null) {
        final authService = Provider.of<AuthService>(context, listen: false);
        final dio = authService.dio;

        final response = await dio.post('/song-posts/$postId/comment', data: {
          'text': text,
        });

        if (response.statusCode == 200 || response.statusCode == 201) {
          return response.data;
        } else {
          return {
            'success': false,
            'message': response.data['message'] ?? 'Failed to add comment',
          };
        }
      } else {
        // Fallback to http for backward compatibility
        final response = await http.post(
          Uri.parse('$baseUrl/song-posts/$postId/comment'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userId': userId, 'text': text}),
        );
        return jsonDecode(response.body);
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> likeComment(
      String postId, String commentId, String userId,
      [BuildContext? context]) async {
    try {
      // If context is provided, use AuthService with Dio for authenticated requests
      if (context != null) {
        final authService = Provider.of<AuthService>(context, listen: false);
        final dio = authService.dio;

        final url = '/song-posts/$postId/comment/$commentId/like';

        final response = await dio.post(url);

        if (response.statusCode == 200 || response.statusCode == 201) {
          return response.data;
        } else {
          return {
            'success': false,
            'message': response.data['message'] ?? 'Failed to like comment',
          };
        }
      } else {
        // Fallback to http for backward compatibility
        final response = await http.post(
          Uri.parse('$baseUrl/song-posts/$postId/comment/$commentId/like'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userId': userId}),
        );
        return jsonDecode(response.body);
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getFollowerPosts(String userId,
      [BuildContext? context]) async {
    try {
      // If context is provided, use AuthService with Dio for authenticated requests
      if (context != null) {
        final authService = Provider.of<AuthService>(context, listen: false);
        final dio = authService.dio;

        final response = await dio.get('/song-posts/followers/$userId');

        if (response.statusCode == 200) {
          final data = response.data;
          if (data['success'] == true) {
            return {
              'success': true,
              'data': data['data'],
              'message': 'Follower posts retrieved successfully',
            };
          }
        }

        // Handle error responses
        final responseData = response.data;
        return {
          'success': false,
          'message': responseData['message'] ??
              responseData['error'] ??
              'Failed to retrieve follower posts',
          'statusCode': response.statusCode,
        };
      } else {
        // Fallback to http for backward compatibility
        final response = await http.get(
          Uri.parse('$baseUrl/song-posts/followers/$userId'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            return {
              'success': true,
              'data': data['data'],
              'message': 'Follower posts retrieved successfully',
            };
          }
        }

        // Handle error responses
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ??
              errorData['error'] ??
              'Failed to retrieve follower posts',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'statusCode': 0,
      };
    }
  }

  Future<Map<String, dynamic>> getNotifications(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/song-posts/notifications/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'data': data['data'],
            'message': 'Notifications retrieved successfully',
          };
        }
      }
      return {
        'success': false,
        'message': 'Failed to retrieve notifications',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> addRecentlyLikedPosts(
      String userId, String likedPostId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recently-liked-post'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'likedPostId': likedPostId,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Interaction recorded'};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ??
              errorData['message'] ??
              'Failed to record interaction',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updatePost(
    String postId,
    String caption,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/song-posts/$postId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'caption': caption,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'Post updated successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ??
              errorData['message'] ??
              'Failed to update post',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> deletePost(String postId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/song-posts/$postId'),
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

  Future<Map<String, dynamic>> hidePost(String postId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/song-posts/$postId/hide'),
        headers: {'Content-Type': 'application/json'},
      );

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

  // Save a post
  Future<Map<String, dynamic>> savePost(
      String userId, String postId, BuildContext context) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;

      final response = await dio.post('/profile/$userId/save/$postId');

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Post saved successfully',
        };
      } else {
        return {
          'success': false,
          'message': response.data['error'] ??
              response.data['message'] ??
              'Failed to save post',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Unsave a post
  Future<Map<String, dynamic>> unsavePost(
      String userId, String postId, BuildContext context) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;

      final response = await dio.delete('/profile/$userId/save/$postId');

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Post unsaved successfully',
        };
      } else {
        return {
          'success': false,
          'message': response.data['error'] ??
              response.data['message'] ??
              'Failed to unsave post',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Check if a post is saved
  Future<Map<String, dynamic>> isPostSaved(
      String userId, String postId, BuildContext context) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;

      final response = await dio.get('/profile/$userId/saved/$postId');

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'success': true,
          'isSaved': data['isSaved'] ?? false,
        };
      } else {
        return {
          'success': false,
          'isSaved': false,
          'message': 'Failed to check saved status',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'isSaved': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get all saved posts for a user
  Future<Map<String, dynamic>> getSavedPosts(
      String userId, BuildContext context) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;

      final response = await dio.get('/profile/$userId/saved-posts');

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'success': true,
          'savedPosts': data['savedPosts'] ?? [],
        };
      } else {
        return {
          'success': false,
          'savedPosts': [],
          'message': 'Failed to get saved posts',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'savedPosts': [],
        'message': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getHiddenPostsByUserId(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/song-posts/user/$userId/hidden'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // The backend may return either a list directly or a wrapper { success, data }
        dynamic payload = decoded;
        if (decoded is Map && decoded.containsKey('data')) {
          payload = decoded['data'];
        }

        // Normalize to plain Dart structures and ensure we have a list
        final normalized = jsonDecode(jsonEncode(payload));
        if (normalized is List) {
          return {
            'success': true,
            'data': normalized,
            'message': 'Hidden posts retrieved successfully',
          };
        }

        return {
          'success': false,
          'message': 'Invalid data format received from server',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to retrieve hidden posts',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> unhidePost(String postId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/song-posts/$postId/unhide'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Post unhidden successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ??
              errorData['message'] ??
              'Failed to unhide post',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getPostsByIds(
      List<String> ids, BuildContext context) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;

      final response = await dio.post('/song-posts/by-ids', data: {'ids': ids});

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        return {
          'success': true,
          'posts': data['posts'] ?? [],
        };
      } else {
        return {
          'success': false,
          'posts': [],
          'message': 'Failed to get posts',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'posts': [],
        'message': 'Network error: $e',
      };
    }
  }
}
