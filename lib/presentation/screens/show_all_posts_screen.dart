import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/services/song_post_service.dart';
import '../../data/models/post_model.dart';
import '../../core/constants/app_constants.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; 
import '../widgets/song_post/comment.dart';
import 'package:provider/provider.dart';
import '../../data/services/auth_service.dart';


class ShowAllPostsScreen extends StatefulWidget {
  const ShowAllPostsScreen({Key? key}) : super(key: key);

  @override
  State<ShowAllPostsScreen> createState() => _ShowAllPostsScreenState();
}

class _ShowAllPostsScreenState extends State<ShowAllPostsScreen> {
  final SongPostService _songPostService = SongPostService();
  
  List<Post> _posts = [];
  bool _isLoading = true;
  String? _error;
  String? _currentlyPlayingTrackId;
  bool _isPlaying = false;
  String? userId;

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
        : {'_id': '685fb750cc084ba7e0ef8533'};
    setState(() {
      userId = userData['_id'];
    });
    await _loadPosts();
  }

  // Load posts from the backend
  Future<void> _loadPosts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final result = await _songPostService.getAllPosts();
      
      if (result['success']) {
        final List<dynamic> postsData = result['data'];
        final posts = postsData.map((json) {
          final post = Post.fromJson(json);
          post.likedByMe = (json['likedBy'] as List<dynamic>?)?.contains(userId) ?? false;
          return post;
        }).toList();
        
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading posts: $e';
        _isLoading = false;
      });
    }
  }

//main screen layout
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF667eea),
      appBar: AppBar(
        title: const Text('Music Feed', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadPosts,
          ),
        ],
      ),
      body: _buildContent(),
    );
  }


//what to show on the screen
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
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPosts,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, color: Colors.white, size: 48),
            SizedBox(height: 16),
            Text('No posts yet', style: TextStyle(color: Colors.white, fontSize: 18)),
            Text('Be the first to share your favorite music!', 
                 style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          return _buildPostCard(_posts[index]);
        },
      ),
    );
  }


//how each post looks
  Widget _buildPostCard(Post post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header
          ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF667eea),
              child: const Icon(Icons.person, color: Colors.white),
            ),
            title: Text(post.username, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${post.songName} • ${post.artists}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_currentlyPlayingTrackId == post.trackId && _isPlaying)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Playing', style: TextStyle(color: Colors.green, fontSize: 10)),
                  ),
                const SizedBox(width: 8),
                Text(_formatTimestamp(post.createdAt), style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
          
          // Album image
          if (post.albumImage != null && post.albumImage!.isNotEmpty)
            Container(
              width: double.infinity,
              height: 200,
              child: Image.network(
                post.albumImage!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.music_note, size: 64, color: Colors.grey),
                  );
                },
              ),
            ),
          
          // Caption
          if (post.caption != null && post.caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(post.caption!),
            ),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildActionButton(
                  icon: post.likedByMe ? Icons.favorite : Icons.favorite_border,
                  label: '${post.likes}',
                  iconColor: post.likedByMe ? Colors.purple : Colors.grey[600],
                  onTap: () => _handleLike(post),
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: '${post.comments.length}',
                  onTap: () => _handleComment(post),
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  icon: _currentlyPlayingTrackId == post.trackId && _isPlaying
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                  label: _currentlyPlayingTrackId == post.trackId && _isPlaying ? 'Pause' : 'Play',
                  onTap: () => _handlePlay(post),
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  icon: Icons.share,
                  label: '',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: iconColor ?? Colors.grey[600]),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _handleLike(Post post) async {
    String? currentUserId = userId;
    if (currentUserId == null) {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      final userData = userDataString != null
          ? jsonDecode(userDataString)
          : {'_id': '685fb750cc084ba7e0ef8533'};
      currentUserId = userData['_id'];
    }
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ID not found. Please log in again.')),
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

    final result = await _songPostService.likePost(post.id, currentUserId);
    if (!result['success']) {
      
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

  void _handleComment(Post post) {
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
            final userData = userDataString != null ? jsonDecode(userDataString) : {'_id': '685fb750cc084ba7e0ef8533', 'username': 'owl'};
            final result = await _songPostService.addComment(post.id, userData['_id'], userData['username'], text);
            if (result['success']) {
              setState(() {
                post.comments = (result['data']['comments'] as List<dynamic>).map((c) => Comment.fromJson(c)).toList();
              });
              Navigator.of(context).pop();
              _handleComment(post); // reopen to refresh
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Failed to add comment')));
            }
          },
          postId: post.id,
          currentUserId: userId ?? '',
          songPostService: _songPostService,
        ),
      ),
    );
  }

  Future<void> _handlePlay(Post post) async {
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

  Future<void> _playTrack(Post post) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;
      final response = await dio.post(
        '/spotify/player/post/play',
        data: {'track_id': post.trackId},
      );
      if (response.statusCode == 200 || response.statusCode == 202 || response.statusCode == 204) {
        setState(() {
          _currentlyPlayingTrackId = post.trackId;
          _isPlaying = true;
        });
        
      } 
    } catch (e) {
      String errorMsg = 'Failed to play track';
      if (e is DioError && e.response != null && e.response?.data != null) {
        // Try to extract a more specific error message from the backend
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          errorMsg = data['message'];
        } else if (data is String) {
          errorMsg = data;
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
        
      } else {
        // Removed SnackBar
      }
    } catch (e) {
      // Removed SnackBar
    }
  }


  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
} 