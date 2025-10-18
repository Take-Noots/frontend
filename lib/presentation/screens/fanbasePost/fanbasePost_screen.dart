import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui'; // For BackdropFilter (blur effect)
import '../../../data/services/fanbase_post_service.dart';

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
  // ==================== CONTROLLERS & STATE ====================

  // Text controllers for input fields
  late final TextEditingController _commentController; // Main comment input
  late final TextEditingController _subCommentController; // Reply input

  // Focus nodes to manage keyboard and input focus
  late final FocusNode _commentFocusNode;
  late final FocusNode _subCommentFocusNode;

  // Local state
  List<Map<String, dynamic>> _comments = []; // Mutable copy of comments
  bool _isSubmittingComment = false; // Loading state for main comment
  bool _isSubmittingSubComment = false; // Loading state for reply
  bool _hasAddedComment = false; // Track if user added any comment

  // CRITICAL: Tracks which comment is being replied to (using array index)
  // null = no reply active, "0" = replying to first comment, "1" = second, etc.
  String? _replyToCommentId; // ✅ Changed from _replyToCommentIndex

  // ==================== LIFECYCLE METHODS ====================

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    // Create mutable copy of comments from widget
    _comments = List.from(widget.comments);
    _debugPrintComments();
  }

  void _initializeControllers() {
    _commentController = TextEditingController();
    _subCommentController = TextEditingController();
    _commentFocusNode = FocusNode();
    _subCommentFocusNode = FocusNode();
  }

  void _debugPrintComments() {
    print('=== PostDetailPage Debug ===');
    print('Total comments received: ${widget.comments.length}');
    print('Comments count from widget: ${widget.commentsCount}');
    print('Comments data: ${widget.comments}');
    print('_comments after init: ${_comments.length}');
  }

  @override
  void dispose() {
    // Clean up controllers to prevent memory leaks
    _commentController.dispose();
    _subCommentController.dispose();
    _commentFocusNode.dispose();
    _subCommentFocusNode.dispose();
    super.dispose();
  }

  // ==================== COMMENT SUBMISSION ====================

  /// Submits a new top-level comment to the post
  Future<void> _submitComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    setState(() => _isSubmittingComment = true);

    try {
      // Call backend API to add comment
      final updatedPost = await FanbasePostService.addComment(
        widget.postId,
        commentText,
        context,
        fanbaseId: widget.fanbaseId,
      );

      if (mounted) {
        _commentController.clear();
        _commentFocusNode.unfocus();
        _showSuccessMessage('Comment added successfully!');
        // Refresh page with updated post data
        _refreshPageWithUpdatedPost(updatedPost);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmittingComment = false);
        _showErrorMessage('Error adding comment: $e');
      }
    }
  }

  /// Submits a reply (sub-comment) to an existing comment
  /// @param commentId - The MongoDB ObjectId of the parent comment
  Future<void> _submitSubComment(String commentId) async {
    final subCommentText = _subCommentController.text.trim();
    if (subCommentText.isEmpty) return;

    setState(() => _isSubmittingSubComment = true);

    try {
      final updatedPost = await FanbasePostService.addSubCommentToFanbasePost(
        widget.postId,
        commentId, // ✅ Use commentId
        subCommentText,
        context,
        fanbaseId: widget.fanbaseId,
      );

      if (mounted) {
        _subCommentController.clear();
        _subCommentFocusNode.unfocus();
        setState(() => _replyToCommentId = null); // ✅ Changed
        _showSuccessMessage('Reply added successfully!');
        _refreshPageWithUpdatedPost(updatedPost);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmittingSubComment = false);
        _showErrorMessage('Error adding reply: $e');
      }
    }
  }

  // ==================== HELPER METHODS ====================

  /// Refreshes the page by replacing it with a new instance
  /// This pattern ensures we get fresh data from the API response
  void _refreshPageWithUpdatedPost(dynamic updatedPost) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PostDetailPage(
          postId: widget.postId,
          trackId: widget.trackId,
          songName: widget.songName,
          artists: widget.artists,
          albumImage: widget.albumImage,
          // Convert FanbasePostComment objects back to Map format
          comments: _mapCommentsToDisplay(updatedPost.comments),
          username: widget.username,
          userImage: widget.userImage,
          title: widget.title,
          description: widget.description,
          isLiked: widget.isLiked,
          isPlaying: widget.isPlaying,
          isCurrentTrack: widget.isCurrentTrack,
          backgroundColor: widget.backgroundColor,
          fanbaseId: widget.fanbaseId,
          likesCount: widget.likesCount,
          commentsCount: updatedPost.commentsCount,
        ),
      ),
    );
  }

  /// Converts FanbasePostComment objects to Map format for display
  /// Maps proper field names (userName -> username, comment -> text)
  /// Handles missing commentIndex by using array position as fallback
  List<Map<String, dynamic>> _mapCommentsToDisplay(List comments) {
    return comments.map((comment) {
      return {
        'username': comment.userName ?? 'Unknown User',
        'text': comment.comment ?? '',
        'userId': comment.userId ?? '',
        'commentId': comment.commentId ?? '', // ✅ Changed
        'likeCount': (comment.likeCount ?? 0).toString(),
        'createdAt': comment.createdAt?.toIso8601String() ??
            DateTime.now().toIso8601String(),
        'subComments': (comment.subComments ?? []).map((subComment) {
          return {
            'username': subComment.userName ?? 'Unknown User',
            'text': subComment.comment ?? '',
            'userId': subComment.userId ?? '',
            'commentId': subComment.commentId ?? '', // ✅ Changed
            'likeCount': (subComment.likeCount ?? 0).toString(),
            'createdAt': subComment.createdAt?.toIso8601String() ??
                DateTime.now().toIso8601String(),
          };
        }).toList(),
      };
    }).toList();
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Formats a DateTime string into human-readable relative time
  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) return '${difference.inDays}d ago';
      if (difference.inHours > 0) return '${difference.inHours}h ago';
      if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
      return 'Just now';
    } catch (e) {
      return '';
    }
  }

  // ==================== UI BUILDERS ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      resizeToAvoidBottomInset: true, // Adjusts layout when keyboard appears
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 10,
          right: 10,
          top: 16,
          bottom: 80, // Space for bottom input bar
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
            _buildCommentsSection(),
          ],
        ),
      ),
      // Fixed bottom bar for adding main comments
      bottomNavigationBar: _buildCommentInputBar(),
    );
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
          // Pass back whether user added a comment (for parent refresh)
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
    // Song information card with album art and playback controls
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
          IconButton(
            icon: Icon(
              Icons.play_arrow_sharp,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Image.asset(
              'assets/images/spotify.png',
              height: 24,
            ),
            onPressed: () {},
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

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Comments (${_comments.length})",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (_comments.isEmpty)
          _buildEmptyCommentsPlaceholder()
        else
          // Map each comment to a comment card widget
          ..._comments.map((comment) => _buildCommentCard(comment)).toList(),
      ],
    );
  }

  Widget _buildEmptyCommentsPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          'No comments yet. Be the first to comment!',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// Builds a single comment card with reply functionality
  Widget _buildCommentCard(Map<String, dynamic> comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800.withOpacity(0.3)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCommentHeader(comment),
          const SizedBox(height: 2),
          _buildCommentBody(comment),
          const SizedBox(height: 3),
          _buildCommentActions(comment),

          // Show inline reply input
          if (_replyToCommentId != null &&
              _replyToCommentId!.isNotEmpty &&
              comment['commentId'] != null &&
              comment['commentId'].toString().isNotEmpty &&
              _replyToCommentId == comment['commentId'].toString())
            _buildInlineReplyInput(comment['commentId'].toString()),

          const SizedBox(height: 8),
          // Show sub-comments section if this comment has replies
          if (comment['subComments'] != null &&
              (comment['subComments'] as List).isNotEmpty)
            _buildSubCommentsSection(comment),
        ],
      ),
    );
  }

  Widget _buildCommentHeader(Map<String, dynamic> comment) {
    return Row(
      children: [
        Text(
          comment['username'] ?? 'Unknown User',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 10,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        const Spacer(),
        if (comment['createdAt'] != null)
          Text(
            _formatDateTime(comment['createdAt']!),
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
      ],
    );
  }

  Widget _buildCommentBody(Map<String, dynamic> comment) {
    return Padding(
      padding: const EdgeInsets.only(left: 15),
      child: Text(
        comment['text'] ?? '',
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }

  /// Comment actions: like button and reply button
  Widget _buildCommentActions(Map<String, dynamic> comment) {
    final commentId = comment['commentId']?.toString() ?? ''; // ✅ Changed
    final hasValidId = commentId.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(left: 15),
      child: Row(
        children: [
          // Like button (not implemented yet)
          Icon(Icons.favorite_border, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 4),
          Text(
            comment['likeCount'] ?? '0',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(width: 10),

          // REPLY BUTTON: Only enabled if comment has valid index
          GestureDetector(
            onTap: hasValidId
                ? () {
                    print('Reply clicked for comment: $commentId');
                    setState(() {
                      // Toggle reply input: if already replying to this comment, close it
                      if (_replyToCommentId == commentId) {
                        _replyToCommentId = null;
                        _subCommentController.clear();
                      } else {
                        // Set this comment's index as the active reply target
                        _replyToCommentId = commentId; // ✅ Changed
                      }
                    });
                    // Auto-focus the reply input after it appears
                    if (_replyToCommentId != null) {
                      Future.delayed(const Duration(milliseconds: 100), () {
                        _subCommentFocusNode.requestFocus();
                      });
                    }
                  }
                : null, // Disable if no valid index
            child: Opacity(
              opacity: hasValidId ? 1.0 : 0.5, // Dim if disabled
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    Icon(LucideIcons.repeat,
                        size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    // Show count of sub-comments (replies)
                    Text(
                      ((comment['subComments'] as List?)?.length ?? 0)
                          .toString(),
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// INLINE REPLY INPUT: Shows directly under the comment being replied to
  /// @param commentId - Actually commentIndex (array position)
  Widget _buildInlineReplyInput(String? commentId) {
    if (commentId == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12, left: 15),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade900.withOpacity(0.5)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Write a reply',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              // Close button to cancel reply
              GestureDetector(
                onTap: () {
                  setState(() {
                    _replyToCommentId = null;
                    _subCommentController.clear();
                  });
                  _subCommentFocusNode.unfocus();
                },
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Reply input field with send button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _subCommentController,
                  focusNode: _subCommentFocusNode,
                  enabled: !_isSubmittingSubComment,
                  decoration: InputDecoration(
                    hintText: 'Write your reply...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    _submitSubComment(commentId);
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Send button
              GestureDetector(
                onTap: _isSubmittingSubComment
                    ? null
                    : () => _submitSubComment(commentId),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isSubmittingSubComment
                        ? Colors.grey
                        : Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _isSubmittingSubComment
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Displays all replies (sub-comments) for a comment
  Widget _buildSubCommentsSection(Map<String, dynamic> comment) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade900
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Replies:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...(comment['subComments'] as List)
              .map((subComment) => _buildSubCommentCard(subComment))
              .toList(),
        ],
      ),
    );
  }

  /// Builds a single sub-comment (reply) card
  Widget _buildSubCommentCard(Map<String, dynamic> subComment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                subComment['username'] ?? 'Unknown User',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              const Spacer(),
              if (subComment['createdAt'] != null)
                Text(
                  _formatDateTime(subComment['createdAt']!),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Text(
              subComment['text'] ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Row(
              children: [
                Icon(Icons.favorite_border,
                    size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  subComment['likeCount'] ?? '0',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Fixed bottom input bar for adding top-level comments
  Widget _buildCommentInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              focusNode: _commentFocusNode,
              enabled: !_isSubmittingComment,
              decoration: InputDecoration(
                hintText: 'Add a comment',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitComment(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isSubmittingComment ? null : _submitComment,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isSubmittingComment ? Colors.grey : Colors.purple,
                borderRadius: BorderRadius.circular(24),
              ),
              child: _isSubmittingComment
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
