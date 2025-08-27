import 'package:flutter/material.dart';
import '../../widgets/home/header_bar.dart';
import '../../widgets/common/bottom_bar.dart';
import '../../widgets/home/feed_widget.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../data/models/post_model.dart' as data_model;
import '../../../data/models/feed_item.dart';
import '../../../data/services/profile_service.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/services/song_post_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../../widgets/song_post/comment.dart';
import '../../widgets/song_post/post_options_menu.dart';
import '../song_posts/update.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import './user_profiles.dart';

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
      final posts = postsResult
          .map<data_model.Post>((json) => data_model.Post.fromJson(json))
          .toList();

      // Fetch username for the profile
      String? username;
      try {
        final profileResult =
            await profileService.getUserProfile(widget.userId);
        if (profileResult['success'] == true && profileResult['data'] != null) {
          final profile = ProfileModel.fromJson(profileResult['data']);
          username = profile.username;
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

      // Patch username if missing and copyWith is available
      final postsWithUsername = posts.map((post) {
        if ((post.username == null || post.username!.isEmpty) &&
            username != null) {
          return post.copyWith(username: username);
        }
        return post;
      }).toList();

      setState(() {
        _posts = postsWithUsername;
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
          userDataString != null ? jsonDecode(userDataString) : {'id': null};
      currentUserId = userData['id'];
    }
    if (currentUserId == null) return;

    setState(() {
      if (post.likedByMe) {
        post.likedByMe = false;
        post.likes--;
      } else {
        post.likedByMe = true;
        post.likes++;
      }
    });

    final result = await _songPostService.likePost(post.id, currentUserId);
    if (!(result['success'] == true)) {
      setState(() {
        if (post.likedByMe) {
          post.likedByMe = false;
          post.likes--;
        } else {
          post.likedByMe = true;
          post.likes++;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to like post')),
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
                : {'id': null, 'name': 'Anonymous'};
            final result = await _songPostService.addComment(
                post.id, userData['id'], userData['name'], text);
            if (result['success']) {
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
                    content:
                        Text(result['message'] ?? 'Failed to add comment')),
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
      final authService = Provider.of<dynamic>(context, listen: false);
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
      // ignore errors for now
    }
  }

  Future<void> _pausePlayback() async {
    try {
      final authService = Provider.of<dynamic>(context, listen: false);
      final dio = authService.dio;
      final response = await dio.put('/spotify/player/post/pause');
      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _isPlaying = false;
        });
      }
    } catch (e) {
      // ignore
    }
  }

  void _handleShare(data_model.Post post) {
    final shareText =
        'Check out this song: ${post.songName} by ${post.artists}';
    Share.share(shareText, subject: 'Music from Noot');
  }

  void _handlePostOptions(data_model.Post post) {
    print('ProfileFeedScreen _handlePostOptions - Post ID: ${post.id}');
    print(
        'ProfileFeedScreen _handlePostOptions - Post User ID: ${post.userId}');
    print(
        'ProfileFeedScreen _handlePostOptions - Current User ID: $_currentUserId');

    // Check if either ID is null or empty
    if (post.userId == null || post.userId!.isEmpty) {
      print('WARNING: Post userId is null or empty');
    }
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      print('WARNING: Current userId is null or empty');
    }

    bool isUsersOwnPost = false;
    if (post.userId != null && _currentUserId != null) {
      isUsersOwnPost = post.userId == _currentUserId;
      print('Calculated isUsersOwnPost: $isUsersOwnPost');
    } else {
      print('Cannot determine if post is user\'s own due to null IDs');
    }

    PostOptionsMenu.show(
      context,
      postUserId: post.userId,
      currentUserId: _currentUserId,
      postId: post.id,
      isOwnPost: isUsersOwnPost,
      onCopyLink: () {
        final shareText =
            'Check out this song: ${post.songName} by ${post.artists}';
        Share.share(shareText, subject: 'Music from Noot');
      },
      onSavePost: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post saved')),
        );
      },
      onUnfollow: () {
        // Implement unfollow user functionality
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unfollowed ${post.username ?? "user"}')),
        );
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
                // Refresh the feed after successful edit
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
            backgroundColor: Colors.black,
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
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
            actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
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
                  foregroundColor: Colors.white,
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
                    content: Text('Post deleted successfully'),
                    backgroundColor: Colors.purple),
              );
              // Refresh posts after deletion
              _loadProfilePosts();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text(result['message'] ?? 'Failed to delete post')),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error deleting post: $e')),
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
                  content: Text('Post hidden from your feed'),
                  backgroundColor: Colors.purple),
            );
            _loadProfilePosts(); // Refresh posts
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
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
            child: Text(_error!, style: const TextStyle(color: Colors.white))),
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
      appBar: NootAppBar(),
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
        onUserTap: (String userId) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfilePage(userId: userId),
            ),
          );
        },
        itemScrollController: _itemScrollController,
        itemPositionsListener: _itemPositionsListener,
        initialIndex: _initialIndex,
      ),
      bottomNavigationBar: const BottomBar(),
      backgroundColor: Colors.black,
    );
  }
}
