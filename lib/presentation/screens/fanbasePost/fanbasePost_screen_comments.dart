import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../data/services/fanbase_post_service.dart';
import '../../widgets/fanbasepost/threaded_comment_widget.dart';

/// Stateful widget that handles all comment-related functionality
/// Includes displaying comments, adding comments, replies, and likes
class FanbasePostCommentsSection extends StatefulWidget {
  final String postId;
  final String fanbaseId;
  final List<Map<String, dynamic>> comments;
  final Future<void> Function() onCommentAdded;
  final String? currentUserId; // ✅ Add current user ID
  final String? postCreatorId; // ✅ Add post creator ID
  final String? fanbaseOwnerId; // ✅ Add fanbase owner ID

  const FanbasePostCommentsSection({
    super.key,
    required this.postId,
    required this.fanbaseId,
    required this.comments,
    required this.onCommentAdded,
    this.currentUserId,
    this.postCreatorId,
    this.fanbaseOwnerId,
  });

  @override
  State<FanbasePostCommentsSection> createState() =>
      FanbasePostCommentsSectionState();
}

class FanbasePostCommentsSectionState
    extends State<FanbasePostCommentsSection> {
  // ==================== CONTROLLERS & STATE ====================

  late final TextEditingController _commentController;
  late final TextEditingController _subCommentController;
  late final FocusNode _commentFocusNode;
  late final FocusNode _subCommentFocusNode;

  List<Map<String, dynamic>> _comments = [];
  bool _isSubmittingComment = false;
  bool _isSubmittingSubComment = false;
  String? _replyToCommentId;

  // ==================== LIFECYCLE METHODS ====================

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _comments = List.from(widget.comments);
    // _debugPrintComments();
  }

  void _initializeControllers() {
    _commentController = TextEditingController();
    _subCommentController = TextEditingController();
    _commentFocusNode = FocusNode();
    _subCommentFocusNode = FocusNode();
  }

  // void _debugPrintComments() {
  //   print('=== Comments Section Debug ===');
  //   print('Total comments received: ${widget.comments.length}');
  //   print('Comments data: ${widget.comments}');
  // }

  @override
  void didUpdateWidget(FanbasePostCommentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comments != widget.comments) {
      setState(() {
        _comments = List.from(widget.comments);
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _subCommentController.dispose();
    _commentFocusNode.dispose();
    _subCommentFocusNode.dispose();
    super.dispose();
  }

  // ==================== COMMENT SUBMISSION ====================

  Future<void> _submitComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    setState(() => _isSubmittingComment = true);

    try {
      await FanbasePostService.addComment(
        widget.postId,
        commentText,
        context,
        fanbaseId: widget.fanbaseId,
      );

      if (mounted) {
        _commentController.clear();
        _commentFocusNode.unfocus();
        _showSuccessMessage('Comment added successfully!');

        // Call parent to refresh all comments from backend
        await widget
            .onCommentAdded(); // Now this works because it's a Future function

        // Reset loading state after refresh
        if (mounted) {
          setState(() => _isSubmittingComment = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmittingComment = false);
        _showErrorMessage('Error adding comment: $e');
      }
    }
  }

  Future<void> _submitSubComment(String commentId) async {
    final subCommentText = _subCommentController.text.trim();
    if (subCommentText.isEmpty) return;

    setState(() => _isSubmittingSubComment = true);

    try {
      await FanbasePostService.addSubCommentToFanbasePost(
        widget.postId,
        commentId,
        subCommentText,
        context,
        fanbaseId: widget.fanbaseId,
      );

      if (mounted) {
        _subCommentController.clear();
        _subCommentFocusNode.unfocus();
        setState(() => _replyToCommentId = null);
        _showSuccessMessage('Reply added successfully!');

        // Call parent to refresh all comments from backend
        await widget
            .onCommentAdded(); // Now this works because it's a Future function

        // Reset loading state after refresh
        if (mounted) {
          setState(() => _isSubmittingSubComment = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmittingSubComment = false);
        _showErrorMessage('Error adding reply: $e');
      }
    }
  }

  Future<void> _likeComment(String commentId) async {
    try {
      await FanbasePostService.likeComment(
        widget.postId,
        commentId,
        context,
        fanbaseId: widget.fanbaseId,
      );

      if (mounted) {
        await widget.onCommentAdded(); // Use await here too
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Error liking comment: $e');
      }
    }
  }

  Future<void> _likeSubComment(String commentId, String subCommentId) async {
    try {
      await FanbasePostService.likeSubComment(
        widget.postId,
        commentId,
        subCommentId,
        context,
        fanbaseId: widget.fanbaseId,
      );

      if (mounted) {
        await widget.onCommentAdded(); // Use await here too
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Error liking reply: $e');
      }
    }
  }

  // ==================== COMMENT DELETION ====================

  Future<void> _deleteComment(String commentId) async {
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Comment'),
          content: const Text(
            'Are you sure you want to delete this comment? All replies will also be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    // If user didn't confirm, return
    if (confirmed != true) return;

    try {
      await FanbasePostService.deleteComment(
        widget.postId,
        commentId,
        context,
        fanbaseId: widget.fanbaseId,
      );

      if (mounted) {
        _showSuccessMessage('Comment deleted successfully!');
        // Refresh comments from backend
        await widget.onCommentAdded();
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Error deleting comment: $e');
      }
    }
  }

  Future<void> _deleteSubComment(String commentId, String subCommentId) async {
    print('[DEBUG] _deleteSubComment called');
    print('[DEBUG] postId: ${widget.postId}');
    print('[DEBUG] commentId (parent): $commentId');
    print('[DEBUG] subCommentId: $subCommentId');
    print('[DEBUG] fanbaseId: ${widget.fanbaseId}');

    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Reply'),
          content: const Text(
            'Are you sure you want to delete this reply?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    // If user didn't confirm, return
    if (confirmed != true) {
      print('[DEBUG] User cancelled deletion');
      return;
    }

    print('[DEBUG] User confirmed deletion, proceeding...');

    try {
      await FanbasePostService.deleteSubComment(
        widget.postId,
        commentId,
        subCommentId,
        context,
        fanbaseId: widget.fanbaseId,
      );

      if (mounted) {
        _showSuccessMessage('Reply deleted successfully!');
        // Refresh comments from backend
        await widget.onCommentAdded();
      }
    } catch (e) {
      print('[ERROR] Failed to delete subcomment: $e');
      if (mounted) {
        _showErrorMessage('Error deleting reply: $e');
      }
    }
  }

  // ==================== HELPER METHODS ====================

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
    // Return only the comments section - input bar will be handled by parent
    return _buildCommentsSection();
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
          ..._comments.map((comment) => _buildCommentCard(comment)).toList(),
        // Add spacing at the bottom for the floating input bar
        const SizedBox(height: 80),
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
          if (_replyToCommentId != null &&
              _replyToCommentId!.isNotEmpty &&
              comment['commentId'] != null &&
              comment['commentId'].toString().isNotEmpty &&
              _replyToCommentId == comment['commentId'].toString())
            _buildInlineReplyInput(comment['commentId'].toString()),
          const SizedBox(height: 8),
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

  Widget _buildCommentActions(Map<String, dynamic> comment) {
    final commentId = comment['commentId']?.toString() ?? '';
    final hasValidId = commentId.isNotEmpty;
    final isLiked = comment['isLiked'] ?? false;
    final likeCount = comment['likeCount'] ?? '0';
    final commentUserId = comment['userId']?.toString() ?? '';

    // ✅ Check if current user can delete this comment
    final canDelete = widget.currentUserId != null &&
        (commentUserId == widget.currentUserId || // Comment owner
            widget.currentUserId == widget.postCreatorId || // Post creator
            widget.currentUserId == widget.fanbaseOwnerId); // Fanbase owner

    return Padding(
      padding: const EdgeInsets.only(left: 15),
      child: Row(
        children: [
          GestureDetector(
            onTap: hasValidId ? () => _likeComment(commentId) : null,
            child: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              size: 14,
              color: isLiked ? Colors.purple : Colors.grey.shade500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            likeCount,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: hasValidId
                ? () {
                    print('Reply clicked for comment: $commentId');
                    setState(() {
                      if (_replyToCommentId == commentId) {
                        _replyToCommentId = null;
                        _subCommentController.clear();
                      } else {
                        _replyToCommentId = commentId;
                      }
                    });
                    if (_replyToCommentId != null) {
                      Future.delayed(const Duration(milliseconds: 100), () {
                        _subCommentFocusNode.requestFocus();
                      });
                    }
                  }
                : null,
            child: Opacity(
              opacity: hasValidId ? 1.0 : 0.5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    Icon(LucideIcons.repeat,
                        size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
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
          const Spacer(), // Push the delete icon to the right
          if (canDelete) // ✅ Only show delete if user has permission
            GestureDetector(
              onTap: hasValidId ? () => _deleteComment(commentId) : null,
              child: Icon(
                Icons.remove_circle_outline,
                size: 16,
                color: hasValidId ? Colors.red.shade400 : Colors.grey.shade500,
              ),
            ),
        ],
      ),
    );
  }

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
                  onSubmitted: (_) => _submitSubComment(commentId),
                ),
              ),
              const SizedBox(width: 8),
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

  Widget _buildSubCommentsSection(Map<String, dynamic> comment) {
    final subComments = comment['subComments'] as List;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final threadLineColor =
        isDark ? Colors.grey.shade700 : Colors.grey.shade400;
    final parentCommentId = comment['commentId']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade900.withOpacity(0.5)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(subComments.length, (index) {
            final subComment = subComments[index] as Map<String, dynamic>;
            final subCommentId = subComment['commentId']?.toString() ?? '';

            // ✅ Add parentCommentId to subComment map with proper type
            final enrichedSubComment = Map<String, dynamic>.from(subComment)
              ..['parentCommentId'] = parentCommentId;

            return ThreadedCommentWidget(
              comment: enrichedSubComment,
              isFirst: index == 0,
              isLast: index == subComments.length - 1,
              formatDateTime: _formatDateTime,
              lineColor: threadLineColor,
              currentUserId: widget.currentUserId, // ✅ Pass user IDs
              postCreatorId: widget.postCreatorId,
              fanbaseOwnerId: widget.fanbaseOwnerId,
              onLike: subCommentId.isNotEmpty && parentCommentId.isNotEmpty
                  ? (scId) => _likeSubComment(parentCommentId, scId)
                  : null,
              onDelete: subCommentId.isNotEmpty && parentCommentId.isNotEmpty
                  ? (parentId, scId) => _deleteSubComment(parentId, scId)
                  : null,
            );
          }),
        ],
      ),
    );
  }

  // Make this method public so it can be called from parent
  Widget buildCommentInputBar() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.04,
        // vertical: 1,
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
      child: SafeArea(
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
      ),
    );
  }
}
