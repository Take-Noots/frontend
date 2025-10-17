import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import 'package:share_plus/share_plus.dart';
import '../../../data/services/post_report_service.dart';

class PostOptionsMenu extends StatefulWidget {
  final String? postUserId;
  final String? currentUserId;
  final bool? isOwnPost;
  final bool? isSaved;
  final bool? isFollowing;
  final String? postId;
  final String? username;
  final String? songName;
  final String? artistName;
  final VoidCallback? onSharePost;
  final VoidCallback? onSavePost;
  final VoidCallback? onUnsavePost;
  final VoidCallback? onFollow;
  final VoidCallback? onUnfollow;
  final VoidCallback? onReport;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onHide;

  const PostOptionsMenu({
    super.key,
    this.postUserId,
    this.currentUserId,
    this.isOwnPost,
    this.isSaved,
    this.isFollowing,
    this.postId,
    this.username,
    this.songName,
    this.artistName,
    this.onSharePost,
    this.onSavePost,
    this.onUnsavePost,
    this.onFollow,
    this.onUnfollow,
    this.onReport,
    this.onEdit,
    this.onDelete,
    this.onHide,
  });

  static void show(
    BuildContext context, {
    String? postUserId,
    String? currentUserId,
    bool? isOwnPost,
    bool? isSaved,
    bool? isFollowing,
    String? postId,
    String? username,
    String? songName,
    String? artistName,
    VoidCallback? onSharePost,
    VoidCallback? onSavePost,
    VoidCallback? onUnsavePost,
    VoidCallback? onFollow,
    VoidCallback? onUnfollow,
    VoidCallback? onReport,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onHide,
  }) {
    // Enhanced logic to determine if post belongs to current user
    bool isCurrentUserPost;

    // First, use explicit isOwnPost if provided
    if (isOwnPost != null) {
      isCurrentUserPost = isOwnPost;
    }
    // Otherwise, compare IDs if both are available
    else if (postUserId != null && currentUserId != null) {
      isCurrentUserPost = postUserId == currentUserId;
    }
    // If either ID is null, assume it's not the user's post
    else {
      isCurrentUserPost = false;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color.fromARGB(255, 0, 0, 0)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => PostOptionsMenu(
        postUserId: postUserId,
        currentUserId: currentUserId,
        isOwnPost: isCurrentUserPost,
        isSaved: isSaved,
        isFollowing: isFollowing,
        postId: postId,
        username: username,
        songName: songName,
        artistName: artistName,
        onSharePost: onSharePost,
        onSavePost: onSavePost,
        onUnsavePost: onUnsavePost,
        onFollow: onFollow,
        onUnfollow: onUnfollow,
        onReport: onReport,
        onEdit: onEdit,
        onDelete: onDelete,
        onHide: onHide,
      ),
    );
  }

  @override
  State<PostOptionsMenu> createState() => _PostOptionsMenuState();
}

class _PostOptionsMenuState extends State<PostOptionsMenu> {
  late bool _isSaved;
  late bool _isFollowing;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.isSaved ?? false;
    _isFollowing = widget.isFollowing ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    // Enhanced logic to determine if post belongs to current user
    bool isCurrentUserPost;

