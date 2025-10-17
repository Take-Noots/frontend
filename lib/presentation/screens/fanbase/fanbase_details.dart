import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/data/models/fanbase_model.dart';
import 'package:frontend/data/services/auth_service.dart';
import 'package:frontend/data/services/fanbase_service.dart';
import 'package:frontend/presentation/widgets/fanbasepost/widgets/post_options_menu.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:frontend/presentation/screens/fanbasePost/fanbasePost_creation_screen.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/fanbase_post_model.dart';
import '../../../data/services/fanbase_post_service.dart';
import '../../widgets/common/bottom_bar.dart';
import '../fanbasePost/fanbasePost_screen.dart';
import '../profile/user_profiles.dart';
import '../../widgets/fanbasepost/fanbase_post_feed.dart';
import 'fanbase_details_creator_about.dart';
import 'fanbase_details_user_about.dart';

/// Fanbase detail screen showing fanbase information, posts, and management options
/// Handles ownership checking and displays appropriate UI based on user's relationship to the fanbase
class FanbaseDetailScreen extends StatefulWidget {
  final String fanbaseId;
  final String userId;

  const FanbaseDetailScreen({
    super.key,
    required this.fanbaseId,
    required this.userId,
  });

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
    print(
        'Ownership check: userId=$userId, createdBy.id=${_fanbase!.createdBy.id}, isOwner=$isOwner');
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
        post.id,
        context,
        fanbaseId: _fanbase!.id,
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

  // Add this method to _FanbaseDetailScreenState class
  Future<void> _handleDeleteFanbase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Fanbase'),
        content: Text(
          'Are you sure you want to permanently delete "${_fanbase?.fanbaseName}"? '
          'This will delete all posts and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && _fanbase != null) {
      setState(() => _isLoading = true);

      try {
        await FanbaseService.deleteFanbase(_fanbase!.id, context);

        if (mounted) {
          // Navigate back to previous screen after successful deletion
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fanbase deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete fanbase: $e')),
          );
        }
      }
    }
  }

  // Add this method to show options menu
  void _showFanbaseOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isCurrentUserOwner) ...[
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Delete Fanbase',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close bottom sheet
                    _handleDeleteFanbase();
                  },
                ),
                // ListTile(
                //   leading: const Icon(Icons.edit),
                //   title: const Text('Edit Fanbase'),
                //   onTap: () {
                //     Navigator.pop(context);
                //     // TODO: Navigate to edit fanbase screen
                //     ScaffoldMessenger.of(context).showSnackBar(
                //       const SnackBar(
                //           content: Text('Edit functionality coming soon')),
                //     );
                //   },
                // ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.flag, color: Colors.orange),
                  title: const Text('Report Fanbase'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement report functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Report functionality coming soon')),
                    );
                  },
                ),
              ],
              // ListTile(
              //   leading: const Icon(Icons.share),
              //   title: const Text('Share Fanbase'),
              //   onTap: () {
              //     Navigator.pop(context);
              //     Share.share(
              //       'Check out ${_fanbase?.fanbaseName} on Noot!',
              //       subject: 'Fanbase Invitation',
              //     );
              //   },
              // ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadFanbasePosts();
            });
          }

          Widget aboutTabContent;
          if (_isCurrentUserOwner) {
            aboutTabContent = FanbaseDetailsCreatorAbout(fanbase: _fanbase!);
          } else {
            aboutTabContent = FanbaseDetailsUserAbout(fanbase: _fanbase!);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FanbaseDetailsHeader(
                fanbase: _fanbase!,
                isCurrentUserOwner: _isCurrentUserOwner,
                selectedTabIndex: _selectedTabIndex,
                onTabChanged: (index) =>
                    setState(() => _selectedTabIndex = index),
                onPostCreated: () async {
                  final createdPost = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FanbasePostCreationScreen(
                        fanbaseId: _fanbase!.id,
                        fanbaseName: _fanbase!.fanbaseName,
                      ),
                    ),
                  );
                  if (createdPost != null) {
                    setState(() => _postFeedKey++);
                    await _refreshPosts();
                  }
                },
                onJoinPressed: _handleJoin,
                onOptionsPressed: _showFanbaseOptionsMenu, // Add this line
                isLoading: _isLoading,
              ),
              // Tab block separated from the header (white card with subtle shadow)
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(0),
                  border: Border.all(color: Colors.grey.shade500),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedTabIndex == 0
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[500],
                          foregroundColor: _selectedTabIndex == 0
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => setState(() => _selectedTabIndex = 0),
                        child: const Text('Feed'),
                      ),
                    ),
                    // const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedTabIndex == 1
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[500],
                          foregroundColor: _selectedTabIndex == 1
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => setState(() => _selectedTabIndex = 1),
                        child: const Text('About'),
                      ),
                    ),
                  ],
                ),
              ),
              // const SizedBox(height: ),
              if (_selectedTabIndex == 0)
                Expanded(
                  child: FanbaseDetailsFeed(
                    key: ValueKey(_postFeedKey),
                    fanbase: _fanbase!,
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
                )
              else
                aboutTabContent,
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

// =================== HEADER ===================
class FanbaseDetailsHeader extends StatelessWidget {
  final Fanbase fanbase;
  final bool isCurrentUserOwner;
  final int selectedTabIndex;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onPostCreated;
  final VoidCallback onJoinPressed;
  final VoidCallback onOptionsPressed; // Add this
  final bool isLoading;

  const FanbaseDetailsHeader({
    super.key,
    required this.fanbase,
    required this.isCurrentUserOwner,
    required this.selectedTabIndex,
    required this.onTabChanged,
    required this.onPostCreated,
    required this.onJoinPressed,
    required this.onOptionsPressed, // Add this
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final btnW = (screenW * 0.22).clamp(80.0, 140.0);

    return Container(
      color: Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.fromLTRB(8.0, 20.0, 8.0, 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(
                  fanbase.fanbasePhotoUrl ?? 'https://via.placeholder.com/150',
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
                            fanbase.fanbaseName,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary),
                          ),
                        ),
                        if (isCurrentUserOwner) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified,
                            size: 20,
                            color: Color(0xFFC20BF5),
                          ),
                        ],
                        const Spacer(),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          onPressed: onOptionsPressed, // Use the callback
                        ),
                      ],
                    ),
                    const SizedBox(height: 0.5),
                    Text(
                      '${fanbase.joinedUserIds.length} members',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                    if (isCurrentUserOwner)
                      const Text(
                        'Creator',
                        style: TextStyle(
                          color: Color(0xFFC20BF5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // --- "Post" button ---
              if (selectedTabIndex == 0 &&
                  (fanbase.isJoined || isCurrentUserOwner))
                SizedBox(
                  width: btnW,
                  child: OutlinedButton.icon(
                    onPressed: onPostCreated,
                    icon: Icon(LucideIcons.plus,
                        size: 16,
                        color: Theme.of(context).colorScheme.onPrimary),
                    label: const Text("Post"),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.zero,
                      minimumSize: Size(btnW, 36),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              // --- "Owner"/"Joined"/"Join" button ---
              SizedBox(
                width: btnW,
                child: isCurrentUserOwner
                    ? OutlinedButton(
                        onPressed: null,
                        style: OutlinedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.purple,
                          side: const BorderSide(color: Colors.purple),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.zero,
                          minimumSize: Size(btnW, 36),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Owner',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.purple),
                            ),
                          ],
                        ),
                      )
                    : fanbase.isJoined
                        ? OutlinedButton(
                            onPressed: onJoinPressed,
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.purple,
                              side: const BorderSide(color: Colors.purple),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: EdgeInsets.zero,
                              minimumSize: Size(btnW, 36),
                            ),
                            child: const Center(
                              child: Text(
                                'Joined',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          )
                        : OutlinedButton(
                            onPressed: onJoinPressed,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.purple),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: EdgeInsets.zero,
                              minimumSize: Size(btnW, 36),
                            ),
                            child: const Center(
                              child: Text(
                                'Join',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
              ),
            ],
          ),
          // const SizedBox(height: 2),
        ], // end Column children
      ), // end Column
    ); // end outer Container for header
  }
}

