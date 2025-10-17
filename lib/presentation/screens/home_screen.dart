import 'package:flutter/material.dart';
import '../widgets/home/header_bar.dart';
import '/presentation/widgets/common/bottom_bar.dart';
import '../widgets/home/feed_widget.dart';
import '../../data/models/post_model.dart' as data_model;
import '../../data/models/feed_item.dart';
import '../../data/models/thoughts_model.dart';
import '../../data/services/profile_service.dart';
import '../../data/services/thoughts_service.dart';
import '../../data/services/song_post_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../data/services/auth_service.dart';
import 'package:dio/dio.dart';
import '../widgets/song_post/comment.dart';
import './profile/user_profiles.dart';
import '../widgets/song_post/post_options_menu.dart';

class HomeScreen extends StatefulWidget {
  final String? accessToken;

  /// Whether this screen is being displayed inside the ShellScreen.
  /// When true, navigation elements (app bar, bottom bar, music player) are not shown
  /// as they are already provided by the ShellScreen.
  final bool inShell;

  const HomeScreen({Key? key, this.accessToken, this.inShell = false})
      : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SongPostService _songPostService = SongPostService();
  final ThoughtsService _thoughtsService = ThoughtsService();

  List<FeedItem> _feedItems = [];
  bool _isLoading = true;
  String? _error;
  String? _currentlyPlayingTrackId;
  bool _isPlaying = false;
  String? userId;
  Map<String, bool> _followingStatus =
      {}; // Track following status for each user

  @override
  void initState() {
    super.initState();
    _loadUserIdAndPosts();
  }

