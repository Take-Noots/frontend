import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
// import 'package:frontend/presentation/screens/demopost/des_post_home.dart';
import 'package:frontend/data/models/fanbase_model.dart';
import 'package:frontend/data/services/auth_service.dart';
import 'package:frontend/data/services/fanbase_service.dart';
// import 'package:frontend/presentation/widgets/fanbasepost/widgets/fanbase_post_content_widget.dart'
//     as data_model;
import 'package:frontend/presentation/widgets/fanbasepost/widgets/post_options_menu.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:frontend/presentation/widgets/fanbasepost/fanbase_post_feed.dart';
import 'package:frontend/presentation/screens/fanbasePost/fanbasePost_creation_screen.dart';
// import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/fanbase_post_model.dart';
import '../../../data/services/fanbase_post_service.dart';
import '../../widgets/common/bottom_bar.dart';
import '../fanbasePost/fanbasePost_screen.dart';
import '../profile/user_profiles.dart';

class FanbaseDetailScreen extends StatefulWidget {
  final String fanbaseId;
  final String userId;

  const FanbaseDetailScreen(
      {super.key, required this.fanbaseId, required this.userId});

  @override
  State<FanbaseDetailScreen> createState() => _FanbaseDetailScreenState();
}

class _FanbaseDetailScreenState extends State<FanbaseDetailScreen> {
  late Future<Fanbase> _fanbaseFuture;
  Fanbase? _fanbase;

  int _selectedTabIndex = 0; // 0 = Feed, 1 = About

  List<FanbasePost> _fanbasePosts = []; // List to hold fanbase posts
  bool _isLoading = false;
  int _postFeedKey = 0; // Add this to track feed refreshes
  String? _error; // To capture any errors during post loading
  String? userId; // Assuming you have a way to get the current user's ID
  String? _currentlyPlayingTrackId;
  bool _isPlaying = false;

  // final ScrollController _scrollController = ScrollController();
  final Map<String, Color> _extractedColors = {};
  final Color _defaultColor = const Color.fromARGB(255, 17, 37, 37);

  @override
  void initState() {
    super.initState();
    _loadUserIdAndPosts(); // Load user ID and initial posts
    _fanbaseFuture = FanbaseService.getFanbaseById(widget.fanbaseId, context);
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
    await _loadFanbasePosts();
  }

  // Refresh posts after creating a new post
  Future<void> refreshPostsAfterCreation() async {
    print('Refreshing posts after new post creation...');
    await _loadFanbasePosts();
  }

