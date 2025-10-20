import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'dart:convert';
import '../../../data/models/thoughts_model.dart';
import '../../../data/services/thoughts_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../despost/widgets/TMP_des_post_bg_container.dart';
import '../song_post/comment.dart';
import '../song_post/post_options_menu.dart';
import '../../../data/models/post_model.dart' as data_model;
import '../../../data/services/song_post_service.dart';
import '../../../core/styles/app_colors.dart';
import '../../screens/thoughts_posts/update_thoughts.dart';

// ================= ThoughtsFeedCard (Main Widget) =================
class ThoughtsFeedCard extends StatefulWidget {
  final ThoughtsPost post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final void Function(String userId, String? username)? onUserTap;
  final Function(ThoughtsPost)? onPostUpdated;
  final VoidCallback? onPlayPause;
  final VoidCallback? onOptionsTap;
  final bool isPlaying;
  final bool isCurrentTrack;
  final bool showCoverImage;
  final bool? isLiked;

  const ThoughtsFeedCard({
    Key? key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onUserTap,
    this.showCoverImage = true,
    this.isLiked,
    this.onPostUpdated,
    this.onPlayPause,
    this.onOptionsTap,
    this.isPlaying = false,
    this.isCurrentTrack = false,
  }) : super(key: key);

  @override
  State<ThoughtsFeedCard> createState() => _ThoughtsFeedCardState();
}

