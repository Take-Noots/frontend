import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PostOptionsMenu {
  static void show(
    BuildContext context, {
    String? postUserId,
    String? currentUserId,
    bool? isOwnPost,
    VoidCallback? onCopyLink,
    VoidCallback? onSavePost,
    VoidCallback? onUnfollow,
    VoidCallback? onReport,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onHide,
  }) {
    // Debug output to understand the values
    print(
        'PostOptionsMenu - postUserId: $postUserId, currentUserId: $currentUserId');

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
                    Navigator.pop(context);
                    if (onHide != null) onHide();
                  },
                ),
              ] else ...[
                // Show save and unfollow options for other users' posts
                ListTile(
                  leading: Icon(LucideIcons.bookmark, color: textColor),
                  title: Text('Save post', style: TextStyle(color: textColor)),
                  onTap: () {
                    Navigator.pop(context);
                    if (onSavePost != null) onSavePost();
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
                    _showReportOptions(context);
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

  static void _showReportOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black : Colors.white;
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
                    color: Colors.grey.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Why are you reporting this post?',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),

              // Report options
              ListTile(
                title: Text('Spam', style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(context);
                  _submitReport(context, 'Spam');
                },
              ),
              ListTile(
                title: Text('Inappropriate content',
                    style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(context);
                  _submitReport(context, 'Inappropriate content');
                },
              ),
              ListTile(
                title: Text('Harmful or abusive',
                    style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(context);
                  _submitReport(context, 'Harmful or abusive');
                },
              ),
              ListTile(
                title: Text('Intellectual property violation',
                    style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(context);
                  _submitReport(context, 'Intellectual property violation');
                },
              ),
              ListTile(
                title: Text('Other', style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(context);
                  _submitReport(context, 'Other');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  static void _submitReport(BuildContext context, String reason) {
    // Show confirmation dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Report submitted: $reason'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 2),
      ),
    );

    // Here you would typically call an API to submit the report
    // Example: postBloc.add(ReportPostEvent(postId: postId, reason: reason));
  }
}
