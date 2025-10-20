import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/song_post_service.dart';
import '../../../data/models/post_model.dart' as data_model;
import '../../../core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../widgets/song_post/post.dart' as widgets;
import '../../widgets/song_post/post_shape.dart';

class PostDetailsScreen extends StatefulWidget {
  final String postId;

  const PostDetailsScreen({
    Key? key,
    required this.postId,
  }) : super(key: key);

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final SongPostService _songPostService = SongPostService();
  data_model.Post? _post;
  bool _isLoading = true;
  String? _error;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadPost();
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        setState(() {
          _currentUserId = userData['id'];
        });
      }
    } catch (e) {
      print('Error loading current user ID: $e');
    }
  }

  Future<void> _loadPost() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final result = await _songPostService.getPostById(widget.postId);

      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _post = data_model.Post.fromJson(result['data']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to load post';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading post: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Post',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_post == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.post_add,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Post not found',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    // Display the post using the same structure as the feed
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: _buildPostItem(),
      ),
    );
  }

  Widget _buildPostItem() {
    if (_post == null) return const SizedBox.shrink();

    // Define the aspect ratio for consistency (same as feed)
    const postAspectRatio = 490 / 595;

    // Get default color based on theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark
        ? const Color.fromARGB(255, 17, 37, 37)
        : const Color(0xFFF5F5F5);

    // Use stored background color from database, or default if not available
    final backgroundColor = _post!.backgroundColor != null
        ? Color(int.parse(_post!.backgroundColor!.replaceFirst('#', '0xFF')))
        : defaultColor;

    // Check if the post belongs to the current user
    final bool isOwnPost = _post!.userId != null &&
        _currentUserId != null &&
        _post!.userId == _currentUserId;

    return Column(
      children: [
        AspectRatio(
          aspectRatio: postAspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Layer for post_shape widget
              CustomPaint(
                painter: PostShape(backgroundColor: backgroundColor),
                child: Container(),
              ),
              // Layer for post widget
              widgets.Post(
                trackId: _post!.trackId ?? '',
                songName: _post!.songName ?? '',
                artists: _post!.artists ?? '',
                albumImage: _post!.albumImage ?? '',
                caption: _post!.caption ?? '',
                username: _post!.username ?? '',
                userId: _post!.userId,
                currentUserId: _currentUserId,
                postId: _post!.id,
                userImage: _post!.userImage ?? 'assets/images/profile_picture.jpg',
                isOwnPost: isOwnPost,
                onLike: _handleLike,
                onComment: () {
                  // Handle comment functionality
                },
                onPlayPause: () {
                  // Handle play/pause functionality
                },
                onShare: () {
                  // Handle share functionality
                },
                onMoreOptions: null, // Can add options menu if needed
                isLiked: _post!.likedByMe,
                isPlaying: false, // Can be connected to music player state
                isCurrentTrack: false, // Can be connected to music player state
                isSaved: _post!.isSaved,
                onUsernameTap: () {
                  // Handle username tap to navigate to user profile
                  if (_post!.userId != null) {
                    // Navigate to user profile
                  }
                },
                onDelete: isOwnPost ? () {
                  // Handle delete functionality
                } : null,
                onHide: () {
                  // Handle hide functionality
                },
                // likeCount and commentCount intentionally omitted for consistency
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleLike() async {
    try {
      if (_currentUserId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to like posts'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final result = await _songPostService.likePost(_post!.id, _currentUserId!, context);

      if (result['success'] == true) {
        // Update the post likes locally
        setState(() {
          if (_post!.likedBy.contains(_currentUserId)) {
            _post!.likedBy.remove(_currentUserId!);
            _post!.likes = (_post!.likes > 0) ? _post!.likes - 1 : 0;
            _post!.likedByMe = false;
          } else {
            _post!.likedBy.add(_currentUserId!);
            _post!.likes += 1;
            _post!.likedByMe = true;
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to like post'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error liking post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}