class _ThoughtsFeedCardState extends State<ThoughtsFeedCard> {
  Color? _extractedColor;
  final Color _defaultColor = const Color(0xFF2D1B69);
  late ThoughtsPost _currentPost;
  final ThoughtsService _thoughtsService = ThoughtsService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
    _loadCurrentUserId();
    _extractColorFromCoverImage();
  }

  @override
  void didUpdateWidget(ThoughtsFeedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local post when parent updates
    if (widget.post != oldWidget.post) {
          setState(() {
        _currentPost = widget.post;
      });
    }
  }

  Future<void> _extractColorFromCoverImage() async {
    setState(() {
      _extractedColor = _currentPost.backgroundColor != null
          ? Color(int.parse(
              _currentPost.backgroundColor!.replaceFirst('#', '0xFF')))
          : null; // Will use default color
    });
  }

  Future<void> _loadCurrentUserId() async {
    // Get current user ID - try AuthProvider first, then SharedPreferences as fallback
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String? currentUserId = authProvider.user?.id;

    // Fallback to SharedPreferences if AuthProvider doesn't have user ID
    if (currentUserId == null) {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      final userData =
          userDataString != null ? jsonDecode(userDataString) : {'id': ''};
      currentUserId = userData['id'];
    }

    if (mounted) {
      setState(() {
        _currentUserId = currentUserId;
      });
    }
  }

  void _handleOptionsTap() {
    if (_currentUserId == null) return;

    final isOwnPost = _currentUserId == _currentPost.userId;

    print(
        '[DEBUG] Options menu: isOwnPost=$isOwnPost, isSaved=${_currentPost.isSaved}');

    PostOptionsMenu.show(
      context,
      postUserId: _currentPost.userId,
      currentUserId: _currentUserId,
      isOwnPost: isOwnPost,
      isSaved: _currentPost.isSaved,
      postId: _currentPost.id,
      onSharePost: () {
        // TODO: Implement copy link functionality
      },
      onSavePost: () async {
        await _handleSavePost(_currentPost);
      },
      onUnsavePost: () async {
        await _handleUnsavePost(_currentPost);
      },
      onUnfollow: () {
        // TODO: Implement unfollow functionality
      },
      onReport: () {
        // TODO: Implement report functionality
      },
      onEdit: isOwnPost
          ? () async {
              await _handleEditPost();
            }
          : null,
      onDelete: isOwnPost
          ? () {
              _handleDeletePost();
            }
          : null,
      onHide: isOwnPost
          ? () {
              _handleHidePost();
            }
          : null,
    );
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

  // This method is no longer used - comment handling is done by parent
  Future<void> _handleComment() async {
    // Stub method - actual implementation is in parent widget
    if (widget.onComment != null) {
      widget.onComment!();
    }
  }

  // Old implementation removed - keeping for reference
  Future<void> _handleComment_OLD() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String? currentUserId = authProvider.user?.id;

    // Fallback to SharedPreferences if AuthProvider doesn't have user ID
    if (currentUserId == null) {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');

      final userData = userDataString != null
          ? jsonDecode(userDataString)
          : {'id': '685fb750cc084ba7e0ef8533'};
      currentUserId = userData['id'];
    }

    if (currentUserId == null || currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to comment on posts'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Fetch latest comments from database
    final commentsResult =
        await _thoughtsService.getComments(_currentPost.id, context);
    List<ThoughtsComment> latestComments = _currentPost.comments;

    if (commentsResult['success'] == true && commentsResult['data'] != null) {
      final postData = commentsResult['data'];
      if (postData['comments'] != null) {
        latestComments = (postData['comments'] as List<dynamic>)
            .map((c) => ThoughtsComment.fromJson(c))
            .toList();
      }
    }

    final convertedComments = latestComments.map((thoughtsComment) {
      return data_model.Comment(
        id: thoughtsComment.id,
        userId: thoughtsComment.userId,
        username: thoughtsComment.username,
        text: thoughtsComment.text,
        createdAt: thoughtsComment.createdAt,
        likes: thoughtsComment.likes,
        likedBy: thoughtsComment.likedBy,
      );
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: CommentSection(
          comments: convertedComments,
          onAddComment: (text) async {
            // Get current user info for optimistic update
            final prefs = await SharedPreferences.getInstance();
            final userDataString = prefs.getString('user_data');
            final userData = userDataString != null
                ? jsonDecode(userDataString)
                : {'id': currentUserId, 'name': 'User'};

            // Create optimistic comment
            final optimisticComment = data_model.Comment(
              id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
              userId: currentUserId!,
              username: userData['name'] ?? 'User',
              text: text,
              createdAt: DateTime.now(),
              likes: 0,
              likedBy: [],
            );

            // Add optimistic comment to the list
            final optimisticComments =
                List<data_model.Comment>.from(convertedComments)
                  ..add(optimisticComment);

            // Now add to database in background
            try {
              final result = await _thoughtsService.addComment(
                _currentPost.id,
                currentUserId!,
                text,
                context,
              );

              // Check if success - handle different response formats
              bool isSuccess = false;
              if (result['success'] is bool) {
                isSuccess = result['success'];
              } else if (result['success'] is int) {
                isSuccess = result['success'] == 1;
              } else if (result['success'] is String) {
                isSuccess =
                    result['success'].toString().toLowerCase() == 'true';
              }

              if (isSuccess && result['data'] != null) {
                List<dynamic>? commentsData;

                // Handle different response structures
                if (result['data']['comments'] != null) {
                  commentsData = result['data']['comments'] as List<dynamic>;
                } else if (result['data'] is List) {
                  commentsData = result['data'] as List<dynamic>;
                } else if (result['comments'] != null) {
                  commentsData = result['comments'] as List<dynamic>;
                }

                if (commentsData == null) {
                  throw Exception(
                      'Comments data not found in response: ${result}');
                }

                final updatedComments = commentsData
                    .map((c) => ThoughtsComment.fromJson(c))
                    .toList();

                // Convert to Comment format
                final convertedUpdatedComments =
                    updatedComments.map((thoughtsComment) {
                  return data_model.Comment(
                    id: thoughtsComment.id,
                    userId: thoughtsComment.userId,
                    username: thoughtsComment.username,
                    text: thoughtsComment.text,
                    createdAt: thoughtsComment.createdAt,
                    likes: thoughtsComment.likes,
                    likedBy: thoughtsComment.likedBy,
                  );
                }).toList();

                // Update the post state with real data
                setState(() {
                  _currentPost = ThoughtsPost(
                    id: _currentPost.id,
                    userId: _currentPost.userId,
                    username: _currentPost.username,
                    userImage: _currentPost.userImage,
                    text: _currentPost.text,
                    createdAt: _currentPost.createdAt,
                    updatedAt: _currentPost.updatedAt,
                    likes: _currentPost.likes,
                    likedBy: _currentPost.likedBy,
                    comments: updatedComments,
                    songName: _currentPost.songName,
                    artistName: _currentPost.artistName,
                    coverImage: _currentPost.coverImage,
                    isHidden: _currentPost.isHidden,
                    isDeleted: _currentPost.isDeleted,
                  );
                });

                // Notify parent widget
                widget.onPostUpdated?.call(_currentPost);

                // Comment added successfully - no need to show SnackBar

                return convertedUpdatedComments;
              } else {
                // Database failed, remove optimistic comment
                // Handle error message - it might be a string or array
                String errorMessage = 'Failed to add comment';
                if (result['message'] != null) {
                  if (result['message'] is String) {
                    errorMessage = result['message'];
                  } else if (result['message'] is List) {
                    errorMessage = (result['message'] as List).join(', ');
                  }
                }

                if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: Colors.red,
                  ),
                );
                }

                return convertedComments;
              }
            } catch (e) {
              // Network error, remove optimistic comment
              if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Network error. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );
              }

              return convertedComments;
            }

            return optimisticComments;
          },
          postId: _currentPost.id,
          currentUserId: currentUserId!,
          songPostService: _createSongPostServiceWrapper(),
        ),
      ),
    );
  }

  // Create a wrapper to make ThoughtsService compatible with SongPostService interface
  SongPostService _createSongPostServiceWrapper() {
    return _ThoughtsToSongPostAdapter(_thoughtsService);
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = _extractedColor ?? _defaultColor;
    // Aspect ratio from TMP_des_post_bg_container.dart
    const double postAspectRatio = 372 / 228;

    return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: AspectRatio(
              aspectRatio: postAspectRatio,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Get parent dimensions for responsive sizing
            final parentWidth = constraints.maxWidth;
            final parentHeight = constraints.maxHeight;

            return Stack(
                fit: StackFit.expand,
                children: [
                  // Background layer with custom shape
                  CustomPaint(
                    painter: PostShape(backgroundColor: backgroundColor),
                    child: Container(),
                  ),
                // Content layer with responsive dimensions
                _ThoughtsContent(
                      post: _currentPost,
                      onUserTap: widget.onUserTap,
                      backgroundColor: _extractedColor ?? _defaultColor,
                      onPlayPause: widget.onPlayPause,
                  onOptionsTap: widget.onOptionsTap ?? _handleOptionsTap,
                      isPlaying: widget.isPlaying,
                      isCurrentTrack: widget.isCurrentTrack,
                  onLike: widget.onLike,
                  onComment: widget.onComment,
                  currentUserId: _currentUserId,
                  parentWidth: parentWidth,
                  parentHeight: parentHeight,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleSavePost(ThoughtsPost post) async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in to save posts'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      print('[DEBUG] Save: userId=$_currentUserId, postId=${post.id}');
      final result = await _thoughtsService.savePost(_currentUserId!, post.id);
      print('[DEBUG] Save result: $result');
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Thoughts post saved successfully'),
            backgroundColor: AppColors.primaryPurple,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 2),
          ),
        );
        // Update the post's saved status
        setState(() {
          _currentPost = ThoughtsPost(
            id: _currentPost.id,
            userId: _currentPost.userId,
            username: _currentPost.username,
            userImage: _currentPost.userImage,
            text: _currentPost.text,
            createdAt: _currentPost.createdAt,
            updatedAt: _currentPost.updatedAt,
            likes: _currentPost.likes,
            likedBy: _currentPost.likedBy,
            comments: _currentPost.comments,
            songName: _currentPost.songName,
            artistName: _currentPost.artistName,
            coverImage: _currentPost.coverImage,
            backgroundColor: _currentPost.backgroundColor,
            isHidden: _currentPost.isHidden,
            isDeleted: _currentPost.isDeleted,
            isSaved: true,
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to save thoughts post'),
            backgroundColor: AppColors.primaryPurple,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving thoughts post: $e'),
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

  Future<void> _handleUnsavePost(ThoughtsPost post) async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in to unsave posts'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      print('[DEBUG] Unsave: userId=$_currentUserId, postId=${post.id}');
      final result =
          await _thoughtsService.unsavePost(_currentUserId!, post.id);
      print('[DEBUG] Unsave result: $result');
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Thoughts post unsaved successfully'),
            backgroundColor: AppColors.primaryPurple,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 2),
          ),
        );
        // Update the post's saved status
        setState(() {
          _currentPost = ThoughtsPost(
            id: _currentPost.id,
            userId: _currentPost.userId,
            username: _currentPost.username,
            userImage: _currentPost.userImage,
            text: _currentPost.text,
            createdAt: _currentPost.createdAt,
            updatedAt: _currentPost.updatedAt,
            likes: _currentPost.likes,
            likedBy: _currentPost.likedBy,
            comments: _currentPost.comments,
            songName: _currentPost.songName,
            artistName: _currentPost.artistName,
            coverImage: _currentPost.coverImage,
            backgroundColor: _currentPost.backgroundColor,
            isHidden: _currentPost.isHidden,
            isDeleted: _currentPost.isDeleted,
            isSaved: false,
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(result['message'] ?? 'Failed to unsave thoughts post'),
            backgroundColor: AppColors.primaryPurple,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error unsaving thoughts post: $e'),
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

  Future<void> _handleDeletePost() async {
    if (_currentUserId == null) {
      _showMessage('Please log in to delete posts', Colors.orange);
      return;
    }

    bool? shouldDelete = await _showDeleteDialog();
    if (shouldDelete != true) return;

    try {
      final result =
          await _thoughtsService.deletePost(_currentPost.id, context);

      if (result['success'] == true) {
        // Success - remove post from screen
        _showMessage('Post deleted successfully', AppColors.primaryPurple);

        // Debug logging
        //print('[DEBUG] DeleteThoughts: Post deleted successfully, calling onPostUpdated');
        //print('[DEBUG] DeleteThoughts: onPostUpdated callback exists: ${widget.onPostUpdated != null}');
        //print('[DEBUG] DeleteThoughts: Post ID: ${_currentPost.id}');

        widget.onPostUpdated?.call(_currentPost);
      } else {
        _showMessage(result['message'] ?? 'Failed to delete post', Colors.red);
      }
    } catch (e) {
      _showMessage('Error: $e', Colors.red);
    }
  }

  void _showMessage(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<bool?> _showDeleteDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Future<void> _handleEditPost() async {
    if (_currentUserId == null) {
      _showMessage('Please log in to edit posts', Colors.orange);
      return;
    }

    // Navigate to edit screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditThoughtsPostScreen(post: _currentPost),
      ),
    );

    if (result == true) {
      try {
        final updatedPostData =
            await _thoughtsService.getPostById(_currentPost.id);
        if (updatedPostData['success'] == true &&
            updatedPostData['data'] != null) {
          setState(() {
            _currentPost = ThoughtsPost.fromJson(updatedPostData['data']);
          });
        }
      } catch (e) {
        _showMessage('Error refreshing post: $e', Colors.red);
      }
    }
  }

  Future<void> _handleHidePost() async {
    if (_currentUserId == null) {
      _showMessage('Please log in to hide posts', Colors.orange);
      return;
    }

    bool? shouldHide = await _showHideDialog();
    if (shouldHide != true) return;

    try {
      final result = await _thoughtsService.hidePost(_currentPost.id);

      if (result['success'] == true) {
        _showMessage('Post hidden successfully', AppColors.primaryPurple);

        widget.onPostUpdated?.call(_currentPost);
      } else {
        _showMessage(result['message'] ?? 'Failed to hide post', Colors.red);
      }
    } catch (e) {
      _showMessage('Error: $e', Colors.red);
    }
  }

  Future<bool?> _showHideDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hide Post'),
        content: const Text('Are you sure you want to hide this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.purple),
            child: const Text('Hide'),
          ),
        ],
      ),
    );
  }
}

