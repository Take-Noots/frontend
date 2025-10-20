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
import '../../core/providers/feed_provider.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/route_names.dart';
import '../widgets/song_post/comment.dart';
import './profile/user_profiles.dart';
import '../widgets/song_post/post_options_menu.dart';
import '../../core/styles/app_colors.dart';

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

  // 🔑 REMOVED: Local feed state - now managed by FeedProvider
  // List<FeedItem> _feedItems = [];
  // bool _isLoading = true;
  // bool _hasLoadedOnce = false; // Cache flag - prevents re-fetching on navigation
  // String? _error;

  String? _currentlyPlayingTrackId;
  bool _isPlaying = false;
  String? userId;
  Map<String, bool> _followingStatus =
      {}; // Track following status for each user

  @override
  void initState() {
    super.initState();
    // 🔑 Load feed through FeedProvider (handles caching automatically)
    _loadUserIdAndInitializeFeed();

    // Check for Stripe redirect query params (e.g. ?payment=success)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final paymentStatus = Uri.base.queryParameters['payment'];
      if (paymentStatus != null) {
        if (paymentStatus == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Payment succeeded'),
              backgroundColor: Colors.green));
        } else if (paymentStatus == 'cancel') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Payment cancelled'),
              backgroundColor: Colors.orange));
        }
        // Clear query by navigating to home without params
        try {
          context.go(AppRoutes.home);
        } catch (_) {}
      }
    });
  }

  // 🔑 Initialize user ID and load feed through provider
  Future<void> _loadUserIdAndInitializeFeed() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    final userData = userDataString != null
        ? jsonDecode(userDataString)
        : {'id': '685fb750cc084ba7e0ef8533'};

    final userId = userData['id'];
      setState(() {
      this.userId = userId;
    });

    // 🔑 Load feed through FeedProvider (uses cache if available) - pass context for auth
    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    await feedProvider.loadFeed(userId, context: context);
  }

  // 🔑 Manual refresh - uses FeedProvider
  Future<void> _refreshFeed() async {
    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    await feedProvider.refreshFeed(context: context);
  }

  // 🔑 Invalidate cache - uses FeedProvider
  void _invalidateCache() {
    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    feedProvider.invalidateCache();
  }

  // Refresh posts after creating a new post
  Future<void> refreshPostsAfterCreation() async {
    await _refreshFeed(); // Use the refresh method to reload
  }

  // 🔑 REMOVED: _loadPosts() - now handled by FeedProvider

  // 🔑 REMOVED: _checkSavedStatusForPosts - not needed with FeedProvider

  void _handleLike(data_model.Post post) async {
    String? currentUserId = userId;
    if (currentUserId == null) {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      final userData =
          userDataString != null ? jsonDecode(userDataString) : {'id': ''};
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
      if (post.id != null) {
        await _songPostService.addRecentlyLikedPosts(
          currentUserId,
          post.id,
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
            } else if (result['success'] == false) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'Failed to add comment'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
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
    // Use the trackId directly from the post
    if (post.trackId == null || post.trackId!.isEmpty) {
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

  Future<void> _handleThoughtsLike(ThoughtsPost post) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to like posts'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final result = await _thoughtsService.likeThoughts(post.id, context);

      if (result['success'] == true) {
        // 🔑 Update the post in FeedProvider
        final feedProvider = Provider.of<FeedProvider>(context, listen: false);
        final itemIndex = feedProvider.feedItems
            .indexWhere((item) => item.thoughtsPost?.id == post.id);
        if (itemIndex != -1) {
          final item = feedProvider.feedItems[itemIndex];
          if (item.thoughtsPost != null) {
            // Toggle like status
            final isCurrentlyLiked =
                item.thoughtsPost!.likedBy.contains(userId!);
            final newLikedBy = List<String>.from(item.thoughtsPost!.likedBy);

            if (isCurrentlyLiked) {
              newLikedBy.remove(userId!);
            } else {
              newLikedBy.add(userId!);
            }

            final updatedPost = ThoughtsPost(
              id: item.thoughtsPost!.id,
              userId: item.thoughtsPost!.userId,
              username: item.thoughtsPost!.username,
              userImage: item.thoughtsPost!.userImage,
              text: item.thoughtsPost!.text,
              createdAt: item.thoughtsPost!.createdAt,
              updatedAt: item.thoughtsPost!.updatedAt,
              likes: isCurrentlyLiked
                  ? item.thoughtsPost!.likes - 1
                  : item.thoughtsPost!.likes + 1,
              likedBy: newLikedBy,
              comments: item.thoughtsPost!.comments,
              songName: item.thoughtsPost!.songName,
              artistName: item.thoughtsPost!.artistName,
              coverImage: item.thoughtsPost!.coverImage,
              backgroundColor: item.thoughtsPost!.backgroundColor,
              isHidden: item.thoughtsPost!.isHidden,
              isDeleted: item.thoughtsPost!.isDeleted,
              isSaved: item.thoughtsPost!.isSaved,
            );

            feedProvider.updatePost(post.id, FeedItem.thought(updatedPost));
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to like post'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error liking post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleThoughtsComment(ThoughtsPost post) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to comment on posts'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Fetch latest comments from database
    final commentsResult = await _thoughtsService.getComments(post.id, context);
    List<ThoughtsComment> latestComments = post.comments;

    if (commentsResult['success'] == true && commentsResult['data'] != null) {
      final postData = commentsResult['data'];
      if (postData['comments'] != null) {
        latestComments = (postData['comments'] as List<dynamic>)
            .map((c) => ThoughtsComment.fromJson(c))
            .toList();
      }
    }

    // Convert to Comment format
    final convertedComments = latestComments.map((thoughtsComment) {
      return data_model.Comment(
        id: thoughtsComment.id,
        userId: thoughtsComment.userId,
        username: thoughtsComment.username,
        text: thoughtsComment.text,
        createdAt: thoughtsComment.createdAt,
        likes: thoughtsComment.likes,
        likedBy: thoughtsComment.likedBy,
      );
    }).toList();

    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: CommentSection(
            postId: post.id,
            comments: convertedComments,
            currentUserId: userId!,
            songPostService: _ThoughtsToSongPostAdapter(_thoughtsService),
            onAddComment: (text) async {
              try {
                final result = await _thoughtsService.addComment(
                  post.id,
                  userId!,
                  text,
                  context,
                );

                // Check if success - handle different response formats
                bool isSuccess = false;
                if (result['success'] is bool) {
                  isSuccess = result['success'];
                } else if (result['success'] is int) {
                  isSuccess = result['success'] == 1;
                } else if (result['success'] is String) {
                  isSuccess =
                      result['success'].toString().toLowerCase() == 'true';
                }

                if (isSuccess && result['data'] != null) {
                  List<dynamic>? commentsData;

                  // Handle different response structures
                  if (result['data']['comments'] != null) {
                    commentsData = result['data']['comments'] as List<dynamic>;
                  } else if (result['data'] is List) {
                    commentsData = result['data'] as List<dynamic>;
                  } else if (result['comments'] != null) {
                    commentsData = result['comments'] as List<dynamic>;
                  }

                  if (commentsData != null) {
                    final updatedComments = commentsData
                        .map((c) => ThoughtsComment.fromJson(c))
                        .toList();

                    // Convert to Comment format
                    final convertedUpdatedComments =
                        updatedComments.map((thoughtsComment) {
                      return data_model.Comment(
                        id: thoughtsComment.id,
                        userId: thoughtsComment.userId,
                        username: thoughtsComment.username,
                        text: thoughtsComment.text,
                        createdAt: thoughtsComment.createdAt,
                        likes: thoughtsComment.likes,
                        likedBy: thoughtsComment.likedBy,
                      );
                    }).toList();

                    return convertedUpdatedComments;
                  }
                }

                // If we get here, something went wrong
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? 'Failed to add comment'),
                    backgroundColor: Colors.red,
                  ),
                );

                return convertedComments;
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error adding comment: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
                return convertedComments;
              }
            },
          ),
        ),
      );
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
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        final errorData = e.response!.data;

        // Check for Spotify not linked error
        if (errorData is Map && errorData['requiresSpotifyLink'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Please connect your Spotify account to play music'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Connect',
                textColor: Colors.white,
                onPressed: () {
                  // Navigate to settings/options page where Spotify linking is available
                  context.go(AppRoutes.options);
                },
              ),
            ),
          );
          return;
        }

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
            // 🔑 Use FeedProvider to remove post
            final feedProvider =
                Provider.of<FeedProvider>(context, listen: false);
            feedProvider.removePost(post.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Post deleted successfully'),
                backgroundColor: AppColors.primaryPurple,
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
            backgroundColor: AppColors.primaryPurple,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 2),
          ),
        );
        // 🔑 REMOVED: Feed update not needed for save status (handled by individual posts)
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to save post'),
            backgroundColor: AppColors.primaryPurple,
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
          backgroundColor: AppColors.primaryPurple,
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
            backgroundColor: AppColors.primaryPurple,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 2),
          ),
        );
        // 🔑 REMOVED: Feed update not needed for save status (handled by individual posts)
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
    // 🔑 Get FeedProvider data
    final feedProvider = Provider.of<FeedProvider>(context);

    Widget content = FeedWidget(
      feedItems: feedProvider.feedItems, // 🔑 Use provider data
      isLoading: feedProvider.isLoading,
      error: feedProvider.error,
      onRefresh: _refreshFeed, // 🔑 Use refresh method for pull-to-refresh
      onSongLike: (data_model.Post post) => _handleLike(post),
      onSongComment: (data_model.Post post) => _handleComment(post),
      onSongPlay: (data_model.Post post) => _handlePlay(post),
      onThoughtLike: (ThoughtsPost post) {
        _handleThoughtsLike(post);
      },
      onThoughtComment: (ThoughtsPost post) {
        _handleThoughtsComment(post);
      },
      onThoughtPlay: (ThoughtsPost post) {
        _handleThoughtsPlay(post);
      },
      onThoughtHide: (ThoughtsPost post) async {
        try {
          final result = await _thoughtsService.hidePost(post.id);
          if (result['success'] == true) {
            // 🔑 Use FeedProvider to remove post
            final feedProvider =
                Provider.of<FeedProvider>(context, listen: false);
            feedProvider.removePost(post.id);
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
            // 🔑 Use FeedProvider to remove post
            final feedProvider =
                Provider.of<FeedProvider>(context, listen: false);
            feedProvider.removePost(post.id);
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

// Adapter class to make ThoughtsService compatible with SongPostService
class _ThoughtsToSongPostAdapter extends SongPostService {
  final ThoughtsService _thoughtsService;

  _ThoughtsToSongPostAdapter(this._thoughtsService);

  @override
  Future<Map<String, dynamic>> likeComment(
      String postId, String commentId, String userId,
      [BuildContext? context]) async {
    return await _thoughtsService.likeComment(
        postId, commentId, userId, context);
  }
}
