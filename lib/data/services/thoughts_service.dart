import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/color_extractor.dart';
import 'auth_service.dart';

class ThoughtsService {
  final String baseUrl = AppConstants.baseUrl;

  // Create a new thoughts post
  Future<Map<String, dynamic>> createThoughts({
    String? text,
    String? thoughtsText,
    String? coverImage,
    String? songName,
    String? artistName,
    String? trackId,
    bool? inAFanbase,
    String? fanbaseID,
    BuildContext? context,
  }) async {
    // Support both 'text' and 'thoughtsText' parameter names
    final postText = thoughtsText ?? text;

    if (postText == null || postText.isEmpty) {
      return {
        'success': false,
        'message': 'Thoughts text is required',
      };
    }
    try {
      // If context is provided, use AuthService with Dio for authenticated requests
      if (context != null) {
        final authService = Provider.of<AuthService>(context, listen: false);
        final dio = authService.dio;

        // Get user ID from AuthProvider or SharedPreferences
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        String? currentUserId = authProvider.user?.id;

        // Fallback to SharedPreferences if AuthProvider doesn't have user ID
        if (currentUserId == null) {
          final prefs = await SharedPreferences.getInstance();
          final userDataString = prefs.getString('user_data');
          if (userDataString != null) {
            final userData = jsonDecode(userDataString);
            currentUserId = userData['id'];
          }
        }

        if (currentUserId == null) {
          return {
            'success': false,
            'message': 'User not logged in. Please log in to share thoughts.',
          };
        }

        // Extract background color from cover image
        String? backgroundColor;
        if (coverImage != null && coverImage.isNotEmpty) {
          backgroundColor = await ColorExtractor.extractBackgroundColor(coverImage);
        }
        
        // Use default color if extraction failed
        if (backgroundColor == null && context != null) {
          backgroundColor = ColorExtractor.getDefaultBackgroundColor(context);
        }

        final postData = {
          'userId': currentUserId,
          'thoughtsText': postText,
          if (coverImage != null) 'coverImage': coverImage,
          if (songName != null) 'songName': songName,
          if (artistName != null) 'artistName': artistName,
          if (trackId != null) 'trackId': trackId,
          if (backgroundColor != null) 'backgroundColor': backgroundColor,
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
        if (userData['id'] == null) {
          return {
            'success': false,
            'message': 'Invalid user data. Please log in again.',
          };
        }

        // Extract background color from cover image (fallback method)
        String? backgroundColor;
        if (coverImage != null && coverImage.isNotEmpty) {
          backgroundColor = await ColorExtractor.extractBackgroundColor(coverImage);
        }
        
        // Use default color if extraction failed
        if (backgroundColor == null && context != null) {
          backgroundColor = ColorExtractor.getDefaultBackgroundColor(context);
        }

        final response = await http.post(
          Uri.parse('$baseUrl/thoughts'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'userId': userData['id'],
            'thoughtsText': postText,
            if (coverImage != null) 'coverImage': coverImage,
            if (songName != null) 'songName': songName,
            if (artistName != null) 'artistName': artistName,
            if (trackId != null) 'trackId': trackId,
            if (backgroundColor != null) 'backgroundColor': backgroundColor,
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
      return {'success': false, 'message': 'Error sharing thoughts: $e'};
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
  Future<Map<String, dynamic>> getFollowerThoughts(String userId,
      [BuildContext? context]) async {
    try {
      // If context is provided, use AuthService with Dio for authenticated requests
      if (context != null) {
        final authService = Provider.of<AuthService>(context, listen: false);
        final dio = authService.dio;

        final response = await dio.get('/thoughts/followers/$userId');
        print('Raw response.body: ${response.data}');

        if (response.statusCode == 200) {
          final decoded = response.data;
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
      } else {
        // Fallback to http for backward compatibility
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
      }
    } catch (e) {
      print('Error fetching follower thoughts posts: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get thoughts posts for a single user (profile)
  Future<Map<String, dynamic>> getUserThoughts(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/thoughts/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      print('Raw response.body (getUserThoughts): ${response.body}');
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (decoded is List) {
          return {
            'success': true,
            'data': decoded,
            'message': 'User thoughts retrieved successfully',
          };
        } else if (decoded is Map && isSuccess(decoded['success'])) {
          return {
            'success': true,
            'data': decoded['data'],
            'message': 'User thoughts retrieved successfully',
          };
        }
      }
      return {
        'success': false,
        'message': 'Failed to retrieve user thoughts',
      };
    } catch (e) {
      print('Error fetching user thoughts posts: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Like/unlike a thoughts post
  Future<Map<String, dynamic>> likeThoughts(String postId,
      [BuildContext? context]) async {
    try {
      // If context is provided, use AuthService with Dio for authenticated requests
      if (context != null) {
        final authService = Provider.of<AuthService>(context, listen: false);
        final dio = authService.dio;

        print('[DEBUG] LikeThoughts: Using authenticated Dio for post $postId');
        print('[DEBUG] LikeThoughts: Dio baseUrl: ${dio.options.baseUrl}');
        print(
            '[DEBUG] LikeThoughts: AuthService token: ${authService.tokenManager.accessToken}');

        final response = await dio.post('/thoughts/$postId/like');

        print('[DEBUG] LikeThoughts: Response status: ${response.statusCode}');
        print('[DEBUG] LikeThoughts: Response data: ${response.data}');

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
        print('[DEBUG] LikeThoughts: Using fallback http for post $postId');
        final response = await http.post(
          Uri.parse('$baseUrl/thoughts/$postId/like'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return jsonDecode(response.body);
        } else {
          return {
            'success': false,
            'message': 'Failed to like post',
          };
        }
      }
    } catch (e) {
      print('[DEBUG] LikeThoughts: Error occurred: $e');
      if (e is DioException) {
        print(
            '[DEBUG] LikeThoughts: DioException status: ${e.response?.statusCode}');
        print('[DEBUG] LikeThoughts: DioException data: ${e.response?.data}');
      }
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Add comment to thoughts post
  Future<Map<String, dynamic>> addComment(
      String postId, String userId, String text,
      [BuildContext? context]) async {
    try {
      // If context is provided, use AuthService with Dio for authenticated requests
      if (context != null) {
        final authService = Provider.of<AuthService>(context, listen: false);
        final dio = authService.dio;

        print(
            '[DEBUG] AddThoughtsComment: Using authenticated Dio for post $postId');
        print(
            '[DEBUG] AddThoughtsComment: Dio baseUrl: ${dio.options.baseUrl}');
        print(
            '[DEBUG] AddThoughtsComment: AuthService token: ${authService.tokenManager.accessToken}');

        final response = await dio.post('/thoughts/$postId/comments', data: {
          'userId': userId,
          'text': text,
        });

        print(
            '[DEBUG] AddThoughtsComment: Response status: ${response.statusCode}');
        print('[DEBUG] AddThoughtsComment: Response data: ${response.data}');

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
        print(
            '[DEBUG] AddThoughtsComment: Using fallback http for post $postId');
        final response = await http.post(
          Uri.parse('$baseUrl/thoughts/$postId/comments'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': userId,
            'text': text,
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return jsonDecode(response.body);
        } else {
          return {
            'success': false,
            'message': 'Failed to add comment',
          };
        }
      }
    } catch (e) {
      print('[DEBUG] AddThoughtsComment: Error occurred: $e');
      if (e is DioException) {
        print(
            '[DEBUG] AddThoughtsComment: DioException status: ${e.response?.statusCode}');
        print(
            '[DEBUG] AddThoughtsComment: DioException data: ${e.response?.data}');
        print('[DEBUG] AddThoughtsComment: DioException message: ${e.message}');
        print('[DEBUG] AddThoughtsComment: DioException type: ${e.type}');

        // Return more specific error message
        final errorData = e.response?.data;
        if (errorData != null && errorData is Map<String, dynamic>) {
          String errorMessage = 'Failed to add comment';
          if (errorData['message'] != null) {
            if (errorData['message'] is String) {
              errorMessage = errorData['message'];
            } else if (errorData['message'] is List) {
              errorMessage = (errorData['message'] as List).join(', ');
            }
          }
          return {
            'success': false,
            'message': errorMessage,
          };
        }
      }
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Like/unlike a thoughts comment
  Future<Map<String, dynamic>> likeComment(
      String postId, String commentId, String userId,
      [BuildContext? context]) async {
    try {
      // If context is provided, use AuthService with Dio for authenticated requests
      if (context != null) {
        final authService = Provider.of<AuthService>(context, listen: false);
        final dio = authService.dio;

        print(
            '[DEBUG] LikeThoughtsComment: Using authenticated Dio for post $postId, comment $commentId');
        print(
            '[DEBUG] LikeThoughtsComment: Dio baseUrl: ${dio.options.baseUrl}');
        print(
            '[DEBUG] LikeThoughtsComment: AuthService token: ${authService.tokenManager.accessToken}');

        final response =
            await dio.post('/thoughts/$postId/comments/$commentId/like');

        print(
            '[DEBUG] LikeThoughtsComment: Response status: ${response.statusCode}');
        print('[DEBUG] LikeThoughtsComment: Response data: ${response.data}');

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
        print(
            '[DEBUG] LikeThoughtsComment: Using fallback http for post $postId, comment $commentId');
        final response = await http.post(
          Uri.parse('$baseUrl/thoughts/$postId/comments/$commentId/like'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return jsonDecode(response.body);
        } else {
          return {
            'success': false,
            'message': 'Failed to like comment',
          };
        }
      }
    } catch (e) {
      print('[DEBUG] LikeThoughtsComment: Error occurred: $e');
      if (e is DioException) {
        print(
            '[DEBUG] LikeThoughtsComment: DioException status: ${e.response?.statusCode}');
        print(
            '[DEBUG] LikeThoughtsComment: DioException data: ${e.response?.data}');
      }
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get comments for a thoughts post
  Future<Map<String, dynamic>> getComments(String postId,
      [BuildContext? context]) async {
    try {
      // If context is provided, use AuthService with Dio for authenticated requests
      if (context != null) {
        final authService = Provider.of<AuthService>(context, listen: false);
        final dio = authService.dio;

        print(
            '[DEBUG] GetThoughtsComments: Using authenticated Dio for post $postId');

        final response = await dio.get('/thoughts/$postId');

        print(
            '[DEBUG] GetThoughtsComments: Response status: ${response.statusCode}');
        print('[DEBUG] GetThoughtsComments: Response data: ${response.data}');

        if (response.statusCode == 200) {
          return {
            'success': true,
            'data': response.data,
          };
        } else {
          return {
            'success': false,
            'message': 'Failed to get comments',
          };
        }
      } else {
        // Fallback to http for backward compatibility
        final response = await http.get(
          Uri.parse('$baseUrl/thoughts/$postId'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          return {
            'success': true,
            'data': jsonDecode(response.body),
          };
        } else {
          return {
            'success': false,
            'message': 'Failed to get comments',
          };
        }
      }
    } catch (e) {
      print('[DEBUG] GetThoughtsComments: Error occurred: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
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

  
  Future<Map<String, dynamic>> savePost(String userId, String postId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/profile/$userId/save-thoughts/$postId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Thoughts post saved successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ??
              errorData['message'] ??
              'Failed to save thoughts post',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  
  Future<Map<String, dynamic>> unsavePost(String userId, String postId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/profile/$userId/save-thoughts/$postId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Thoughts post unsaved successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ??
              errorData['message'] ??
              'Failed to unsave thoughts post',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }


  Future<Map<String, dynamic>> isPostSaved(String userId, String postId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile/$userId/saved-thoughts/$postId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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

 
  Future<Map<String, dynamic>> getSavedThoughtsPosts(
      String userId, BuildContext context) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;

      final response = await dio.get('/profile/$userId/saved-thoughts-posts');

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
          'message': 'Failed to get saved thoughts posts',
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
}