// ================= _ThoughtsContent =================
class _ThoughtsContent extends StatelessWidget {
  final ThoughtsPost post;
  final void Function(String userId, String? username)? onUserTap;
  final Color backgroundColor;
  final VoidCallback? onPlayPause;
  final VoidCallback? onOptionsTap;
  final bool isPlaying;
  final bool isCurrentTrack;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final String? currentUserId;
  final double parentWidth;
  final double parentHeight;

  const _ThoughtsContent({
    required this.post,
    this.onUserTap,
    required this.backgroundColor,
    this.onPlayPause,
    this.onOptionsTap,
    this.isPlaying = false,
    this.isCurrentTrack = false,
    this.onLike,
    this.onComment,
    this.currentUserId,
    required this.parentWidth,
    required this.parentHeight,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate responsive dimensions based on parent size
    final headerHeight = parentHeight * 0.18; // 18% of parent height
    final footerHeight = parentHeight * 0.22; // 22% of parent height
    final spacingBetween = parentHeight * 0.03; // 2% for spacing

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: headerHeight,
          child: _ThoughtsHeader(
          post: post,
          onUserTap: onUserTap,
          onPlayPause: onPlayPause,
            onOptionsTap: onOptionsTap,
          isPlaying: isPlaying,
          isCurrentTrack: isCurrentTrack,
            currentUserId: currentUserId,
            parentWidth: parentWidth,
            parentHeight: parentHeight,
        ),
        ),
        SizedBox(height: spacingBetween),
        Expanded(
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: parentHeight * 0.004),
            child: _ThoughtsBody(
              post: post,
              backgroundColor: backgroundColor,
              parentWidth: parentWidth,
              parentHeight: parentHeight,
            ),
          ),
        ),
        SizedBox(height: parentHeight * 0.035),
        // Footer section matching post.dart structure
        SizedBox(
          height: footerHeight,
          child: Row(
            children: [
              _SongInfoSection(
                post: post,
                parentWidth: parentWidth,
                parentHeight: parentHeight,
              ),
              _InteractionButtons(
                post: post,
                onLike: onLike,
                onComment: onComment,
                parentWidth: parentWidth,
                parentHeight: parentHeight,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ================= _ThoughtsHeader =================
class _ThoughtsHeader extends StatelessWidget {
  final ThoughtsPost post;
  final void Function(String userId, String? username)? onUserTap;
  final VoidCallback? onPlayPause;
  final VoidCallback? onOptionsTap;
  final bool isPlaying;
  final bool isCurrentTrack;
  final String? currentUserId;
  final double parentWidth;
  final double parentHeight;

  const _ThoughtsHeader({
    required this.post,
    this.onUserTap,
    this.onPlayPause,
    this.onOptionsTap,
    this.isPlaying = false,
    this.isCurrentTrack = false,
    this.currentUserId,
    required this.parentWidth,
    required this.parentHeight,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate responsive dimensions
    final iconSize = (parentHeight * 0.096).clamp(20.0, 24.0);
    final spacing = parentWidth * 0.032;

    return Container(
      margin: const EdgeInsets.only(left: 0, bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          // User Image - taking maximum height possible
          Padding(
            padding: EdgeInsets.only(bottom: parentHeight * 0.02),
            child: AspectRatio(
              aspectRatio: 1,
              child: GestureDetector(
                onTap: () => onUserTap?.call(post.userId, post.username),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(16.0),
              image: post.userImage != null && post.userImage!.isNotEmpty
                  ? DecorationImage(
                      image: post.userImage!.startsWith('http')
                          ? NetworkImage(post.userImage!) as ImageProvider
                          : AssetImage(post.userImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: post.userImage == null || post.userImage!.isEmpty
                ? Center(
                    child: Text(
                      post.username != null && post.username!.isNotEmpty
                          ? post.username![0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                  )
                : null,
          ),
        ),
            ),
          ),
          SizedBox(width: spacing),
          // Username in AutoSizeText
        Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: parentHeight * 0.02),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => onUserTap?.call(post.userId, post.username),
                  child: AutoSizeText(
                    post.username ?? 'Unknown User',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : Colors.black87,
              fontWeight: FontWeight.w600,
                      fontSize: 18,
                      letterSpacing: 0.2,
                    ),
                    minFontSize: 14,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
            ),
          ),
          // Push options icon to the far right
          SizedBox(width: spacing * 0.67),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onOptionsTap,
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: spacing * 0.67),
                child: Icon(
                  Icons.more_vert,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : Colors.black87,
                  size: iconSize * 0.92,
                ),
            ),
          ),
        ),
        // Add Spotify controls if song information is available
        if (post.songName != null && post.songName!.isNotEmpty)
          _ThoughtsSpotifyControl(
            post: post,
            onPlayPause: onPlayPause,
            isPlaying: isPlaying,
            isCurrentTrack: isCurrentTrack,
              parentWidth: parentWidth,
              parentHeight: parentHeight,
          ),
      ],
      ),
    );
  }
}

