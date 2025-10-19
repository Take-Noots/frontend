import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../data/services/fanbase_post_service.dart';
import 'fanbasePost_screen_comments.dart';
import 'fanbasePost_screen_songControl.dart'; // Add this import

/// PostDetailPage displays a single fanbase post with its comments
/// Users can add comments and reply to existing comments
class PostDetailPage extends StatefulWidget {
  // Post identification
  final String postId;
  final String fanbaseId;

  // Song/Track information
  final String trackId;
  final String songName;
  final String artists;
  final String albumImage;
  final Color backgroundColor;

  // Post content
  final String title;
  final String description;
  final String username;
  final String userImage;

  // Post state
  final bool isLiked;
  final bool isPlaying;
  final bool isCurrentTrack;
  final int likesCount;
  final int commentsCount;

  // Comments data - stored as Map for flexibility with old data
  final List<Map<String, dynamic>> comments;

  const PostDetailPage({
    super.key,
    required this.postId,
    required this.trackId,
    required this.songName,
    required this.artists,
    required this.albumImage,
    required this.comments,
    required this.username,
    required this.userImage,
    required this.title,
    required this.description,
    required this.isLiked,
    required this.isPlaying,
    required this.isCurrentTrack,
    required this.backgroundColor,
    required this.fanbaseId,
    this.likesCount = 0,
    this.commentsCount = 0,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  bool _hasAddedComment = false;
  List<Map<String, dynamic>> _comments = [];
  final GlobalKey<FanbasePostCommentsSectionState> _commentsSectionKey =
      GlobalKey<FanbasePostCommentsSectionState>();

  @override
  void initState() {
    super.initState();
    _comments = List.from(widget.comments);
    // Trigger a rebuild after the first frame to ensure the key is attached
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  /// Refreshes the page by fetching updated post data
  Future<void> _refreshPost() async {
    try {
      final updatedPost = await FanbasePostService.getFanbasePost(
        widget.postId,
        context,
        fanbaseId: widget.fanbaseId, // ✅ Add this parameter
      );

      if (mounted) {
        setState(() {
          _comments = _mapCommentsToDisplay(updatedPost.comments);
          _hasAddedComment = true;
        });
      }
    } catch (e) {
      print('Error refreshing post: $e');
    }
  }

  /// Converts FanbasePostComment objects to Map format for display
  List<Map<String, dynamic>> _mapCommentsToDisplay(List comments) {
    return comments.map((comment) {
      return {
        'username': comment.userName ?? 'Unknown User',
        'text': comment.comment ?? '',
        'userId': comment.userId ?? '',
        'commentId': comment.commentId ?? '',
        'likeCount': (comment.likeCount ?? 0).toString(),
        'isLiked': comment.isLiked ?? false,
        'createdAt': comment.createdAt?.toIso8601String() ??
            DateTime.now().toIso8601String(),
        'subComments': (comment.subComments ?? []).map((subComment) {
          return {
            'username': subComment.userName ?? 'Unknown User',
            'text': subComment.comment ?? '',
            'userId': subComment.userId ?? '',
            'commentId': subComment.commentId ?? '',
            'likeCount': (subComment.likeCount ?? 0).toString(),
            'isLiked': subComment.isLiked ?? false,
            'createdAt': subComment.createdAt?.toIso8601String() ??
                DateTime.now().toIso8601String(),
          };
        }).toList(),
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Get the bottom padding to account for navigation bar
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Stack(
        children: [
          // Main scrollable content
          SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 10,
              right: 10,
              top: 16,
              bottom:
                  bottomPadding, // Add enough padding for input bar + nav bar
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 10),
                _buildSongCard(),
                const SizedBox(height: 20),
                _buildPostContent(),
                const SizedBox(height: 20),
                // Refactored comments section
                FanbasePostCommentsSection(
                  key: _commentsSectionKey,
                  postId: widget.postId,
                  fanbaseId: widget.fanbaseId,
                  comments: _comments,
                  onCommentAdded: _refreshPost,
                ),
              ],
            ),
          ),
          _buildFloatingInputBar(),
        ],
      ),
    );
  }

  // Create a separate method for the floating input bar
  Widget _buildFloatingInputBar() {
    // Check if the key's current state is available
    final state = _commentsSectionKey.currentState;
    if (state != null) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: state.buildCommentInputBar(),
      );
    }
    // Return an empty widget
    return const SizedBox.shrink();
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: () => Navigator.pop(context, _hasAddedComment),
        ),
        Text(
          "Post",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildSongCard() {
    // If there's no track id (no song), don't display the card
    if (widget.trackId.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ClipRRect(
            child: Image.network(
              widget.albumImage,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/images/song.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.songName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.artists,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Use the new CompactSongControlWidget
          CompactSongControlWidget(
            trackId: widget.trackId,
            isPlaying: widget.isPlaying,
            isCurrentTrack: widget.isCurrentTrack,
            onPlayPause: () {
              // TODO: Implement play/pause functionality
              print('Play/Pause pressed for track: ${widget.trackId}');
            },
            onSpotifyTap: () {
              // TODO: Implement Spotify link functionality
              print('Spotify icon pressed for track: ${widget.trackId}');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPostContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.description,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade500,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
