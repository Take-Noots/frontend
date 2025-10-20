import 'package:flutter/material.dart';
// import '../../widgets/home/header_bar.dart';
import '../../widgets/home/feed_widget.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../data/models/post_model.dart' as data_model;
import '../../../data/models/feed_item.dart';
import '../../../data/services/profile_service.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/services/song_post_service.dart';
import '../../../data/services/auth_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../../widgets/song_post/comment.dart';
import '../../widgets/song_post/post_options_menu.dart';
import '../song_posts/update.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import './user_profiles.dart';
import '../../../core/styles/app_colors.dart';
import '../../../../presentation/widgets/loading_screens/common_loading.dart';

class ProfileFeedScreen extends StatefulWidget {
  final String userId;
  final String? initialPostId; // Make this nullable

  const ProfileFeedScreen({
    Key? key,
    required this.userId,
    this.initialPostId, // Remove required keyword
  }) : super(key: key);

  @override
  State<ProfileFeedScreen> createState() => _ProfileFeedScreenState();
}

class _ProfileFeedScreenState extends State<ProfileFeedScreen> {
  List<data_model.Post> _posts = [];
  bool _isLoading = true;
  String? _error;
  int _initialIndex = 0;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final SongPostService _songPostService = SongPostService();
  bool _isPlaying = false;
  String? _currentlyPlayingTrackId;
  String? _currentUserId;
  Map<String, bool> _followingStatus =
      {}; // Track following status for each user

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndPosts();
  }

  Future<void> _loadCurrentUserAndPosts() async {
    // Get current user ID from shared preferences
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      final userData = jsonDecode(userDataString);
      _currentUserId = userData['id'];
    }

    await _loadProfilePosts();
  }

  Future<void> _loadProfilePosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final profileService = ProfileService();
      final postsResult = await profileService.getUserPosts(widget.userId);
      final posts = postsResult.map<data_model.Post>((json) {
        final post = data_model.Post.fromJson(json);
        post.likedByMe =
            (json['likedBy'] as List<dynamic>?)?.contains(_currentUserId) ??
                false;
        return post;
      }).toList();

      // Fetch username and profile image for the profile
      String? username;
      String? profileImage;
      try {
        final profileResult =
            await profileService.getUserProfile(widget.userId);
        if (profileResult['success'] == true && profileResult['data'] != null) {
          final profile = ProfileModel.fromJson(profileResult['data']);
          username = profile.username;
          profileImage = profile.profileImage;
        }
      } catch (_) {}

      // Handle the case where initialPostId might be null
      int initialIndex = 0;
      if (widget.initialPostId != null && widget.initialPostId!.isNotEmpty) {
        initialIndex = posts.indexWhere((p) => p.id == widget.initialPostId);
        if (initialIndex == -1) initialIndex = 0;
        print("Initial post ID: ${widget.initialPostId}");
        print("Found at index: $initialIndex");
      }

      // Patch username and userImage if missing and copyWith is available
      final postsWithUsernameAndImage = posts.map((post) {
        bool needsUpdate = false;
        String? newUsername = post.username;
        String? newUserImage = post.userImage;

        if ((post.username == null || post.username!.isEmpty) &&
            username != null) {
          newUsername = username;
          needsUpdate = true;
        }

        if ((post.userImage == null || post.userImage!.isEmpty) &&
            profileImage != null) {
          newUserImage = profileImage;
          needsUpdate = true;
        }

        if (needsUpdate) {
          return post.copyWith(username: newUsername, userImage: newUserImage);
        }
        return post;
      }).toList();

      setState(() {
        _posts = postsWithUsernameAndImage;
        _initialIndex = initialIndex;
        _isLoading = false;
      });

      // Scroll to the tapped post after the first frame using scrollable_positioned_list
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_itemScrollController.isAttached && _initialIndex > 0) {
          print("Scrolling to index: $_initialIndex");
          try {
            _itemScrollController.jumpTo(index: _initialIndex);
          } catch (e) {
            print("Error scrolling: $e");
          }
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load posts: $e';
        _isLoading = false;
      });
    }
  }

  void _handleLike(data_model.Post post) async {
    String? currentUserId = _currentUserId;
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

    //print('[DEBUG] ProfileScreen: Attempting to like post ${post.id}');
    //print('[DEBUG] ProfileScreen: Current user ID: $currentUserId');

    final result =
        await _songPostService.likePost(post.id, currentUserId, context);
    //print('[DEBUG] ProfileScreen: Like result: $result');

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
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
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

            // Handle different success response formats
            bool isSuccess = false;
            if (result['success'] is bool) {
              isSuccess = result['success'];
            } else if (result['success'] is int) {
              isSuccess = result['success'] == 1;
            } else if (result['success'] is String) {
              isSuccess = result['success'].toString().toLowerCase() == 'true';
            }

            if (isSuccess && result['data'] != null) {
              final updatedComments =
                  (result['data']['comments'] as List<dynamic>)
                      .map((c) => data_model.Comment.fromJson(c))
                      .toList();
              setState(() {
                post.comments = updatedComments;
              });
              return updatedComments;
            } else {
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
          currentUserId: _currentUserId ?? '',
          songPostService: _songPostService,
        ),
      ),
    );
  }

  Future<void> _handlePlay(data_model.Post post) async {
    //print('[DEBUG] HandlePlay: trackId=${post.trackId}, currentlyPlaying=$_currentlyPlayingTrackId, isPlaying=$_isPlaying');

    if (_currentlyPlayingTrackId == post.trackId && _isPlaying) {
      //print('[DEBUG] HandlePlay: Pausing current track');
      setState(() {
        _isPlaying = false;
      });
      try {
        await _pausePlayback();
      } catch (e) {
        print('[DEBUG] HandlePlay: Error pausing - $e');
        setState(() {
          _isPlaying = true;
        });
      }
    } else {
      //print('[DEBUG] HandlePlay: Playing new track');
      setState(() {
        _currentlyPlayingTrackId = post.trackId;
        _isPlaying = true;
      });
      try {
        await _playTrack(post);
      } catch (e) {
        //print('[DEBUG] HandlePlay: Error playing - $e');
        setState(() {
          _isPlaying = false;
          _currentlyPlayingTrackId = null;
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
      } else {
        print(
            '[DEBUG] PlayTrack: Unexpected status code: ${response.statusCode}');
      }
    } catch (e) {
      print('[DEBUG] PlayTrack Error: $e');
      setState(() {
        _isPlaying = false;
        _currentlyPlayingTrackId = null;
      });
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
      } else {
        print(
            '[DEBUG] PausePlayback: Unexpected status code: ${response.statusCode}');
      }
    } catch (e) {
      print('[DEBUG] PausePlayback Error: $e');
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _handleShare(data_model.Post post) {
    final shareText =
        'Check out this song: ${post.songName} by ${post.artists}';
    Share.share(shareText, subject: 'Music from Noot');
  }

  Future<void> _handlePostOptions(data_model.Post post) async {
    // Check if either ID is null or empty
    if (post.userId == null || post.userId!.isEmpty) {
      // WARNING: Post userId is null or empty
    }
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      // WARNING: Current userId is null or empty
    }

    bool isUsersOwnPost = false;
    if (post.userId != null && _currentUserId != null) {
      isUsersOwnPost = post.userId == _currentUserId;
    } else {
      // Cannot determine if post is user's own due to null IDs
    }

    // Check if post is saved
    bool isSaved = false;
    if (_currentUserId != null) {
      try {
        final savedResult = await _songPostService.isPostSaved(
            _currentUserId!, post.id, context);
        isSaved = savedResult['isSaved'] ?? false;
      } catch (e) {
        // If we can't check saved status, assume it's not saved
        isSaved = false;
      }
    }

    // Check if current user is following the post's author
    bool isFollowing = false;
    if (_currentUserId != null &&
        post.userId != null &&
        _currentUserId != post.userId) {
      // Use cached following status if available, otherwise check from API
      if (_followingStatus.containsKey(post.userId)) {
        isFollowing = _followingStatus[post.userId]!;
      } else {
        try {
          final authService = Provider.of<AuthService>(context, listen: false);
          final profileService = ProfileService(authService: authService);
          final followingList =
              await profileService.getFollowingListWithDetails(_currentUserId!);
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
      currentUserId: _currentUserId,
      postId: post.id,
      isOwnPost: isUsersOwnPost,
      isSaved: isSaved,
      isFollowing: isFollowing,
      onSharePost: () {
        final shareText =
            'Check out this song: ${post.songName} by ${post.artists}';
        Share.share(shareText, subject: 'Music from Noot');
      },
      onSavePost: () async {
        if (_currentUserId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please log in to save posts'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(10),
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }

        try {
          final result = await _songPostService.savePost(
              _currentUserId!, post.id, context);
          if (result['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Post saved successfully'),
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
                content: Text(result['message'] ?? 'Failed to save post'),
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
              content: Text('Error saving post: $e'),
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
      onUnsavePost: () async {
        if (_currentUserId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please log in to unsave posts'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(10),
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }

        try {
          final result = await _songPostService.unsavePost(
              _currentUserId!, post.id, context);
          if (result['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Post unsaved successfully'),
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
                content: Text(result['message'] ?? 'Failed to unsave post'),
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
              content: Text('Error unsaving post: $e'),
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
      onUnfollow: () async {
        await _handleUnfollowUser(post.userId!);
      },
      onFollow: () async {
        await _handleFollowUser(post.userId!);
      },
      onReport: () {
        // Report functionality is handled inside PostOptionsMenu
      },
      onEdit: isUsersOwnPost
          ? () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditPostScreen(post: post),
                ),
              );
              if (result == true) {
                
                _loadProfilePosts();
              }
            }
          : null,
      onDelete: () async {
        // Show confirmation dialog
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Theme.of(context).dialogBackgroundColor,
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFA855F7)),
                SizedBox(width: 8),
                Text('Delete Post',
                    style: TextStyle(
                        color: Color(0xFFA855F7), fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              'Are you sure you want to delete this post? This action cannot be undone.',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface, fontSize: 15),
            ),
            actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  textStyle: TextStyle(fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFA855F7),
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  textStyle: TextStyle(fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('Delete'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          try {
            final result = await _songPostService.deletePost(post.id);
            if (result['success']) {
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
              // Refresh posts after deletion
              _loadProfilePosts();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'Failed to delete post'),
                  backgroundColor: Theme.of(context).colorScheme.error,
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
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(10),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      onHide: () async {
        try {
          final result = await _songPostService.hidePost(post.id);
          if (result['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Post hidden from your feed'),
                backgroundColor: AppColors.primaryPurple,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(10),
                duration: const Duration(seconds: 2),
              ),
            );
            _loadProfilePosts(); 
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to hide post'),
                backgroundColor: Theme.of(context).colorScheme.error,
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
              content: Text('Error hiding post: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(10),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  Future<void> _handleFollowUser(String targetUserId) async {
    if (_currentUserId == null) {
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
      final result =
          await profileService.followUser(_currentUserId!, targetUserId);
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
    if (_currentUserId == null) {
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
      final result =
          await profileService.unfollowUser(_currentUserId!, targetUserId);
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CommonLoading.purple()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
            child: Text(_error!,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface))),
      );
    }

    // Ensure scrolling to initial position happens after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_itemScrollController.isAttached && _initialIndex > 0) {
        try {
          _itemScrollController.scrollTo(
            index: _initialIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } catch (e) {
          print("Error scrolling: $e");
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Feed'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // Removed theme toggle button from actions
        actions: [],
      ),
      body: FeedWidget(
        feedItems: _posts.map((p) => FeedItem.song(p)).toList(),
        isLoading: false,
        error: null,
        onRefresh: _loadProfilePosts,
        onSongLike: (data_model.Post post) => _handleLike(post),
        onSongComment: (data_model.Post post) => _handleComment(post),
        onSongPlay: (data_model.Post post) => _handlePlay(post),
        onSongShare: (data_model.Post post) => _handleShare(post),
        currentlyPlayingTrackId: _currentlyPlayingTrackId,
        isPlaying: _isPlaying,
        currentUserId: _currentUserId,
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
        itemScrollController: _itemScrollController,
        itemPositionsListener: _itemPositionsListener,
        initialIndex: _initialIndex,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }
}
