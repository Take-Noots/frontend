import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/song_post_service.dart';
import '../../../data/models/post_model.dart';
import '../../../core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
  Post? _post;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPost();
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
          _post = Post.fromJson(result['data']);
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

    // Display the post with a custom layout
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPostHeader(),
            const SizedBox(height: 16),
            _buildPostContent(),
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildPostHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey[300],
          child: Text(
            _post!.username?.substring(0, 1).toUpperCase() ?? 'U',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _post!.username ?? 'Unknown User',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_post!.songName ?? 'Unknown Song'} • ${_post!.artists ?? 'Unknown Artist'}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Album Image
        if (_post!.albumImage != null)
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _post!.albumImage!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.music_note,
                      size: 64,
                      color: Colors.white54,
                    ),
                  );
                },
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Caption
        if (_post!.caption != null && _post!.caption!.isNotEmpty)
          Text(
            _post!.caption!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 16,
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        _buildActionButton(
          icon: Icons.favorite_border,
          label: '${_post!.likes}',
          onTap: _handleLike,
        ),
        const SizedBox(width: 20),
        _buildActionButton(
          icon: Icons.chat_bubble_outline,
          label: '${_post!.comments.length}',
          onTap: () {
            // Handle comment tap
          },
        ),
        const SizedBox(width: 20),
        _buildActionButton(
          icon: Icons.share,
          label: '',
          onTap: () {
            // Handle share tap
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.onPrimary,
            size: 24,
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleLike() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');

      if (userDataString == null) {
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

      final userData = jsonDecode(userDataString);
      final userId = userData['id'];

      final result = await _songPostService.likePost(_post!.id, userId, context);

      if (result['success'] == true) {
        // Update the post likes locally
        setState(() {
          if (_post!.likedBy.contains(userId)) {
            _post!.likedBy.remove(userId);
            _post!.likes = (_post!.likes > 0) ? _post!.likes - 1 : 0;
          } else {
            _post!.likedBy.add(userId);
            _post!.likes += 1;
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