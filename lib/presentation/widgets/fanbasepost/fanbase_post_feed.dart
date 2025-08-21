import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../../data/services/fanbase_post_service.dart';
import '../../../data/models/fanbase_post_model.dart';
import '../../screens/fanbasePost/fanbasePost_screen.dart';
import 'widgets/fanbase_post_content_widget.dart';
import './widgets/fanbase_post_bg_container.dart';

class FanbasePostFeedWidget extends StatefulWidget {
  final String fanbaseId;

  const FanbasePostFeedWidget({
    Key? key,
    required this.fanbaseId,
  }) : super(key: key);

  @override
  State<FanbasePostFeedWidget> createState() => _FanbasePostFeedWidgetState();
}

class _FanbasePostFeedWidgetState extends State<FanbasePostFeedWidget> {
  List<FanbasePost> _posts = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentPage = 1;
  bool _hasMorePosts = true;
  bool _isLoadingMore = false;

  final ScrollController _scrollController = ScrollController();
  final Map<String, Color> _extractedColors = {};
  final Color _defaultColor = const Color.fromARGB(255, 17, 37, 37);

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMorePosts) {
        _loadMorePosts();
      }
    }
  }

  Future<void> _loadPosts() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final posts = await FanbasePostService.getFanbasePosts(
        widget.fanbaseId,
        context,
        page: 1,
        limit: 10,
      );

      // Add debug logging here
      print('=== FanbasePostFeed Debug ===');
      print('Loaded ${posts.length} posts');
      for (var i = 0; i < posts.length; i++) {
        final post = posts[i];
        print('Post $i:');
        print('  ID: ${post.id}');
        print('  Topic: ${post.topic}');
        print('  Comments count: ${post.commentsCount}');
        print('  Comments array length: ${post.comments.length}');
        print('  Comments: ${post.comments.map((c) => c.comment).toList()}');
      }

      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
          _currentPage = 1;
          _hasMorePosts = posts.length >= 10;
        });

        // Extract colors for album images
        _extractColorsFromAlbumImages();
      }
    } catch (e) {
      print('Error loading posts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMorePosts) return;

    try {
      setState(() {
        _isLoadingMore = true;
      });

      final newPosts = await FanbasePostService.getFanbasePosts(
        widget.fanbaseId,
        context,
        page: _currentPage + 1,
        limit: 10,
      );

      if (mounted) {
        setState(() {
          _posts.addAll(newPosts);
          _currentPage++;
          _hasMorePosts = newPosts.length >= 10;
          _isLoadingMore = false;
        });

        // Extract colors for new album images
        _extractColorsFromAlbumImages();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more posts: $e')),
        );
      }
    }
  }

  Future<void> _refreshPosts() async {
    await _loadPosts();
  }

  Future<void> _extractColorsFromAlbumImages() async {
    for (final post in _posts) {
      if (post.albumArt != null && post.albumArt!.isNotEmpty) {
        final albumImageUrl = post.albumArt!;
        if (!_extractedColors.containsKey(albumImageUrl)) {
          try {
            final PaletteGenerator paletteGenerator =
                await PaletteGenerator.fromImageProvider(
              NetworkImage(albumImageUrl),
              size: const Size(100, 100),
              maximumColorCount: 10,
            );

            Color? extractedColor = paletteGenerator.darkMutedColor?.color ??
                paletteGenerator.darkVibrantColor?.color ??
                paletteGenerator.dominantColor?.color;

            if (extractedColor != null) {
              setState(() {
                _extractedColors[albumImageUrl] = _isDarkEnough(extractedColor)
                    ? extractedColor
                    : _darkenColor(extractedColor);
              });
            } else {
              setState(() {
                _extractedColors[albumImageUrl] = _defaultColor;
              });
            }
          } catch (e) {
            print('Error extracting color: $e');
            setState(() {
              _extractedColors[albumImageUrl] = _defaultColor;
            });
          }
        }
      }
    }
  }

  bool _isDarkEnough(Color color) {
    double luminance =
        (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return luminance < 0.4;
  }

  Color _darkenColor(Color color) {
    const double factor = 0.6;
    return Color.fromARGB(
      color.alpha,
      (color.red * factor).round(),
      (color.green * factor).round(),
      (color.blue * factor).round(),
    );
  }

  Future<void> _handleLike(FanbasePost post) async {
    // Optimistic update - update UI immediately
    final originalPost = post;
    final optimisticPost = FanbasePost(
      id: post.id,
      createdBy: post.createdBy,
      topic: post.topic,
      description: post.description,
      spotifyTrackId: post.spotifyTrackId,
      songName: post.songName,
      artistName: post.artistName,
      albumArt: post.albumArt,
      likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
      likeUserIds: post.likeUserIds,
      commentsCount: post.commentsCount,
      comments: post.comments,
      fanbaseId: post.fanbaseId,
      createdAt: post.createdAt,
      updatedAt: post.updatedAt,
      isLiked: !post.isLiked,
    );

    // Update UI optimistically
    setState(() {
      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        _posts[index] = optimisticPost;
      }
    });

    try {
      final updatedPost = await FanbasePostService.likeFanbasePost(
        post.id,
        context,
        fanbaseId: widget.fanbaseId,
      );

      // Update with actual response from server
      setState(() {
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          _posts[index] = updatedPost;
        }
      });
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          _posts[index] = originalPost;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error liking post: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleComment(FanbasePost post) async {
    // Navigate to post detail page
    final albumImageUrl = post.albumArt ?? '';
    final backgroundColor = _extractedColors[albumImageUrl] ?? _defaultColor;

    // Add debug logging here
    print('=== _handleComment Debug ===');
    print('Post ID: ${post.id}');
    print('Post comments count: ${post.commentsCount}');
    print('Post comments array length: ${post.comments.length}');
    print('Raw comments: ${post.comments}');

    final commentsToPass = post.comments
        .map((comment) => {
              'username': comment.userName,
              'text': comment.comment,
              'userId': comment.userId,
              'likeCount': comment.likeCount.toString(),
              'createdAt': comment.createdAt.toIso8601String(),
            })
        .toList();

    print('Converted comments: $commentsToPass');

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PostDetailPage(
          postId: post.id,
          trackId: post.spotifyTrackId ?? '',
          songName: post.songName ?? '',
          artists: post.artistName ?? '',
          albumImage: post.albumArt ?? '',
          comments: commentsToPass,
          username: post.createdBy['userName'] ?? 'Unknown User',
          userImage: 'assets/images/profile_picture.jpg',
          title: post.topic,
          description: post.description,
          isLiked: post.isLiked,
          isPlaying: false,
          isCurrentTrack: false,
          backgroundColor: backgroundColor,
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
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading posts',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPosts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.post_add,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to create a post in this fanbase!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshPosts,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: _posts.length + (_hasMorePosts ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _posts.length) {
                // Loading indicator for more posts
                return _isLoadingMore
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : const SizedBox.shrink();
              }

              final post = _posts[index];
              return _buildPostItem(post);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPostItem(FanbasePost post) {
    final albumImageUrl = post.albumArt ?? '';
    final backgroundColor = _extractedColors[albumImageUrl] ?? _defaultColor;
    const double postAspectRatio = 490 / 223;

    // Convert comments to the format expected by PostDetailPage
    final commentsForPost = post.comments
        .map((comment) => {
              'username': comment.userName,
              'text': comment.comment,
              'userId': comment.userId,
              'likeCount': comment.likeCount.toString(),
              'createdAt': comment.createdAt.toIso8601String(),
            })
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
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
                Post(
                  trackId: post.spotifyTrackId ?? '',
                  postId: post.id,
                  songName: post.songName ?? '',
                  artists: post.artistName ?? '',
                  albumImage: post.albumArt ?? '',
                  caption: '',
                  username: post.createdBy['userName'] ?? 'Unknown User',
                  userImage: 'assets/images/profile_picture.jpg',
                  descriptionTitle: post.topic,
                  description: post.description,
                  comments: commentsForPost, // Add this line
                  onLike: () => _handleLikeById(post.id),
                  onComment: () => _handleCommentById(post.id),
                  isLiked: post.isLiked,
                  isPlaying: false,
                  backgroundColor: backgroundColor,
                  likesCount: post.likesCount,
                  commentsCount: post.commentsCount,
                  fanbaseId: widget.fanbaseId,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // New methods that find the post by ID
  Future<void> _handleLikeById(String postId) async {
    final post = _posts.firstWhere((p) => p.id == postId);
    print('=== _handleLikeById Debug ===');
    print('Found post ${post.id} with ${post.comments.length} comments');
    await _handleLike(post);
  }

  Future<void> _handleCommentById(String postId) async {
    final post = _posts.firstWhere((p) => p.id == postId);
    print('=== _handleCommentById Debug ===');
    print('Found post ${post.id} with ${post.comments.length} comments');
    await _handleComment(post);
  }
}
