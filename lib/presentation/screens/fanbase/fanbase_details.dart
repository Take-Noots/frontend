import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/data/models/fanbase_model.dart';
import 'package:frontend/data/services/auth_service.dart';
import 'package:frontend/data/services/fanbase_service.dart';
import 'package:frontend/presentation/widgets/fanbasepost/widgets/post_options_menu.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:frontend/presentation/widgets/fanbasepost/fanbase_post_feed.dart';
import 'package:frontend/presentation/screens/fanbasePost/fanbasePost_creation_screen.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/fanbase_post_model.dart';
import '../../../data/services/fanbase_post_service.dart';
import '../../widgets/common/bottom_bar.dart';
import '../fanbasePost/fanbasePost_screen.dart';
import '../profile/user_profiles.dart';

/// Fanbase detail screen showing fanbase information, posts, and management options
/// Handles ownership checking and displays appropriate UI based on user's relationship to the fanbase
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
  String? userId; // Current user's ID
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

  /// Loads current user ID from SharedPreferences and initializes posts
  Future<void> _loadUserIdAndPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    final userData = userDataString != null
        ? jsonDecode(userDataString)
        : {'id': '685fb750cc084ba7e0ef8533'}; // Fallback for testing
    setState(() {
      userId = userData['id'];
    });
    print('Current user ID loaded: $userId');
    await _loadFanbasePosts();
  }

  /// Checks if the current user is the owner of this fanbase
  /// Compares current user ID with fanbase creator's ID
  bool get _isCurrentUserOwner {
    if (userId == null || _fanbase == null) {
      return false;
    }
    
    final isOwner = userId == _fanbase!.createdBy.id;
    print('Ownership check: userId=$userId, createdBy.id=${_fanbase!.createdBy.id}, isOwner=$isOwner');
    return isOwner;
  }

  /// Refresh posts after creating a new post
  Future<void> refreshPostsAfterCreation() async {
    print('Refreshing posts after new post creation...');
    await _loadFanbasePosts();
  }

  /// Loads fanbase posts from the service
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

  /// Refreshes the posts list
  Future<void> _refreshPosts() async {
    await _loadFanbasePosts();
  }

  /// Handles liking/unliking a post with optimistic UI updates
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

  /// Handles navigating to post detail page for commenting
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

  /// Handles toggling the join status by trusting the backend response
  /// Owners cannot join/leave their own fanbase
  Future<void> _handleJoin() async {
    if (_isLoading || _fanbase == null || _isCurrentUserOwner) return;

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

  /// Handles playing/pausing Spotify tracks
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

  /// Plays a Spotify track using the backend API
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

  /// Pauses Spotify playback
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

  /// Handles sharing a post
  void _handleShare(FanbasePost post) {
    final shareText =
        'Check out this song: ${post.songName ?? 'Unknown Song'} by ${post.artistName ?? 'Unknown Artist'}';
    Share.share(shareText, subject: 'Music from Noot');
  }

  /// Handles post options menu (edit, delete, etc.)
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

  /// Builds the join/owned button based on ownership status
  Widget _buildJoinButton() {
    if (_isCurrentUserOwner) {
      // Show "Owned" button for fanbase owners
      return SizedBox(
        width: 100,
        child: OutlinedButton(
          onPressed: null, // Disabled since it's owned
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.green[50],
            foregroundColor: Colors.green[700],
            side: BorderSide(color: Colors.green[300]!),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified,
                size: 14,
                color: Colors.green[700],
              ),
              const SizedBox(width: 4),
              const Text('Owned'),
            ],
          ),
        ),
      );
    } else {
      // Show Join/Joined button for non-owners
      return SizedBox(
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
      );
    }
  }

  /// Builds the header section with fanbase info and ownership indicators
  Widget _buildHeaderSection() {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(
            _fanbase!.fanbasePhotoUrl ??
                'https://via.placeholder.com/150',
          ),
          radius: 24,
          backgroundColor: Theme.of(context).colorScheme.surface,
          onBackgroundImageError: (exception, stackTrace) {},
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      _fanbase!.fanbaseName,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  // Crown icon for owned fanbases
                  if (_isCurrentUserOwner) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.crown,
                      size: 20,
                      color: Colors.amber[600],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 0.5),
              Text(
                '${_fanbase!.joinedUserIds.length} members',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
              // "Creator" label for owned fanbases
              if (_isCurrentUserOwner)
                Text(
                  'Creator',
                  style: TextStyle(
                    color: Colors.amber[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
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
                    // Enhanced header with ownership indicators
                    _buildHeaderSection(),
                    
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Only show post button on Feed tab and for members/owners
                        if (_selectedTabIndex == 0 && (_fanbase!.isJoined || _isCurrentUserOwner))
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
                        
                        // Dynamic join/owned button
                        _buildJoinButton(),
                      ],
                    ),
                  ],
                ),
              ),

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
                          _fanbase!.fanbaseName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
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
                        ),
                        Text(
                          'Created by ${_fanbase!.createdBy.username}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                        Text(
                          'Created on ${_fanbase!.createdAt.toLocal().toString().split(' ')[0]}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                      
                        const SizedBox(height: 16),
                        
                        // Show owner-specific options
                        if (_isCurrentUserOwner)
                          ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Implement fanbase guide/rules creation logic
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Add Fanbase Guide'),
                                  content: const Text(
                                    'Here you can add rules or a guide for your fanbase.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('  + Add a fanbase guide '),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        // Add more about info here if needed
                      ],
                    ),
                  ),
                ),
              ],

              // Bottom member count
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Center(
                  child: Text(
                    'Members: ${_fanbase!.joinedUserIds.length}',
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