    // First, use explicit isOwnPost if provided
    if (widget.isOwnPost != null) {
      isCurrentUserPost = widget.isOwnPost!;
    }
    // Otherwise, compare IDs if both are available
    else if (widget.postUserId != null && widget.currentUserId != null) {
      isCurrentUserPost = widget.postUserId == widget.currentUserId;
    }
    // If either ID is null, assume it's not the user's post
    else {
      isCurrentUserPost = false;
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with rounded drag handle
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Options list
          ListTile(
            leading: Icon(LucideIcons.share, color: textColor),
            title: Text('Share post', style: TextStyle(color: textColor)),
            onTap: () {
              Navigator.pop(context);
              if (widget.postId != null && widget.postUserId != null) {
                // Create a user-friendly share message
                String shareText = 'Check out this post';
                if (widget.username != null) {
                  shareText += ' by @${widget.username}';
                }
                if (widget.songName != null) {
                  shareText += '\n🎵 ${widget.songName}';
                  if (widget.artistName != null) {
                    shareText += ' - ${widget.artistName}';
                  }
                }
                // Use deep link scheme for mobile apps
                shareText +=
                    '$baseUrl/profile/${widget.postUserId}/post/${widget.postId}';

                Share.share(shareText, subject: 'Check out this post on Noot');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                        'Unable to share post: Post information not available'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(10),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
              if (widget.onSharePost != null) widget.onSharePost!();
            },
          ),

          if (isCurrentUserPost) ...[
            // Show edit option for own posts
            ListTile(
              leading: Icon(LucideIcons.pencil, color: textColor),
              title: Text('Edit post', style: TextStyle(color: textColor)),
              onTap: () {
                Navigator.pop(context);
                if (widget.onEdit != null) widget.onEdit!();
              },
            ),
            // Show delete option for own posts
            ListTile(
              leading: Icon(LucideIcons.trash2, color: Colors.red),
              title: const Text('Delete post',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                if (widget.onDelete != null) widget.onDelete!();
              },
            ),
            // Show hide option for own posts
            ListTile(
              leading: Icon(LucideIcons.eyeOff, color: textColor),
              title: Text('Hide post', style: TextStyle(color: textColor)),
              onTap: () {
                Navigator.pop(context);
                if (widget.onHide != null) {
                  widget.onHide!();
                }
              },
            ),
          ] else ...[
            // Show save/unsave options for other users' posts
            ListTile(
              leading: Icon(
                _isSaved ? LucideIcons.bookmarkMinus : LucideIcons.bookmark,
                color: _isSaved ? Colors.blue : textColor,
              ),
              title: Text(
                _isSaved ? 'Unsave post' : 'Save post',
                style: TextStyle(
                  color: _isSaved ? Colors.blue : textColor,
                ),
              ),
              onTap: () async {
                if (widget.currentUserId == null || widget.postId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                          'Error: User or post information not available'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.all(10),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                final wasSaved = _isSaved;
                Navigator.pop(context);
                // Call the appropriate callback
                if (wasSaved) {
                  if (widget.onUnsavePost != null) {
                    widget.onUnsavePost!();
                  }
                } else {
                  if (widget.onSavePost != null) {
                    widget.onSavePost!();
                  }
                }
              },
            ),
            ListTile(
              leading: Icon(
                _isFollowing ? LucideIcons.userMinus : LucideIcons.userPlus,
                color: textColor,
              ),
              title: Text(
                _isFollowing ? 'Unfollow' : 'Follow',
                style: TextStyle(color: textColor),
              ),
              onTap: () async {
                if (widget.currentUserId == null || widget.postUserId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                          'Error: User or post information not available'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.all(10),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                final wasFollowing = _isFollowing;
                Navigator.pop(context);
                // Call the provided callbacks
                if (wasFollowing) {
                  if (widget.onUnfollow != null) {
                    widget.onUnfollow!();
                  }
                } else {
                  if (widget.onFollow != null) {
                    widget.onFollow!();
                  }
                }
              },
            ),
            // Show report option only for other users' posts
            ListTile(
              leading: Icon(LucideIcons.flag, color: Colors.red),
              title: const Text('Report', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                // Show report options menu
                _showReportOptions(context, widget.postUserId, widget.postId);
              },
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static const String baseUrl =
      'noot://app'; // Custom deep link scheme for mobile

  static void _showReportOptions(
      BuildContext context, String? reportedUserId, String? postId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final purpleColor = const Color(0xFFA855F7);

    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with rounded drag handle
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title with icon
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.flag,
                        color: purpleColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Report Post',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 8.0),
                  child: Text(
                    'Why are you reporting this post?',
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Report options with enhanced styling
                _buildReportOption(context, 'Spam', LucideIcons.ban,
                    reportedUserId, postId, textColor, purpleColor),
                _buildReportOption(
                    context,
                    'Inappropriate content',
                    LucideIcons.alertTriangle,
                    reportedUserId,
                    postId,
                    textColor,
                    purpleColor),
                _buildReportOption(
                    context,
                    'Harmful or abusive',
                    LucideIcons.shield,
                    reportedUserId,
                    postId,
                    textColor,
                    purpleColor),
                _buildReportOption(
                    context,
                    'Intellectual property violation',
                    LucideIcons.copyright,
                    reportedUserId,
                    postId,
                    textColor,
                    purpleColor),
                _buildReportOption(context, 'Other', LucideIcons.helpCircle,
                    reportedUserId, postId, textColor, purpleColor),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildReportOption(
      BuildContext context,
      String title,
      IconData icon,
      String? reportedUserId,
      String? postId,
      Color textColor,
      Color purpleColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: textColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: purpleColor,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          _submitReport(context, title, reportedUserId, postId);
        },
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),
    );
  }

  static void _submitReport(BuildContext context, String reason,
      String? reportedUserId, String? postId) async {
    if (reportedUserId == null || postId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error: Missing user or post information'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    try {
      final result = await PostReportService.reportPost(
        reportedUserId: reportedUserId,
        reportedPostId: postId,
        reason: reason,
        context: context,
      );

      if (context.mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(result['message'] ?? 'Report submitted successfully'),
              backgroundColor: const Color(0xFFA855F7),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(10),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to submit report'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(10),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
