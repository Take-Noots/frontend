import 'package:flutter/material.dart';
import 'comment_thread_painter.dart';

/// A widget that displays a single comment/reply with thread connection lines
/// Used for displaying sub-comments (replies) in a threaded conversation
class ThreadedCommentWidget extends StatelessWidget {
  final Map<String, dynamic> comment;
  final bool isFirst;
  final bool isLast;
  final String Function(String) formatDateTime;
  final Color? lineColor;
  final Function(String)? onLike; // ✅ Add callback for liking

  const ThreadedCommentWidget({
    Key? key,
    required this.comment,
    required this.isFirst,
    required this.isLast,
    required this.formatDateTime,
    this.lineColor,
    this.onLike, // ✅ Add to constructor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Determine thread line color based on theme
    final threadLineColor =
        lineColor ?? (isDark ? Colors.grey.shade700 : Colors.grey.shade400);

    return Stack(
      children: [
        // Draw thread connection lines behind the comment
        Positioned.fill(
          left: 0,
          child: CustomPaint(
            painter: CommentThreadPainter(
              drawTop: true, // Don't draw top line for first reply
              drawBottom: !isLast, // Don't draw bottom line for last reply
              lineColor: threadLineColor,
              strokeWidth: 2.0,
            ),
          ),
        ),

        // Comment content with left padding to make room for thread line
        Padding(
          padding: const EdgeInsets.only(left: 32.0, bottom: 8.0),
          child: _buildCommentCard(context, isDark),
        ),
      ],
    );
  }

  Widget _buildCommentCard(BuildContext context, bool isDark) {
    final isLiked = comment['isLiked'] ?? false;
    final likeCount = comment['likeCount'] ?? '0';
    final commentId = comment['commentId']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with username and timestamp
          Row(
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
                  formatDateTime(comment['createdAt']!),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),

          // Comment text
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Text(
              comment['text'] ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Like button
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: GestureDetector(
              onTap: onLike != null && commentId.isNotEmpty
                  ? () => onLike!(commentId)
                  : null,
              child: Row(
                children: [
                  Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 14,
                    color: isLiked
                        ? Colors.purple
                        : Colors.grey.shade500, // Changed to purple
                  ),
                  const SizedBox(width: 4),
                  Text(
                    likeCount,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