// ================= _ThoughtsBody =================
class _ThoughtsBody extends StatelessWidget {
  final ThoughtsPost post;
  final Color backgroundColor;
  final double parentWidth;
  final double parentHeight;

  const _ThoughtsBody({
    required this.post,
    required this.backgroundColor,
    required this.parentWidth,
    required this.parentHeight,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate responsive dimensions
    final coverImageWidth = parentWidth * 0.32; // 32% of parent width
    final coverImageHeight = parentHeight * 0.35; // 35% of parent height
    final imageMargin = parentWidth * 0.024;
    final imageBorderRadius = (parentHeight * 0.035).clamp(6.0, 10.0);
    final spacing = parentWidth * 0.012;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left side - Cover image (matching song post style)
        if (post.coverImage != null && post.coverImage!.isNotEmpty) ...[
          Container(
            margin: EdgeInsets.only(
              left: imageMargin,
              right: imageMargin,
              top: 0.0,
              bottom: parentHeight * 0.018,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(imageBorderRadius),
              child: Image.network(
                post.coverImage!,
                width: coverImageWidth,
                height: coverImageHeight,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: coverImageWidth,
                  height: coverImageHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A3B8A),
                    borderRadius: BorderRadius.circular(imageBorderRadius),
                  ),
                  child: Icon(
                    Icons.music_note,
                    color: Colors.white,
                    size: (parentHeight * 0.13).clamp(25.0, 35.0),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: spacing),
        ],
        // Right side - Text content with overflow handling
        Expanded(
          child: _ThoughtsTextContent(
            post: post,
            backgroundColor: backgroundColor,
            parentWidth: parentWidth,
            parentHeight: parentHeight,
          ),
        ),
      ],
    );
  }
}

