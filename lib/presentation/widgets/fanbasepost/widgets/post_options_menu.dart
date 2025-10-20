import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../data/services/fanbase_post_service.dart';
import '../../../../data/services/fanbase_post_report_service.dart'; // Add this import
import '../../../../data/models/fanbase_post_model.dart';

class PostOptionsMenu {
  static void show(
    BuildContext context, {
    String? postUserId,
    String? currentUserId,
    String? fanbaseOwnerId,
    bool? isOwnPost,
    FanbasePost? post,
    String? fanbaseId,
    VoidCallback? onCopyLink,
    VoidCallback? onSavePost,
    VoidCallback? onUnfollow,
    VoidCallback? onReport,
    VoidCallback? onEdit,
    VoidCallback? onPostDeleted,
    VoidCallback? onHide,
  }) {
    // Determine user type
    bool isPostCreator = false;
    bool isFanbaseOwner = false;
    bool isPostViewer = false;

    if(fanbaseOwnerId == null && postUserId == null) {
      print('Both fanbaseOwnerId and postUserId are null. Cannot determine user type.');
    }

    if(fanbaseOwnerId != null && fanbaseOwnerId == postUserId && fanbaseOwnerId == currentUserId) {
      print('fanbaseOwnerId and postUserId are the same. User is both owner and creator.');
      isFanbaseOwner = true;
    }

    if(postUserId != null && currentUserId == postUserId && (fanbaseOwnerId == null || fanbaseOwnerId != currentUserId)) {
      print('postUserId matches currentUserId. User is the post creator.');
      isPostCreator = true;
    }

    if(!isPostCreator && !isFanbaseOwner) {
      print('User is neither post creator nor fanbase owner. User is a post viewer.');
      isPostViewer = true;
    }

    print('=== PostOptionsMenu Debug ===');
    print('Current User ID: $currentUserId');
    print('Post Creator ID: $postUserId');
    print('Fanbase Owner ID: $fanbaseOwnerId');
    print('Is Post Creator: $isPostCreator');
    print('Is Fanbase Owner: $isFanbaseOwner');
    print('Is Post Viewer: $isPostViewer');

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
      builder: (bottomSheetContext) {
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

              // Options based on user type
              if (isPostCreator) ...[
                // Post Creator: Show Delete option
                ListTile(
                  leading: Icon(LucideIcons.trash2, color: Colors.red),
                  title: const Text(
                    'Delete post',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    print('[DEBUG] Delete post tapped');
                    print('[DEBUG] post is null: ${post == null}');
                    print('[DEBUG] fanbaseId is null: ${fanbaseId == null}');
                    print('[DEBUG] post value: $post');
                    print('[DEBUG] fanbaseId value: $fanbaseId');

                    // Close the bottom sheet first
                    Navigator.pop(bottomSheetContext);

                    if (post != null && fanbaseId != null) {
                      print('[DEBUG] Calling _handleDeletePost');
                      // Use the ORIGINAL context, not bottomSheetContext
                      _handleDeletePost(
                        context, // ← Use the parent context, not bottomSheetContext
                        post,
                        fanbaseId,
                        onPostDeleted,
                      );
                    } else {
                      print(
                          '[DEBUG] NOT calling _handleDeletePost - missing parameters');
                      print('[DEBUG] post: ${post == null ? "NULL" : "OK"}');
                      print(
                          '[DEBUG] fanbaseId: ${fanbaseId == null ? "NULL" : "OK"}');

                      // Show error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Error: Missing post or fanbase information'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ] else if (isFanbaseOwner) ...[
                // Fanbase Owner: Show Remove option
                ListTile(
                  leading: Icon(LucideIcons.xCircle, color: Colors.red),
                  title: const Text(
                    'Remove post',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    print('[DEBUG] Remove post tapped');
                    print('[DEBUG] post is null: ${post == null}');
                    print('[DEBUG] fanbaseId is null: ${fanbaseId == null}');

                    // Close the bottom sheet first
                    Navigator.pop(bottomSheetContext);

                    if (post != null && fanbaseId != null) {
                      print('[DEBUG] Calling _handleRemovePost');
                      // Use the ORIGINAL context, not bottomSheetContext
                      _handleRemovePost(
                        context, // ← Use the parent context, not bottomSheetContext
                        post,
                        fanbaseId,
                        onPostDeleted,
                      );
                    } else {
                      print(
                          '[DEBUG] NOT calling _handleRemovePost - missing parameters');
                      print('[DEBUG] post: ${post == null ? "NULL" : "OK"}');
                      print(
                          '[DEBUG] fanbaseId: ${fanbaseId == null ? "NULL" : "OK"}');

                      // Show error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Error: Missing post or fanbase information'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ] else if (isPostViewer) ...[
                // Post Viewer: Show Report option
                ListTile(
                  leading: Icon(LucideIcons.flag, color: Colors.red),
                  title: const Text(
                    'Report post',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    // Pass the post object to _showReportOptions
                    _showReportOptions(context, post, onReport);
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

  /// Handles deleting a post by the post creator
  static Future<void> _handleDeletePost(
    BuildContext context,
    FanbasePost post,
    String fanbaseId,
    VoidCallback? onPostDeleted,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text('Delete Post'),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // IMPORTANT: Capture ScaffoldMessenger BEFORE any async operations
      final messenger = ScaffoldMessenger.of(context);

      // Show loading snackbar
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Deleting post...'),
            ],
          ),
          duration: const Duration(seconds: 30),
          backgroundColor: Colors.grey,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );

      try {
        await FanbasePostService.deleteFanbasePost(
          post.id,
          context,
          fanbaseId: fanbaseId,
        );

        // Clear loading snackbar
        messenger.clearSnackBars();

        // Show success snackbar BEFORE calling onPostDeleted
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Post deleted successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );

        // Small delay to ensure snackbar is visible before state changes
        await Future.delayed(const Duration(milliseconds: 300));

        // Notify parent to refresh (this might cause UI changes)
        if (onPostDeleted != null) {
          onPostDeleted();
        }
      } catch (e) {
        // Clear loading snackbar
        messenger.clearSnackBars();

        // Show error snackbar
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Failed to delete post: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    }
  }

  /// Handles removing a post by the fanbase owner
  static Future<void> _handleRemovePost(
    BuildContext context,
    FanbasePost post,
    String fanbaseId,
    VoidCallback? onPostDeleted,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text('Remove Post'),
        content: Text(
          'Are you sure you want to remove this post by ${post.createdBy['userName'] ?? 'Unknown User'}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // IMPORTANT: Capture ScaffoldMessenger BEFORE any async operations
      final messenger = ScaffoldMessenger.of(context);

      // Show loading snackbar
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Removing post...'),
            ],
          ),
          duration: const Duration(seconds: 30),
          backgroundColor: Colors.grey,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );

      try {
        // Use the same delete endpoint - owners can delete any post in their fanbase
        await FanbasePostService.deleteFanbasePost(
          post.id,
          context,
          fanbaseId: fanbaseId,
        );

        // Clear loading snackbar
        messenger.clearSnackBars();

        // Show success snackbar BEFORE calling onPostDeleted
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Post removed successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );

        // Small delay to ensure snackbar is visible before state changes
        await Future.delayed(const Duration(milliseconds: 300));

        // Notify parent to refresh (this might cause UI changes)
        if (onPostDeleted != null) {
          onPostDeleted();
        }
      } catch (e) {
        // Clear loading snackbar
        messenger.clearSnackBars();

        // Show error snackbar
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Failed to remove post: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    }
  }

  static void _showReportOptions(
    BuildContext context,
    FanbasePost? post, // Add post parameter
    VoidCallback? onReport,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black : Colors.white;
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
                      color: Colors.grey.withOpacity(0.5),
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
                      Icon(LucideIcons.flag, color: purpleColor, size: 24),
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
                      color: textColor,
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Report options with enhanced styling
                _buildReportOption(
                  context,
                  'Spam',
                  LucideIcons.ban,
                  textColor,
                  purpleColor,
                  post, // Pass post
                  onReport,
                ),
                _buildReportOption(
                  context,
                  'Inappropriate content',
                  LucideIcons.alertTriangle,
                  textColor,
                  purpleColor,
                  post, // Pass post
                  onReport,
                ),
                _buildReportOption(
                  context,
                  'Harmful or abusive',
                  LucideIcons.shield,
                  textColor,
                  purpleColor,
                  post, // Pass post
                  onReport,
                ),
                _buildReportOption(
                  context,
                  'Intellectual property violation',
                  LucideIcons.copyright,
                  textColor,
                  purpleColor,
                  post, // Pass post
                  onReport,
                ),
                _buildReportOption(
                  context,
                  'Other',
                  LucideIcons.helpCircle,
                  textColor,
                  purpleColor,
                  post, // Pass post
                  onReport,
                ),

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
    Color textColor,
    Color purpleColor,
    FanbasePost? post, // Add post parameter
    VoidCallback? onReport,
  ) {
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
          _submitReport(context, title, post); // Pass post
          if (onReport != null) onReport();
        },
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),
    );
  }

  static Future<void> _submitReport(
    BuildContext context,
    String reason,
    FanbasePost? post, // Add post parameter
  ) async {
    if (post == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error: Post information not available'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Show loading indicator
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Submitting report...'),
          ],
        ),
        duration: const Duration(seconds: 30),
        backgroundColor: Colors.grey,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );

    try {
      final result = await FanbasePostReportService.reportPost(
        reportedPostId: post.id,
        reportedUserId: post.createdBy['userId'] ?? '',
        reason: reason,
        description: 'User reported post: ${post.topic}',
        context: context,
      );

      // Clear the loading snackbar
      messenger.clearSnackBars();

      // Small delay to ensure the loading snackbar is cleared
      await Future.delayed(const Duration(milliseconds: 100));

      // Check for success
      final isSuccess = result['success'] == true;

      if (isSuccess) {
        // Show success message
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Report submitted successfully!',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFA855F7),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        // Show error message
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result['message'] ?? 'Failed to submit report',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Exception in _submitReport: $e');

      // Clear the loading snackbar
      messenger.clearSnackBars();

      await Future.delayed(const Duration(milliseconds: 100));

      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Failed to submit report: ${e.toString()}',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
