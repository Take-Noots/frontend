import 'package:flutter/material.dart';
import '../../../../widgets/home/feed_widget.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../../../data/models/post_model.dart' as data_model;
import '../../../../../data/models/feed_item.dart';
import '../../../../../data/services/song_post_service.dart';
import '../../../../../data/services/profile_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../../../../widgets/song_post/comment.dart';
import '../../../../widgets/song_post/post_options_menu.dart';
import '../../../song_posts/update.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../user_profiles.dart';

class SavedPostsFeedScreen extends StatefulWidget {
  final String userId;
  final List<String> savedPostIds;
  final String? initialPostId;

  const SavedPostsFeedScreen({
    Key? key,
    required this.userId,
    required this.savedPostIds,
    this.initialPostId,
  }) : super(key: key);

  @override
  State<SavedPostsFeedScreen> createState() => _SavedPostsFeedScreenState();
}

class _SavedPostsFeedScreenState extends State<SavedPostsFeedScreen> {
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
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      final userData = jsonDecode(userDataString);
      _currentUserId = userData['id'];
    }

    await _loadSavedPosts();
  }

  Future<void> _loadSavedPosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      if (widget.savedPostIds.isEmpty) {
        setState(() {
          _posts = [];
          _isLoading = false;
        });
        return;
      }

      final postsResult =
          await _songPostService.getPostsByIds(widget.savedPostIds, context);
      if (postsResult['success'] == true) {
        final posts =
            (postsResult['posts'] as List).map<data_model.Post>((json) {
          final post = data_model.Post.fromJson(json);
          post.likedByMe =
              (json['likedBy'] as List<dynamic>?)?.contains(widget.userId) ??
                  false;
          return post;
        }).toList();

        int initialIndex = 0;
        if (widget.initialPostId != null && widget.initialPostId!.isNotEmpty) {
          initialIndex = posts.indexWhere((p) => p.id == widget.initialPostId);
          if (initialIndex == -1) initialIndex = 0;
        }

        setState(() {
          _posts = posts;
          _initialIndex = initialIndex;
          _isLoading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_itemScrollController.isAttached && _initialIndex > 0) {
            try {
              _itemScrollController.jumpTo(index: _initialIndex);
            } catch (e) {
              // Handle scrolling error silently
            }
          }
        });
      } else {
        setState(() {
          _error = 'Failed to load saved posts';
          _isLoading = false;
        });
      }
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

    final result =
        await _songPostService.likePost(post.id, currentUserId, context);
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
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                post.id, userData['id'], userData['name'], text, context);
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

  Future<void> _handlePostOptions(data_model.Post post) async {
    bool isUsersOwnPost = false;
    if (post.userId != null && _currentUserId != null) {
      isUsersOwnPost = post.userId == _currentUserId;
    }

    // Check if post is saved (should be true for saved posts screen, but check anyway)
    bool isSaved = false;
    if (_currentUserId != null) {
      try {
        final savedResult = await _songPostService.isPostSaved(
            _currentUserId!, post.id, context);
        isSaved = savedResult['isSaved'] ?? false;
      } catch (e) {
        // If we can't check saved status, assume it's saved since we're in saved posts screen
        isSaved = true;
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
          final authService = Provider.of<dynamic>(context, listen: false);
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
        // This should not be called in saved posts screen since posts are already saved
        // But keeping for compatibility - just show a message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post is already saved'),
            backgroundColor: const Color(0xFFA855F7),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 2),
          ),
        );
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
                content: Text('Post removed from saved'),
                backgroundColor: const Color(0xFFA855F7),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(10),
                duration: const Duration(seconds: 2),
              ),
            );
            // Remove from list and refresh
            setState(() {
              _posts.removeWhere((p) => p.id == post.id);
            });
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
        // Report functionality handled inside PostOptionsMenu
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
                _loadSavedPosts();
              }
            }
          : null,
      onDelete: () async {
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
                  backgroundColor: const Color(0xFFA855F7),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(10),
                  duration: const Duration(seconds: 2),
                ),
              );
              _loadSavedPosts();
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
                backgroundColor: const Color(0xFFA855F7),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(10),
                duration: const Duration(seconds: 2),
              ),
            );
            _loadSavedPosts();
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
      final authService = Provider.of<dynamic>(context, listen: false);
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
      final authService = Provider.of<dynamic>(context, listen: false);
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

  Widget _buildSongPostsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
          child: Text(_error!,
              style:
                  TextStyle(color: Theme.of(context).colorScheme.onSurface)));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_itemScrollController.isAttached && _initialIndex > 0) {
        try {
          _itemScrollController.scrollTo(
            index: _initialIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } catch (e) {
          // Handle scrolling error silently
        }
      }
    });

    return _posts.isEmpty
        ? Center(
            child: Text(
              'No saved posts',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          )
        : FeedWidget(
            feedItems: _posts.map((p) => FeedItem.song(p)).toList(),
            isLoading: false,
            error: null,
            onRefresh: _loadSavedPosts,
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
          );
  }

  Widget _buildThoughtsTab() {
    return const Center(child: Text('Saved thought posts — coming soon'));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Saved Posts'),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: Theme.of(context).colorScheme.onSurface),
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: TabBar(
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.onSurface,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurfaceVariant,
            tabs: const [Tab(text: 'Song Posts'), Tab(text: 'Thought Posts')],
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: TabBarView(
          children: [
            _buildSongPostsTab(),
            _buildThoughtsTab(),
          ],
        ),
      ),
    );
  }
}