// =================== FEED TAB ===================
class FanbaseDetailsFeed extends StatelessWidget {
  final Fanbase fanbase;
  final List<FanbasePost> posts;
  final bool isLoading;
  final String? error;
  final VoidCallback onRefresh;
  final Function(FanbasePost) onLike;
  final Function(FanbasePost) onComment;
  final Function(FanbasePost) onPlay;
  final Function(FanbasePost) onShare;
  final Function(FanbasePost) onPostOptions;
  final String? currentlyPlayingTrackId;
  final bool isPlaying;
  final String? currentUserId;
  final void Function(String userId) onUserTap;

  const FanbaseDetailsFeed({
    super.key,
    required this.fanbase,
    required this.posts,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
    required this.onLike,
    required this.onComment,
    required this.onPlay,
    required this.onShare,
    required this.onPostOptions,
    required this.currentlyPlayingTrackId,
    required this.isPlaying,
    required this.currentUserId,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    return FanbasePostFeedWidget(
      fanbaseId: fanbase.id,
      posts: posts,
      isLoading: isLoading,
      error: error,
      onRefresh: onRefresh,
      onLike: onLike,
      onComment: onComment,
      onPlay: onPlay,
      onShare: onShare,
      onPostOptions: onPostOptions,
      currentlyPlayingTrackId: currentlyPlayingTrackId,
      isPlaying: isPlaying,
      currentUserId: currentUserId,
      onUserTap: onUserTap,
    );
  }
}