  Future<void> _loadFanbasePosts() async {
    if (_fanbase == null) return; // Wait for fanbase to load

    try {
      setState(() {
        _isLoading = true;
        _error = null; // Reset error state
      });

      // Use FanbasePostService instead of FanbaseService
      final posts = await FanbasePostService.getFanbasePosts(
        _fanbase!.id,
        context,
        page: 1,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _fanbasePosts = posts; // Update the fanbase with new posts
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _loadFanbasePosts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString(); // Capture the error
        });
      }
    }
  }

  Future<void> _refreshPosts() async {
    await _loadFanbasePosts();
  }

  Future<void> _handleLike(FanbasePost post) async {
    try {
      print('Like button pressed for post: ${post.id}');

      // Optimistically update the UI
      final postIndex = _fanbasePosts.indexWhere((p) => p.id == post.id);
      if (postIndex != -1) {
        final updatedPost = post.copyWith(
          isLiked: !post.isLiked,
          likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
        );

        setState(() {
          _fanbasePosts[postIndex] = updatedPost;
        });
      }

      // Make the API call
      final updatedPost = await FanbasePostService.likeFanbasePost(
        _fanbase!.id,
        post.id,
        context,
      );

      // Update with the actual response
      if (mounted) {
        final index = _fanbasePosts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          setState(() {
            _fanbasePosts[index] = updatedPost;
          });
        }
      }
    } catch (e) {
      // Revert optimistic update on error
      final postIndex = _fanbasePosts.indexWhere((p) => p.id == post.id);
      if (postIndex != -1) {
        setState(() {
          _fanbasePosts[postIndex] = post; // Revert to original
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error liking post: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleComment(FanbasePost post) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PostDetailPage(
            postId: post.id,
            trackId: post.spotifyTrackId ?? '',
            songName: post.songName ?? '',
            artists: post.artistName ?? '',
            albumImage: post.albumArt ?? '',
            comments: post.comments
                .map((comment) => {
                      'username': comment.userName,
                      'text': comment.comment,
                      'userId': comment.userId,
                      'likeCount': comment.likeCount.toString(),
                      'createdAt': comment.createdAt.toIso8601String(),
                    })
                .toList(),
            username: post.createdBy['userName'] ?? 'Unknown User',
            userImage: 'assets/images/profile_picture.jpg',
            title: post.topic,
            description: post.description,
            isLiked: post.isLiked,
            isPlaying: false,
            isCurrentTrack: false,
            backgroundColor:
                _extractedColors[post.albumArt ?? ''] ?? _defaultColor,
            fanbaseId: widget.fanbaseId,
            likesCount: post.likesCount,
            commentsCount: post.commentsCount,
          ),
        ),
      );

      // If a comment was added (result == true), refresh the posts to get updated counts
      if (result == true) {
        await _refreshPosts();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error navigating to post detail: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Handles toggling the join status by trusting the backend response.
  Future<void> _handleJoin() async {
    if (_isLoading || _fanbase == null) return;

    setState(() => _isLoading = true);

    try {
      // Call the service and wait for the definitive response
      final updatedFanbase =
          await FanbaseService.joinFanbase(_fanbase!.id, context);

      print('Updated fanbase: ${updatedFanbase.toJson()}');

      // Trust the backend's response to update the state
      if (mounted) {
        setState(() {
          _fanbase = updatedFanbase;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Updated to work with FanbasePost instead of data_model.Post
  Future<void> _handlePlay(FanbasePost post) async {
    final trackId = post.spotifyTrackId;
    if (trackId == null || trackId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No track available for this post')),
      );
      return;
    }

    if (_currentlyPlayingTrackId == trackId && _isPlaying) {
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
        _currentlyPlayingTrackId = trackId;
        _isPlaying = true;
      });
      try {
        await _playTrack(trackId);
      } catch (e) {
        setState(() {
          _isPlaying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to play track: $e')),
        );
      }
    }
  }

  // Updated to take trackId directly
  Future<void> _playTrack(String trackId) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;
      final response = await dio.post(
        '/spotify/player/post/play',
        data: {'track_id': trackId},
      );
      if (response.statusCode == 200 ||
          response.statusCode == 202 ||
          response.statusCode == 204) {
        setState(() {
          _currentlyPlayingTrackId = trackId;
          _isPlaying = true;
        });
      }
    } catch (e) {
      String errorMsg = 'Failed to play track';
      if (e is DioError && e.response != null && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          errorMsg = data['message'];
        } else if (data is String) {
          errorMsg = data;
        }
      }
      throw Exception(errorMsg);
    }
  }

  Future<void> _pausePlayback() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;
      final response = await dio.put('/spotify/player/post/pause');
      print('function called');
      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _isPlaying = false;
        });
      }
    } catch (e) {
      print('Error pausing playback: $e');
    }
  }

  // Updated to work with FanbasePost
  void _handleShare(FanbasePost post) {
    final shareText =
        'Check out this song: ${post.songName ?? 'Unknown Song'} by ${post.artistName ?? 'Unknown Artist'}';
    Share.share(shareText, subject: 'Music from Noot');
  }

  void _handlePostOptions(FanbasePost post) {
    print('FanbaseDetails _handlePostOptions - Post ID: ${post.id}');
    print(
        'FanbaseDetails _handlePostOptions - Post User ID: ${post.createdBy['userId']}');
    print('FanbaseDetails _handlePostOptions - Current User ID: $userId');

    bool isUsersOwnPost = false;
    if (post.createdBy['userId'] != null && userId != null) {
      isUsersOwnPost = post.createdBy['userId'] == userId;
      print('Calculated isUsersOwnPost: $isUsersOwnPost');
    }

    PostOptionsMenu.show(
      context,
      postUserId: post.createdBy['userId'],
      currentUserId: userId,
      isOwnPost: isUsersOwnPost,
      onCopyLink: () {
        print('Copy link pressed for fanbase post: ${post.id}');
      },
      onSavePost: () {
        print('Save post pressed for fanbase post: ${post.id}');
      },
      onUnfollow: () {
        print('Unfollow pressed for fanbase post: ${post.id}');
      },
      onReport: () {
        print('Report pressed for fanbase post: ${post.id}');
      },
      onEdit: isUsersOwnPost
          ? () {
              print('Edit post pressed for fanbase post: ${post.id}');
            }
          : null,
      onDelete: isUsersOwnPost
          ? () {
              print('Delete post pressed for fanbase post: ${post.id}');
            }
          : null,
      onHide: isUsersOwnPost
          ? () {
              print('Hide post pressed for fanbase post: ${post.id}');
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Fanbase>(
        future: _fanbaseFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Error loading fanbase'));
          }

          if (_fanbase == null) {
            _fanbase = snapshot.data!;
            // Load posts after fanbase is loaded
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadFanbasePosts();
            });
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.fromLTRB(8.0, 20.0, 8.0, 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(
                            _fanbase!.fanbasePhotoUrl ??
                                'https://via.placeholder.com/150',
                          ),
                          radius: 24,
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          onBackgroundImageError: (exception, stackTrace) {},
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _fanbase!.fanbaseName,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary),
                              ),
                              const SizedBox(height: 0.5),
                              Text(
                                '${_fanbase!.joinedUserIds.length} members',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        // You can add more widgets here if needed
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (_selectedTabIndex == 0)
                          OutlinedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      FanbasePostCreationScreen(
                                    fanbaseId: _fanbase!.id,
                                    fanbaseName: _fanbase!.fanbaseName,
                                  ),
                                ),
                              );
                              if (result != null) {
                                setState(() {
                                  _postFeedKey++;
                                });
                                await _refreshPosts();
                              }
                            },
                            icon: const Icon(LucideIcons.plus, size: 16),
                            label: const Text(" Post"),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 100,
                          child: OutlinedButton(
                            onPressed: _handleJoin,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _fanbase!.isJoined
                                  ? Colors.white
                                  : Colors.purple,
                              foregroundColor: _fanbase!.isJoined
                                  ? Colors.purple
                                  : Colors.white,
                              side: const BorderSide(color: Colors.purple),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _fanbase!.isJoined
                                            ? Colors.purple
                                            : Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(_fanbase!.isJoined ? 'Joined' : 'Join'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // const SizedBox(height: 16),

              const SizedBox(height: 2),
              // ===== Tab Buttons =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedTabIndex == 0
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[300],
                          foregroundColor: _selectedTabIndex == 0
                              ? Theme.of(context).colorScheme.onPrimary
                              : Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedTabIndex = 0;
                          });
                        },
                        child: const Text('Feed'),
                      ),
                    ),
                    const SizedBox(width: 1),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedTabIndex == 1
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[300],
                          foregroundColor: _selectedTabIndex == 1
                              ? Theme.of(context).colorScheme.onPrimary
                              : Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedTabIndex = 1;
                          });
                        },
                        child: const Text('About'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),

              // ===== Tab Content =====
              if (_selectedTabIndex == 0) ...[
                // Feed Tab
                Expanded(
                  child: FanbasePostFeedWidget(
                    key: ValueKey(_postFeedKey),
                    fanbaseId: _fanbase!.id,
                    posts: _fanbasePosts,
                    isLoading: _isLoading,
                    error: _error,
                    onRefresh: _loadFanbasePosts,
                    onLike: _handleLike,
                    onComment: _handleComment,
                    onPlay: _handlePlay,
                    onShare: _handleShare,
                    onPostOptions: _handlePostOptions,
                    currentlyPlayingTrackId: _currentlyPlayingTrackId,
                    isPlaying: _isPlaying,
                    currentUserId: userId,
                    onUserTap: (String userId) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfilePage(userId: userId),
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                // About Tab
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fanbase!.fanbaseTopic,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '${_fanbase!.joinedUserIds.length} members',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                        )
                        // Add more about info here if needed
                      ],
                    ),
                  ),
                ),
              ],

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Center(
                  child: Text(
                    'Members: ${_fanbase!.joinedUserIds.length}', // Replace memberCount with your actual property
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const BottomBar(),
    );
  }
}
