import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';

class SongPostService {
  String get baseUrl {
    if (Platform.isAndroid) {
      return 'https://backend-nestjs-production-8204.up.railway.app';
    }
    return 'http://localhost:3000';
  }

  Future<Map<String, dynamic>> createPost({
    required String trackId,
    required String songName,
    required String artists,
    String? albumImage,
    String? caption,
  }) async {
    try {
      // Get user data from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');

      // Check if user is logged in
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
          print('Unexpected data format: $data');
          return {
            'success': false,
            'message': 'Invalid data format received from server',
          };
        }
      } else {
        print('Failed to fetch posts. Status: ${response.statusCode}');
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ??
              errorData['message'] ??
              'Failed to retrieve posts',
        };
      }
    } catch (e) {
      print('Error fetching all posts: $e');
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

  Future<Map<String, dynamic>> likePost(String postId, String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/song-posts/$postId/like'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> addComment(
      String postId, String userId, String username, String text) async {
    final response = await http.post(
      Uri.parse('$baseUrl/song-posts/$postId/comment'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'text': text}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> likeComment(
      String postId, String commentId, String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/song-posts/$postId/comment/$commentId/like'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getFollowerPosts(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/song-posts/followers/$userId'),
      headers: {'Content-Type': 'application/json'},
    );
    return jsonDecode(response.body);
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

  Future<Map<String, dynamic>> addRecentlyLikedUser(
      String userId, String likedUserId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recently-liked-users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'likedUserId': likedUserId,
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
      print('[DEBUG] Updating post with ID: $postId');
      print('[DEBUG] New caption: $caption');
      print('[DEBUG] Making PUT request to: $baseUrl/song-posts/$postId');
      
      final response = await http.put(
        Uri.parse('$baseUrl/song-posts/$postId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'caption': caption,
        }),
      );
      
      print('[DEBUG] Response status: ${response.statusCode}');
      print('[DEBUG] Response body: ${response.body}');

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
    print('[DEBUG] hidePost called with postId: $postId');
    print('[DEBUG] Making API call to: $baseUrl/song-posts/$postId/hide');
    
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/song-posts/$postId/hide'),
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

  // Save a post
  Future<Map<String, dynamic>> savePost(String userId, String postId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/profile/$userId/save/$postId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Post saved successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ??
              errorData['message'] ??
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
  Future<Map<String, dynamic>> unsavePost(String userId, String postId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/profile/$userId/save/$postId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Post unsaved successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ??
              errorData['message'] ??
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
  Future<Map<String, dynamic>> isPostSaved(String userId, String postId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile/$userId/saved/$postId'),
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

  // Get all saved posts for a user
  Future<Map<String, dynamic>> getSavedPosts(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile/$userId/saved-posts'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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
}

