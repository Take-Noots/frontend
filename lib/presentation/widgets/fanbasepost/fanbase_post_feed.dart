import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../../data/models/fanbase_post_model.dart';
import 'widgets/fanbase_post_content_widget.dart';
import './widgets/fanbase_post_bg_container.dart';

class FanbasePostFeedWidget extends StatefulWidget {
  final String fanbaseId;
  final List<FanbasePost> posts;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRefresh;
  final Function(FanbasePost)? onLike;
  final Function(FanbasePost)? onComment;
  final Function(FanbasePost)? onPlay;
  final Function(FanbasePost)? onShare;
  final Function(FanbasePost)? onPostOptions; // Add this parameter
  final String? currentlyPlayingTrackId;
  final bool isPlaying;
  final void Function(String userId)? onUserTap;
  final String? currentUserId;

  const FanbasePostFeedWidget({
    Key? key,
    required this.fanbaseId,
    required this.posts,
    this.isLoading = false,
    this.error,
    this.onRefresh,
    this.onLike,
    this.onComment,
    this.onPlay,
    this.onShare,
    this.onPostOptions, // Add this parameter
    this.currentlyPlayingTrackId,
    this.isPlaying = false,
    this.onUserTap,
    this.currentUserId,
  }) : super(key: key);

  @override
  State<FanbasePostFeedWidget> createState() => _FanbasePostFeedWidgetState();
}

class _FanbasePostFeedWidgetState extends State<FanbasePostFeedWidget> {
  final Map<String, Color> _extractedColors = {};
  final Color _defaultColor = const Color.fromARGB(255, 17, 37, 37);

  @override
  void initState() {
    super.initState();
    _extractColorsFromAlbumImages();
  }

  @override
  void didUpdateWidget(FanbasePostFeedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Extract colors when posts change
    if (oldWidget.posts != widget.posts) {
      _extractColorsFromAlbumImages();
    }
  }

  Future<void> _extractColorsFromAlbumImages() async {
    for (final post in widget.posts) {
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

            if (extractedColor != null && mounted) {
              setState(() {
                _extractedColors[albumImageUrl] = _isDarkEnough(extractedColor)
                    ? extractedColor
                    : _darkenColor(extractedColor);
              });
            } else if (mounted) {
              setState(() {
                _extractedColors[albumImageUrl] = _defaultColor;
              });
            }
          } catch (e) {
            print('Error extracting color: $e');
            if (mounted) {
              setState(() {
                _extractedColors[albumImageUrl] = _defaultColor;
              });
            }
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

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.error != null && widget.posts.isEmpty) {
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
              widget.error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: widget.onRefresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (widget.posts.isEmpty) {
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
      onRefresh: () async {
        if (widget.onRefresh != null) widget.onRefresh!();
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: widget.posts.length,
            itemBuilder: (context, index) {
              final post = widget.posts[index];
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
    const double postAspectRatio = 490 / 250;

    // responsive outer margins
    final screenW = MediaQuery.of(context).size.width;
    final horizontalMargin = (screenW * 0.04).clamp(8.0, 32.0);
    final topSpacerHeight =
        (((screenW) * 0.10) / postAspectRatio).clamp(35.0, 120.0);

    // Compute a responsive margin for PostShape (kept clamped)
    final double painterMargin = (screenW * 0.04).clamp(6.0, 40.0);

    // Check if the post belongs to the current user - same logic as feed_widget
    final bool isOwnPost = post.createdBy['userId'] != null &&
        widget.currentUserId != null &&
        post.createdBy['userId'] == widget.currentUserId;

    print(
        'FanbasePostFeed - Building post from user: ${post.createdBy['userName']}');
    print('FanbasePostFeed - Post userId: ${post.createdBy['userId']}');
    print('FanbasePostFeed - Current userId: ${widget.currentUserId}');
    print('FanbasePostFeed - isOwnPost: $isOwnPost');

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
      margin:
          EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: 12.0),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: postAspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Column(
                  children: [
                    SizedBox(
                      height: topSpacerHeight,
                    ),
                    Expanded(
                      child: CustomPaint(
                        painter: PostShape(
                          backgroundColor: backgroundColor,
                          margin: painterMargin,
                        ),
                        child: Container(),
                      ),
                    ),
                  ],
                ),
                // Layer for post widget (unchanged)
                Post(
                  trackId: post.spotifyTrackId ?? '',
                  postId: post.id,
                  songName: post.songName ?? '',
                  artists: post.artistName ?? '',
                  albumImage: post.albumArt ?? '',
                  caption: post.description, // Use description as caption
                  username: post.createdBy['userName'] ?? 'Unknown User',
                  userId: post.createdBy['userId'], // Pass the actual userId
                  currentUserId: widget.currentUserId, // Pass currentUserId
                  userImage: 'assets/images/profile_picture.jpg',
                  descriptionTitle: post.topic,
                  description: post.description,
                  comments: commentsForPost,
                  isOwnPost: isOwnPost, // Pass isOwnPost calculation
                  onLike: () {
                    if (widget.onLike != null) {
                      widget.onLike!(post);
                    }
                  },
                  onComment: () {
                    if (widget.onComment != null) {
                      widget.onComment!(post);
                    }
                  },
                  onPlayPause: () {
                    if (widget.onPlay != null) {
                      widget.onPlay!(post);
                    }
                  },
                  onShare: () {
                    if (widget.onShare != null) {
                      widget.onShare!(post);
                    }
                  },
                  onMoreOptions: () {
                    // This is the key part - same as feed_widget
                    if (widget.onPostOptions != null) {
                      widget.onPostOptions!(post);
                    }
                  },
                  onUsernameTap: () {
                    if (widget.onUserTap != null &&
                        post.createdBy['userId'] != null) {
                      widget.onUserTap!(post.createdBy['userId']!);
                    }
                  },
                  isLiked: post.isLiked,
                  isPlaying:
                      widget.currentlyPlayingTrackId == post.spotifyTrackId &&
                          widget.isPlaying,
                  isCurrentTrack:
                      widget.currentlyPlayingTrackId == post.spotifyTrackId,
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
}