  Future<void> _loadUserIdAndPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    final userData = userDataString != null
        ? jsonDecode(userDataString)
        : {'id': '685fb750cc084ba7e0ef8533'}; // Fallback for testing
    setState(() {
      userId = userData['id'];
    });
    await _loadPosts();
  }

  // Refresh posts after creating a new post
  Future<void> refreshPostsAfterCreation() async {
    await _loadPosts();
  }

  // Load posts from the backend
  Future<void> _loadPosts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      if (userId == null) {
        setState(() {
          _error = 'User ID not found. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      final songResult =
          await _songPostService.getFollowerPosts(userId!, context);
      final thoughtsResult =
          await _thoughtsService.getFollowerThoughts(userId!, context);
      //print('Fetched thoughtsResult: ' + thoughtsResult.toString());

      List<FeedItem> feedItems = [];

      // Check if songResult is valid and has success field
      if (songResult['success'] == true && songResult['data'] != null) {
        final List<dynamic> postsData = songResult['data'];

        final posts = postsData.map((json) {
          final post = data_model.Post.fromJson(json);
          post.likedByMe =
              (json['likedBy'] as List<dynamic>?)?.contains(userId) ?? false;
          return FeedItem.song(post);
        }).where((item) =>
            item.songPost == null ||
            (item.songPost!.isHidden == 0 && item.songPost!.isDeleted == 0));

        feedItems.addAll(posts);
      }

      // Check saved status for all posts if user is logged in
      if (userId != null) {
        await _checkSavedStatusForPosts(feedItems);
      }

      // Check if thoughtsResult is valid and has success field
      if (thoughtsResult['success'] == true && thoughtsResult['data'] != null) {
        final List<dynamic> thoughtsData = thoughtsResult['data'];

        final thoughtsPosts = thoughtsData.map((json) {
          final post = ThoughtsPost.fromJson(json);
          return FeedItem.thought(post);
        }).where((item) =>
            item.thoughtsPost == null ||
            (item.thoughtsPost!.isHidden == 0 &&
                item.thoughtsPost!.isDeleted == 0));

        feedItems.addAll(thoughtsPosts);
      }

      // Sort all by createdAt, newest first
      feedItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _feedItems = feedItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      String errorMessage = 'Error loading posts: $e';

      // Check if it's an authentication error
      if (e.toString().contains('401') ||
          e.toString().contains('Unauthorized')) {
        errorMessage = 'Authentication failed. Please log in again.';
      }

      if (mounted) {
        setState(() {
          _error = errorMessage;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkSavedStatusForPosts(List<FeedItem> feedItems) async {
    if (userId == null) {
      return;
    }

    try {
      final savedPostsResult =
          await _songPostService.getSavedPosts(userId!, context);

      if (savedPostsResult['success'] == true &&
          savedPostsResult['savedPosts'] != null) {
        final List<String> savedPostsIds =
            List<String>.from(savedPostsResult['savedPosts']);

        for (var item in feedItems) {
          if (item.type == FeedItemType.song && item.songPost != null) {
            final post = item.songPost!;
            post.isSaved = savedPostsIds.contains(post.id);
          }
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _handleLike(data_model.Post post) async {
    String? currentUserId = userId;
    if (currentUserId == null) {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      final userData = userDataString != null
          ? jsonDecode(userDataString)
          : {'id': '685fb750cc084ba7e0ef8533'}; // Fallback for testing
      currentUserId = userData['id'];
    }
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User ID not found. Please log in again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      if (post.likedByMe) {
        post.likedByMe = false;
        post.likes--;
      } else {
        post.likedByMe = true;
        post.likes++;
      }
    });

    final result =
        await _songPostService.likePost(post.id, currentUserId, context);

    if (result['success']) {
      if (post.userId != null) {
        await _songPostService.addRecentlyLikedUser(
          currentUserId,
          post.userId!,
        );
      }
    }
    if (result['success'] != true) {
      if (mounted) {
        setState(() {
          if (post.likedByMe) {
            post.likedByMe = false;
            post.likes--;
          } else {
            post.likedByMe = true;
            post.likes++;
          }
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to like post'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _handleComment(data_model.Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: CommentSection(
          comments: post.comments,
          onAddComment: (text) async {
            final prefs = await SharedPreferences.getInstance();
            final userDataString = prefs.getString('user_data');
            final userData = userDataString != null
                ? jsonDecode(userDataString)
                : {'id': '685fb750cc084ba7e0ef8533', 'name': 'owl'};
            final result = await _songPostService.addComment(
                post.id, userData['id'], userData['name'], text, context);
            if (result['success'] == true) {
              final updatedComments =
                  (result['data']['comments'] as List<dynamic>)
                      .map((c) => data_model.Comment.fromJson(c))
                      .toList();
              setState(() {
                post.comments = updatedComments;
              });
              return updatedComments;
              return updatedComments;
            } else if (result['success'] == false) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'Failed to add comment'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
              return post.comments;
              return post.comments;
            }
          },
          postId: post.id,
          currentUserId: userId ?? '',
          songPostService: _songPostService,
        ),
      ),
    );
  }

  Future<void> _handlePlay(data_model.Post post) async {
    if (_currentlyPlayingTrackId == post.trackId && _isPlaying) {
      setState(() {
        _isPlaying = false;
      });
      try {
        await _pausePlayback();
      } catch (e) {
        setState(() {
          _isPlaying = true;
        });
      }
    } else {
      setState(() {
        _currentlyPlayingTrackId = post.trackId;
        _isPlaying = true;
      });
      try {
        await _playTrack(post);
      } catch (e) {
        setState(() {
          _isPlaying = false;
        });
      }
    }
  }

  Future<void> _playTrack(data_model.Post post) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;
      final response = await dio.post(
        '/spotify/player/post/play',
        data: {'track_id': post.trackId},
      );
      if (response.statusCode == 200 ||
          response.statusCode == 202 ||
          response.statusCode == 204) {
        setState(() {
          _currentlyPlayingTrackId = post.trackId;
          _isPlaying = true;
        });
      }
    } catch (e) {
      if (e is DioError && e.response != null && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          // errorMsg = data['message'];
        } else if (data is String) {
          // errorMsg = data;
        }
      }
    }
  }

  Future<void> _pausePlayback() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;
      final response = await dio.put('/spotify/player/post/pause');
      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _isPlaying = false;
        });
      }
    } catch (e) {}
  }

  Future<void> _handleThoughtsPlay(ThoughtsPost post) async {
    if (post.songName == null || post.songName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No song information available for this post'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create a unique identifier for thoughts posts
    final thoughtsTrackId = '${post.songName}_${post.artistName}';

    if (_currentlyPlayingTrackId == thoughtsTrackId && _isPlaying) {
      setState(() {
        _isPlaying = false;
      });
      try {
        await _pausePlayback();
      } catch (e) {
        setState(() {
          _isPlaying = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to pause playback'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Optimistically update the UI state immediately
      setState(() {
        _currentlyPlayingTrackId = thoughtsTrackId;
        _isPlaying = true;
      });

      try {
        await _playThoughtsTrack(post);
      } catch (e) {
        // Revert state on error
        setState(() {
          _currentlyPlayingTrackId = null;
          _isPlaying = false;
        });

        // Show a more user-friendly error message
        String errorMessage = 'Failed to play track';
        String detailedError = e.toString();

        if (detailedError.contains('No Spotify token')) {
          errorMessage = 'Please connect your Spotify account to play music';
        } else if (detailedError.contains('Track not found')) {
          errorMessage = 'Track not found on Spotify';
        } else if (detailedError.contains('401') ||
            detailedError.contains('Unauthorized')) {
          errorMessage =
              'Spotify authentication failed. Please reconnect your account';
        } else {
          // Show the actual error for debugging
          errorMessage =
              'Failed to play: ${detailedError.length > 100 ? detailedError.substring(0, 100) : detailedError}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _playThoughtsTrack(ThoughtsPost post) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;

      // Search for the track first - try with both song name and artist name
      final searchQuery = '${post.songName} ${post.artistName}';
      final searchResponse = await dio.get(
        '/spotify/search/track',
        queryParameters: {'track_name': searchQuery},
      );

      // Check if response has the expected structure
      if (searchResponse.data == null) {
        throw Exception('Search returned null data');
      }

      if (searchResponse.data['tracks'] == null) {
        throw Exception(
            'Search response missing tracks field. Data: ${searchResponse.data}');
      }

      if (searchResponse.data['tracks']['items'] == null) {
        throw Exception(
            'Search response missing items field. Data: ${searchResponse.data}');
      }

      if (searchResponse.statusCode == 200 &&
          searchResponse.data['tracks']['items'].isNotEmpty) {
        // Find the track that matches both song name and artist name
        final tracks = searchResponse.data['tracks']['items'] as List;

        String? trackId;

        for (var track in tracks) {
          final trackName = track['name']?.toString().toLowerCase() ?? '';

          // Handle artists - could be a list of strings or list of objects
          String trackArtists = '';
          try {
            final artistsList = track['artists'] as List;
            trackArtists = artistsList
                .map((a) {
                  // If artist is a string, use it directly
                  if (a is String) return a.toLowerCase();
                  // If artist is a map/object, get the name field
                  if (a is Map && a['name'] != null)
                    return a['name'].toString().toLowerCase();
                  return '';
                })
                .where((name) => name.isNotEmpty)
                .join(' ');
          } catch (e) {
            trackArtists = '';
          }

          final postSongName = post.songName?.toLowerCase() ?? '';
          final postArtistName = post.artistName?.toLowerCase() ?? '';

          if (trackName.contains(postSongName) &&
              trackArtists.contains(postArtistName)) {
            trackId = track['id'];
            break;
          }
        }

        // If no exact match found, use the first result
        if (trackId == null) {
          trackId = tracks.first['id'];
        }

        // Play the track
        final playResponse = await dio.post(
          '/spotify/player/post/play',
          data: {'track_id': trackId},
        );

        // Accept any 2xx status code as success
        if (playResponse.statusCode != null &&
            playResponse.statusCode! >= 200 &&
            playResponse.statusCode! < 300) {
          // Successfully started playing track
        } else {
          throw Exception(
              'Failed to play track - Status: ${playResponse.statusCode}');
        }
      } else {
        throw Exception(
            'Track not found - Search returned ${searchResponse.statusCode} with ${searchResponse.data['tracks']['items']?.length ?? 0} results');
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception('Spotify error: ${errorData['message']}');
        } else if (errorData is String) {
          throw Exception('Spotify error: $errorData');
        }
      }
      throw Exception('Failed to play track: ${e.message}');
    } catch (e) {
      throw Exception('Failed to play track: $e');
    }
  }

  Future<void> _handlePostOptions(data_model.Post post) async {
    // Check if either ID is null or empty
    if (post.userId == null || post.userId!.isEmpty) {
      // WARNING: Post userId is null or empty
    }
    if (userId == null || userId!.isEmpty) {
      // WARNING: Current userId is null or empty
    }

    bool isUsersOwnPost = false;
    if (post.userId != null && userId != null) {
      isUsersOwnPost = post.userId == userId;
    } else {
      // Cannot determine if post is user's own due to null IDs
    }

    // Check if post is saved
    bool isSaved = false;
    if (userId != null) {
      try {
        final savedResult =
            await _songPostService.isPostSaved(userId!, post.id, context);
        isSaved = savedResult['isSaved'] ?? false;
      } catch (e) {
        // If we can't check saved status, assume it's not saved
        isSaved = false;
      }
    }

    // Check if current user is following the post's author
    bool isFollowing = false;
    if (userId != null && post.userId != null && userId != post.userId) {
      // Use cached following status if available, otherwise check from API
      if (_followingStatus.containsKey(post.userId)) {
        isFollowing = _followingStatus[post.userId]!;
      } else {
        try {
          final authService = Provider.of<AuthService>(context, listen: false);
          final profileService = ProfileService(authService: authService);
          final followingList =
              await profileService.getFollowingListWithDetails(userId!);
          isFollowing = followingList.any((user) => user['id'] == post.userId);
          // Cache the result
          _followingStatus[post.userId!] = isFollowing;
        } catch (e) {
          // If we can't check following status, assume not following
          isFollowing = false;
        }
      }
    }

    PostOptionsMenu.show(
      context,
      postUserId: post.userId,
      currentUserId: userId,
      postId: post.id,
      isOwnPost: isUsersOwnPost,
      isSaved: isSaved,
      isFollowing: isFollowing,
      onDelete: () async {
        try {
          final result = await _songPostService.deletePost(post.id);
          if (result['success'] == true) {
            setState(() {
              _feedItems.removeWhere((item) => item.songPost?.id == post.id);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Post deleted successfully'),
                backgroundColor: const Color(0xFFA855F7),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(10),
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to delete post'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(10),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting post: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(10),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      onSavePost: () async {
        await _handleSavePost(post);
      },
      onUnsavePost: () async {
        await _handleUnsavePost(post);
      },
      onFollow: () async {
        await _handleFollowUser(post.userId!);
      },
      onUnfollow: () async {
        await _handleUnfollowUser(post.userId!);
      },
    );
  }

  Future<void> _handleSavePost(data_model.Post post) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in to save posts'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final result = await _songPostService.savePost(userId!, post.id, context);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Post saved successfully'),
            backgroundColor: const Color(0xFFA855F7),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 2),
          ),
        );
        // Update the post's saved status in the feed
        setState(() {
          final feedItem = _feedItems.firstWhere(
            (item) => item.songPost?.id == post.id,
            orElse: () => FeedItem.song(post),
          );
          if (feedItem.songPost != null) {
            // Note: We would need to add an isSaved field to the Post model
            // For now, we'll just show the success message
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to save post'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving post: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleUnsavePost(data_model.Post post) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in to unsave posts'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final result =
          await _songPostService.unsavePost(userId!, post.id, context);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Post unsaved successfully'),
            backgroundColor: const Color(0xFFA855F7),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 2),
          ),
        );
        // Update the post's saved status in the feed
        setState(() {
          final feedItem = _feedItems.firstWhere(
            (item) => item.songPost?.id == post.id,
            orElse: () => FeedItem.song(post),
          );
          if (feedItem.songPost != null) {
            // Note: We would need to add an isSaved field to the Post model
            // For now, we'll just show the success message
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to unsave post'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error unsaving post: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleFollowUser(String targetUserId) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in to follow users'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final profileService = ProfileService(authService: authService);
      final result = await profileService.followUser(userId!, targetUserId);
      if (result['success'] == true) {
        // Update local following status
        setState(() {
          _followingStatus[targetUserId] = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('User followed successfully'),
            backgroundColor: const Color(0xFFA855F7),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to follow user'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error following user: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleUnfollowUser(String targetUserId) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in to unfollow users'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final profileService = ProfileService(authService: authService);
      final result = await profileService.unfollowUser(userId!, targetUserId);
      if (result['success'] == true) {
        // Update local following status
        setState(() {
          _followingStatus[targetUserId] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('User unfollowed successfully'),
            backgroundColor: const Color(0xFFA855F7),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to unfollow user'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error unfollowing user: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = FeedWidget(
      feedItems: _feedItems,
      isLoading: _isLoading,
      error: _error,
      onRefresh: _loadPosts,
      onSongLike: (data_model.Post post) => _handleLike(post),
      onSongComment: (data_model.Post post) => _handleComment(post),
      onSongPlay: (data_model.Post post) => _handlePlay(post),
      onThoughtLike: (ThoughtsPost post) {},
      onThoughtComment: (ThoughtsPost post) {},
      onThoughtPlay: (ThoughtsPost post) {
        _handleThoughtsPlay(post);
      },
      currentlyPlayingTrackId: _currentlyPlayingTrackId,
      isPlaying: _isPlaying,
      currentUserId: userId,
      onPostOptions: _handlePostOptions,
      onUserTap: (String userId, String? username) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                UserProfilePage(userId: userId, username: username),
          ),
        );
      },
      onHidePost: (data_model.Post post) async {
        try {
          final result = await _songPostService.hidePost(post.id);
          if (result['success'] == true || result['hidden'] == true) {
            setState(() {
              _feedItems.removeWhere((item) => item.songPost?.id == post.id);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Post hidden successfully'),
                  backgroundColor: Colors.purple),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(result['message'] ?? 'Failed to hide post')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error hiding post: $e')),
          );
        }
      },
    );

    // When in shell mode, render with app bar but without bottom navigation
    if (widget.inShell) {
      return Scaffold(
        appBar: NootAppBar(),
        body: content,
      );
    }

    // LEGACY NAVIGATION SUPPORT - This code will eventually be removed
    // when all screens are migrated to the ShellScreen
    return Scaffold(
      // OLD NAVIGATION: App bar will be provided by ShellScreen in the future
      appBar: NootAppBar(),
      body: Column(
        children: [
          Expanded(
            child: content,
          ),
        ],
      ),
      // Bottom bar will be provided by ShellScreen in the future
      bottomNavigationBar: const BottomBar(),
    );
    // END LEGACY NAVIGATION SUPPORT
  }
}
