import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../song_post/post.dart';
import '../song_post/post_shape.dart';
import '../../../data/models/post_model.dart' as data_model;

/// A feed widget that displays song posts
import '../../../data/models/feed_item.dart';
import '../../../data/models/thoughts_model.dart';
import '../thoughts/thoughts_feed_card.dart';

class FeedWidget extends StatefulWidget {
  final List<FeedItem>? feedItems;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRefresh;
  final Function(data_model.Post)? onLike;
  final Function(data_model.Post)? onComment;
  final Function(data_model.Post)? onPlay;
  final Function(data_model.Post)? onShare;
  final Function(data_model.Post)? onPostOptions;
  final String? currentlyPlayingTrackId;
  final bool isPlaying;
  final void Function(String userId)? onUserTap;

  final String? currentUserId;
  final Future<void> Function(data_model.Post post)? onHidePost;

  final bool shrinkWrap;
  final ScrollPhysics? physics;

  final int initialIndex;
  final ItemScrollController? itemScrollController;
  final ItemPositionsListener? itemPositionsListener;
  final Function(data_model.Post)? onSongLike;
  final Function(data_model.Post)? onSongComment;
  final Function(data_model.Post)? onSongPlay;
  final Function(ThoughtsPost)? onThoughtLike;
  final Function(ThoughtsPost)? onThoughtComment;
  final Function(ThoughtsPost)? onThoughtPlay;
  final Function(data_model.Post)? onSongShare;

  const FeedWidget({
    Key? key,
    this.feedItems,
    this.isLoading = false,
    this.error,
    this.onRefresh,
    this.onLike,
    this.onComment,
    this.onPlay,
    this.onShare,
    this.onPostOptions,
    this.currentlyPlayingTrackId,
    this.isPlaying = false,
    this.onUserTap,
    this.currentUserId,
    this.onHidePost,
    this.shrinkWrap = false,
    this.physics,
    this.initialIndex = 0,
    this.itemScrollController,
    this.itemPositionsListener,
    this.onSongLike,
    this.onSongComment,
    this.onSongPlay,
    this.onSongShare,
    this.onThoughtLike,
    this.onThoughtComment,
    this.onThoughtPlay,
  }) : super(key: key);

  @override
  State<FeedWidget> createState() => _FeedWidgetState();
}