// ================= _FullContentBottomSheet =================
class _FullContentBottomSheet extends StatelessWidget {
  final ThoughtsPost post;
  final Color backgroundColor;

  const _FullContentBottomSheet({
    required this.post,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            backgroundColor,
            backgroundColor.withOpacity(1),
            backgroundColor.withOpacity(0.9),
            backgroundColor.withOpacity(0.8),
            backgroundColor.withOpacity(0.7),
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover image if available
                  if (post.coverImage != null &&
                      post.coverImage!.isNotEmpty) ...[
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          post.coverImage!,
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A3B8A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.white,
                              size: 45,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Full text content
                  Text(
                    post.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.justify,
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

// ================= _ThoughtsTextContent =================
class _ThoughtsTextContent extends StatefulWidget {
  final ThoughtsPost post;
  final Color backgroundColor;
  final double parentWidth;
  final double parentHeight;

  const _ThoughtsTextContent({
    required this.post,
    required this.backgroundColor,
    required this.parentWidth,
    required this.parentHeight,
  });

  @override
  State<_ThoughtsTextContent> createState() => _ThoughtsTextContentState();
}

class _ThoughtsTextContentState extends State<_ThoughtsTextContent> {
  void _showFullContentBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _FullContentBottomSheet(
          post: widget.post,
          backgroundColor: widget.backgroundColor,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate responsive font sizes and spacing
    final textFontSize = (widget.parentHeight * 0.061).clamp(12.0, 16.0);
    final seeMoreFontSize = (widget.parentHeight * 0.053).clamp(10.0, 13.0);
    final seeMoreSpacing = widget.parentHeight * 0.018;
    final topPadding = widget.parentHeight * 0.04;
    final rightPadding = widget.parentHeight * 0.06;

    return Padding(
      padding: EdgeInsets.only(top: topPadding, right: rightPadding),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.post.text,
                    style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white 
                        : Colors.black87,
                      fontSize: textFontSize,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                ),
              ),
              if (widget.post.text.length > 200) ...[
                  SizedBox(height: seeMoreSpacing),
                GestureDetector(
                  onTap: _showFullContentBottomSheet,
                    child: Text(
                    'see more',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white70 
                          : Colors.black54,
                        fontSize: seeMoreFontSize,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
      ),
    );
  }
}

// ================= _SongInfoSection =================
class _SongInfoSection extends StatelessWidget {
  final ThoughtsPost post;
  final double parentWidth;
  final double parentHeight;

  const _SongInfoSection({
    required this.post,
    required this.parentWidth,
    required this.parentHeight,
  });

  @override
  Widget build(BuildContext context) {
    // Always use white for song/artist, white70 for caption
    final textColor = Colors.white;

    // Calculate responsive padding
    final horizontalPadding = parentWidth * 0.032;
    final verticalPadding = parentHeight * 0.026;

    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post.songName != null && post.songName!.isNotEmpty)
              AutoSizeText(
                post.songName ?? 'Unknown Track',
                style: TextStyle(
                  color: textColor,
                    fontSize: 12,
                  fontWeight: FontWeight.w600,
                  ),
                minFontSize: 8,
                maxFontSize: 14,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
                ),
              if (post.artistName != null && post.artistName!.isNotEmpty)
              AutoSizeText(
                post.artistName != null
                    ? (post.artistName!.length > 20
                        ? '${post.artistName!.substring(0, 20)}...'
                        : post.artistName!)
                    : 'Unknown Artist',
                style: TextStyle(
                  color: textColor.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
                minFontSize: 8,
                maxFontSize: 13,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
                ),
            ],
          ),
      ),
    );
  }
}

// ================= _InteractionButtons =================
class _InteractionButtons extends StatefulWidget {
  final ThoughtsPost post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final double parentWidth;
  final double parentHeight;

