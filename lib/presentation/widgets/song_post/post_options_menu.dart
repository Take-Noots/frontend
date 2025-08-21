import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../../../data/services/post_report_service.dart';

class PostOptionsMenu {
  static void show(
    BuildContext context, {
    String? postUserId,
    String? currentUserId,
    bool? isOwnPost,
    bool? isSaved,
    String? postId,
    VoidCallback? onCopyLink,
    VoidCallback? onSavePost,
    VoidCallback? onUnsavePost,
    VoidCallback? onUnfollow,
    VoidCallback? onReport,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onHide,
  }) {
    // Debug output to understand the values
    print(
        'PostOptionsMenu - postUserId: $postUserId, currentUserId: $currentUserId');
    print('PostOptionsMenu - isOwnPost: $isOwnPost');
    print('PostOptionsMenu - isSaved: $isSaved');
    print('PostOptionsMenu - postId: $postId');
    print('PostOptionsMenu - onHide callback is ${onHide != null ? "NOT NULL" : "NULL"}');

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

    print('PostOptionsMenu - isCurrentUserPost: $isCurrentUserPost');

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color.fromARGB(255, 0, 0, 0) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
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
                leading: Icon(LucideIcons.link, color: textColor),
                title: Text('Copy link', style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(context);
                  if (onCopyLink != null) onCopyLink();
                },
              ),

              if (isCurrentUserPost) ...[
                // Show edit option for own posts
                ListTile(
                  leading: Icon(LucideIcons.pencil, color: textColor),
                  title: Text('Edit post', style: TextStyle(color: textColor)),

                  onTap: () {
                    Navigator.pop(context);
                    if (onEdit != null) onEdit();
                  },
                ),
                // Show delete option for own posts
                ListTile(
                  leading: Icon(LucideIcons.trash2, color: Colors.red),
                  title: const Text('Delete post',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    if (onDelete != null) onDelete();
                  },
                ),
                // Show hide option for own posts
                ListTile(
                  leading: Icon(LucideIcons.eyeOff, color: textColor),
                  title: Text('Hide post', style: TextStyle(color: textColor)),
                  onTap: () {
                    print('[DEBUG] PostOptionsMenu: Hide post tapped');
                    print('[DEBUG] PostOptionsMenu: onHide callback is ${onHide != null ? "NOT NULL" : "NULL"}');
                    Navigator.pop(context);
                    if (onHide != null) {
                      print('[DEBUG] PostOptionsMenu: Calling onHide callback');
                      onHide();
                    } else {
                      print('[DEBUG] PostOptionsMenu: onHide callback is null, not calling');
                    }
                  },
                ),
              ] else ...[
                // Show save/unsave options for other users' posts
                ListTile(
                  leading: Icon(
                    isSaved == true ? LucideIcons.bookmarkMinus : LucideIcons.bookmark,
                    color: isSaved == true ? Colors.blue : textColor,
                  ),
                  title: Text(
                    isSaved == true ? 'Unsave post' : 'Save post',
                    style: TextStyle(
                      color: isSaved == true ? Colors.blue : textColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    if (isSaved == true) {
                      if (onUnsavePost != null) onUnsavePost();
                    } else {
                      if (onSavePost != null) onSavePost();
                    }
                  },
                ),
                ListTile(
                  leading: Icon(LucideIcons.userMinus, color: textColor),
                  title: Text('Unfollow', style: TextStyle(color: textColor)),
                  onTap: () {
                    Navigator.pop(context);
                    if (onUnfollow != null) onUnfollow();
                  },
                ),
                // Show report option only for other users' posts
                ListTile(
                  leading: Icon(LucideIcons.flag, color: Colors.red),
                  title:
                      const Text('Report', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    // Show report options menu
                    _showReportOptions(context, postUserId, postId);
                  },
                ),
              ],

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  static void _showReportOptions(BuildContext context, String? reportedUserId, String? postId) {
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
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
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
                _buildReportOption(context, 'Spam', LucideIcons.ban, reportedUserId, postId, textColor, purpleColor),
                _buildReportOption(context, 'Inappropriate content', LucideIcons.alertTriangle, reportedUserId, postId, textColor, purpleColor),
                _buildReportOption(context, 'Harmful or abusive', LucideIcons.shield, reportedUserId, postId, textColor, purpleColor),
                _buildReportOption(context, 'Intellectual property violation', LucideIcons.copyright, reportedUserId, postId, textColor, purpleColor),
                _buildReportOption(context, 'Other', LucideIcons.helpCircle, reportedUserId, postId, textColor, purpleColor),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildReportOption(BuildContext context, String title, IconData icon, String? reportedUserId, String? postId, Color textColor, Color purpleColor) {
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),
    );
  }

  static void _submitReport(BuildContext context, String reason, String? reportedUserId, String? postId) async {
    print('[DEBUG] _submitReport called with:');
    print('[DEBUG] - reason: $reason');
    print('[DEBUG] - reportedUserId: $reportedUserId');
    print('[DEBUG] - postId: $postId');
    
    if (reportedUserId == null || postId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error: Missing user or post information'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final result = await PostReportService.reportPost(
        reportedUserId: reportedUserId,
        reportedPostId: postId,
        reason: reason,
        context: context,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Report submitted successfully'),
            backgroundColor: const Color(0xFFA855F7),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting report: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