class _FeedWidgetState extends State<FeedWidget> {
  Color get _defaultColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? const Color.fromARGB(255, 17, 37, 37)
        : const Color(0xFFF5F5F5);
  }

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  bool _hasJumped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpToInitialIndex();
    });
  }

  void _jumpToInitialIndex() {
    if (widget.initialIndex > 0 &&
        widget.feedItems != null &&
        widget.feedItems!.isNotEmpty &&
        _itemScrollController.isAttached) {
      _itemScrollController.jumpTo(index: widget.initialIndex);
    }
  }

  @override
  void didUpdateWidget(FeedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feedItems != widget.feedItems) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _jumpToInitialIndex();
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF8E08EF),
        ),
      );
    }

    if (widget.error != null) {
      print('FeedWidget error: ${widget.error}');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              widget.error!,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: widget.onRefresh,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (widget.feedItems == null || widget.feedItems!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, color: Colors.white, size: 48),
            SizedBox(height: 16),
            Text('No posts yet', style: TextStyle(fontSize: 18)),
            Text('Be the first to share your favorite music or thoughts!'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (widget.onRefresh != null) {
          widget.onRefresh!();
        }
      },
      child: ScrollablePositionedList.builder(
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics,
        itemScrollController: widget.itemScrollController,
        itemPositionsListener: widget.itemPositionsListener,
        itemCount: widget.feedItems!.length,
        itemBuilder: (context, index) {
          final item = widget.feedItems![index];
          return _buildFeedItem(item);
        },
      ),
    );
  }

  Widget _buildFeedItem(FeedItem item) {
    print('Building FeedItem of type: ' +
        item.type.toString() +
        ', data: ' +
        item.toString());
    if (item.type == FeedItemType.song && item.songPost != null) {
      return _buildSongPostItem(item.songPost!);
    } else if (item.type == FeedItemType.thought && item.thoughtsPost != null) {
      // Create a unique identifier for thoughts posts using song name and artist name
      final thoughtsPost = item.thoughtsPost!;
      final thoughtsTrackId = thoughtsPost.songName != null && thoughtsPost.artistName != null
          ? '${thoughtsPost.songName}_${thoughtsPost.artistName}'
          : null;
      
      return ThoughtsFeedCard(
        post: thoughtsPost,
        onLike: widget.onThoughtLike != null
            ? () => widget.onThoughtLike!(thoughtsPost)
            : null,
        onComment: widget.onThoughtComment != null
            ? () => widget.onThoughtComment!(thoughtsPost)
            : null,
        onPlayPause: widget.onThoughtPlay != null
            ? () => widget.onThoughtPlay!(thoughtsPost)
            : null,
        isPlaying: widget.isPlaying && widget.currentlyPlayingTrackId == thoughtsTrackId,
        isCurrentTrack: widget.currentlyPlayingTrackId == thoughtsTrackId,
        onUserTap: widget.onUserTap,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSongPostItem(data_model.Post post) {
    // Define the aspect ratio for consistency
    const postAspectRatio = 490 / 595;

    // Use stored background color from database, or default if not available
    final backgroundColor = post.backgroundColor != null 
        ? Color(int.parse(post.backgroundColor!.replaceFirst('#', '0xFF')))
        : _defaultColor;

    // Check if the post belongs to the current user
    final bool isOwnPost = post.userId != null &&
        widget.currentUserId != null &&
        post.userId == widget.currentUserId;
    /*print(
        '[DEBUG] FeedWidget._buildSongPostItem: post.userId=${post.userId}, currentUserId=${widget.currentUserId}, isOwnPost=$isOwnPost');
    print(
        '[DEBUG] FeedWidget._buildSongPostItem: post.userId=${post.userId}, currentUserId=${widget.currentUserId}, isOwnPost=$isOwnPost');

    print(
        'FeedWidget - Building post from user: ${post.username}, userId: ${post.userId}');
    print('FeedWidget - Current userId: ${widget.currentUserId}');
    print('FeedWidget - isOwnPost: $isOwnPost');*/

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
                  trackId: post.trackId ?? '',
                  songName: post.songName ?? '',
                  artists: post.artists ?? '',
                  albumImage: post.albumImage ?? '',
                  caption: post.caption ?? '',
                  username: post.username ?? '',
                  userId: post.userId,
                  currentUserId: widget.currentUserId,
                  postId: post.id,
                  userImage:
                      post.userImage ?? 'assets/images/profile_picture.jpg',
                  isOwnPost: isOwnPost,
                  onLike: () {
                    if (widget.onSongLike != null) {
                      widget.onSongLike!(post);
                    }
                  },
                  onComment: () {
                    if (widget.onSongComment != null) {
                      widget.onSongComment!(post);
                    }
                  },
                  onPlayPause: () {
                    if (widget.onSongPlay != null) {
                      widget.onSongPlay!(post);
                    }
                  },
                  onShare: () {
                    if (widget.onShare != null) {
                      widget.onShare!(post);
                    }
                  },
                  onMoreOptions: widget.onPostOptions != null
                      ? () => widget.onPostOptions!(post)
                      : null,
                  isLiked: post.likedByMe,
                  isPlaying: widget.isPlaying,
                  isCurrentTrack:
                      widget.currentlyPlayingTrackId == post.trackId,
                  isSaved: post.isSaved,
                  onUsernameTap: () {
                    if (widget.onUserTap != null && post.userId != null) {
                      widget.onUserTap!(post.userId!);
                    }
                  },
                  onDelete: isOwnPost && widget.onPostOptions != null
                      ? () => widget.onPostOptions!(post)
                      : null,
                  onHide: widget.onHidePost != null
                      ? () async {
                          print(
                              '[DEBUG] FeedWidget: onHide called from HeaderWidget');
                          print(
                              '[DEBUG] FeedWidget: onHide callback triggered for post ID: ${post.id}');
                          await widget.onHidePost!(post);
                          if (mounted) {
                            setState(() {});
                          }
                        }
                      : null,
                  // likeCount and commentCount intentionally omitted for home/feed
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Only show the caption row if post.caption is not empty
          if ((post.caption ?? '').trim().isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: AutoSizeText.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: post.username ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          TextSpan(
                            text: ' : ${post.caption ?? ''}',
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