  const _InteractionButtons({
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
    required this.parentWidth,
    required this.parentHeight,
  });

  @override
  State<_InteractionButtons> createState() => _InteractionButtonsState();
}

class _InteractionButtonsState extends State<_InteractionButtons> {
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    // Get current user ID to check if they liked the post
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String? userId = authProvider.user?.id;

    // Fallback to SharedPreferences if AuthProvider doesn't have user ID
    if (userId == null || userId.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      final userData =
          userDataString != null ? jsonDecode(userDataString) : {'id': ''};
      userId = userData['id'];
    }

    if (mounted) {
      setState(() {
        currentUserId = userId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLiked =
        currentUserId != null && widget.post.likedBy.contains(currentUserId!);
    final iconColor = Colors.white;
    final likedColor = const Color(0xFFd535f9);

    // Match spacing from post.dart InteractionWidget
    final spacing = (widget.parentWidth * 0.02).clamp(6.0, 20.0);
    final paddingTop = widget.parentHeight * 0.026;
    final paddingBottom = widget.parentHeight * 0.0;
    final paddingLeft = widget.parentWidth * 0.022;
    final paddingRight = widget.parentWidth * 0.018;

    return Container(
      padding: EdgeInsets.only(
        top: paddingTop,
        bottom: paddingBottom,
        left: paddingLeft,
        right: paddingRight,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
      children: [
        // Like button
        GestureDetector(
          onTap: widget.onLike,
          child: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? likedColor : iconColor,
            size: 24,
          ),
        ),
          SizedBox(width: spacing),
        // Comment button
        GestureDetector(
          onTap: widget.onComment,
          child: Icon(
            LucideIcons.messageCircle,
              color: iconColor,
            size: 22,
          ),
        ),
          SizedBox(width: spacing),
        // Share button
          GestureDetector(
            onTap: widget.onShare,
            child: Icon(
          LucideIcons.share2,
              color: iconColor,
          size: 22,
        ),
          ),
          SizedBox(width: spacing),
      ],
      ),
    );
  }
}

// ================= _ThoughtsSpotifyControl =================
class _ThoughtsSpotifyControl extends StatelessWidget {
  final ThoughtsPost post;
  final VoidCallback? onPlayPause;
  final bool isPlaying;
  final bool isCurrentTrack;
  final double parentWidth;
  final double parentHeight;

  const _ThoughtsSpotifyControl({
    required this.post,
    this.onPlayPause,
    this.isPlaying = false,
    this.isCurrentTrack = false,
    required this.parentWidth,
    required this.parentHeight,
  });

  @override
  Widget build(BuildContext context) {
    print(
        '[DEBUG] _ThoughtsSpotifyControl build: onPlayPause is null? ${onPlayPause == null}');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillColor = isDark ? Colors.black : Colors.white;
    final iconColor = isDark ? Colors.white : Colors.black;
    final spotifyAsset = isDark
        ? 'assets/icons/icons-spotify-dark.svg'
        : 'assets/icons/icons-spotify-light.svg';

    // Calculate responsive dimensions
    final pillHeight = (parentHeight * 0.14).clamp(28.0, 36.0);
    final pillBorderRadius = (parentHeight * 0.061).clamp(12.0, 16.0);
    final horizontalPadding = parentWidth * 0.032;
    final verticalPadding = parentHeight * 0.026;
    final iconSize = (parentHeight * 0.079).clamp(16.0, 20.0);
    final spotifyIconSize = (parentHeight * 0.079).clamp(16.0, 20.0);
    final spacing = parentWidth * 0.076;

    return Container(
      margin: EdgeInsets.only(
        right: parentWidth * 0.018,
        top: parentHeight * 0.028,
      ),
      child: Container(
        height: pillHeight,
        decoration: BoxDecoration(
          color: pillColor,
          borderRadius: BorderRadius.circular(pillBorderRadius),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: spotifyIconSize,
              height: spotifyIconSize,
              child: SvgPicture.asset(
                spotifyAsset,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(width: spacing),
            GestureDetector(
              onTap: () {
                if (onPlayPause != null) {
                  onPlayPause!();
                }
              },
              child: Icon(
                isCurrentTrack && isPlaying
                    ? LucideIcons.pause
                    : LucideIcons.play,
                color: iconColor,
                size: iconSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Adapter class to make ThoughtsService compatible with SongPostService
class _ThoughtsToSongPostAdapter extends SongPostService {
  final ThoughtsService _thoughtsService;

  _ThoughtsToSongPostAdapter(this._thoughtsService);

  @override
  Future<Map<String, dynamic>> likeComment(
      String postId, String commentId, String userId,
      [BuildContext? context]) async {
    return await _thoughtsService.likeComment(
        postId, commentId, userId, context);
  }
}