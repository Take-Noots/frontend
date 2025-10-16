import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import '../../../data/models/thoughts_model.dart';
import '../../../data/services/thoughts_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/spotify_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../despost/widgets/TMP_des_post_bg_container.dart';
import '../song_post/comment.dart';
import '../../../data/models/post_model.dart' as data_model;
import '../../../data/services/song_post_service.dart';

class ThoughtsFeedCard extends StatefulWidget {
  final ThoughtsPost post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final void Function(String userId)? onUserTap;
  final Function(ThoughtsPost)? onPostUpdated;
  final VoidCallback? onPlayPause;
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

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
    print('[DEBUG] ThoughtsFeedCard.initState: post id: ${widget.post.id}');
    print(
        '[DEBUG] ThoughtsFeedCard.initState: songName: ${widget.post.songName}');
    print(
        '[DEBUG] ThoughtsFeedCard.initState: artistName: ${widget.post.artistName}');
    print(
        '[DEBUG] ThoughtsFeedCard.initState: onPlayPause is null? ${widget.onPlayPause == null}');
    print(
        '[DEBUG] ThoughtsFeedCard.initState: isPlaying: ${widget.isPlaying}, isCurrentTrack: ${widget.isCurrentTrack}');
    _extractColorFromCoverImage();
  }

  Future<void> _extractColorFromCoverImage() async {
    if (widget.post.coverImage != null && widget.post.coverImage!.isNotEmpty) {
      try {
        final PaletteGenerator paletteGenerator =
            await PaletteGenerator.fromImageProvider(
          NetworkImage(widget.post.coverImage!),
          size: const Size(100, 100),
          maximumColorCount: 10,
        );

        Color? extractedColor = paletteGenerator.darkMutedColor?.color ??
            paletteGenerator.darkVibrantColor?.color ??
            paletteGenerator.dominantColor?.color;

        if (extractedColor != null) {
          setState(() {
            _extractedColor = _isDarkEnough(extractedColor)
                ? extractedColor
                : _darkenColor(extractedColor);
          });
        }
      } catch (e) {
        print('Error extracting color: $e');
      }
    }
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

  Future<void> _handleLike() async {
    // Get current user ID - try AuthProvider first, then SharedPreferences as fallback
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String? currentUserId = authProvider.user?.id;

    print(
        '[DEBUG] ThoughtsFeedCard._handleLike: AuthProvider currentUserId = $currentUserId');
    print(
        '[DEBUG] ThoughtsFeedCard._handleLike: authProvider.user = ${authProvider.user}');
    print(
        '[DEBUG] ThoughtsFeedCard._handleLike: authProvider.isAuthenticated = ${authProvider.isAuthenticated}');

    // Fallback to SharedPreferences if AuthProvider doesn't have user ID
    if (currentUserId == null) {
      print(
          '[DEBUG] ThoughtsFeedCard._handleLike: AuthProvider user ID is null, trying SharedPreferences');
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      final userData = userDataString != null
          ? jsonDecode(userDataString)
          : {'id': '685fb750cc084ba7e0ef8533'}; // Fallback for testing
      currentUserId = userData['id'];
      print(
          '[DEBUG] ThoughtsFeedCard._handleLike: SharedPreferences currentUserId = $currentUserId');
    }

    if (currentUserId == null || currentUserId.isEmpty) {
      print(
          '[DEBUG] ThoughtsFeedCard._handleLike: User ID is still null, showing login message');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to like posts'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Store original post for potential rollback
    final originalPost = _currentPost;

    // Check if already liked
    final isCurrentlyLiked = _currentPost.likedBy.contains(currentUserId);
    print(
        '[DEBUG] ThoughtsFeedCard._handleLike: isCurrentlyLiked = $isCurrentlyLiked');
    print(
        '[DEBUG] ThoughtsFeedCard._handleLike: current likedBy = ${_currentPost.likedBy}');

    // Optimistic update - update UI immediately
    setState(() {
      if (isCurrentlyLiked) {
        // Unlike - remove from likedBy list
        final newLikedBy = List<String>.from(_currentPost.likedBy);
        newLikedBy.remove(currentUserId!);
        _currentPost = ThoughtsPost(
          id: _currentPost.id,
          userId: _currentPost.userId,
          username: _currentPost.username,
          userImage: _currentPost.userImage,
          text: _currentPost.text,
          createdAt: _currentPost.createdAt,
          updatedAt: _currentPost.updatedAt,
          likes: _currentPost.likes - 1,
          likedBy: newLikedBy,
          comments: _currentPost.comments,
          songName: _currentPost.songName,
          artistName: _currentPost.artistName,
          coverImage: _currentPost.coverImage,
          isHidden: _currentPost.isHidden,
          isDeleted: _currentPost.isDeleted,
        );
      } else {
        // Like - add to likedBy list
        final newLikedBy = List<String>.from(_currentPost.likedBy);
        newLikedBy.add(currentUserId!);
        _currentPost = ThoughtsPost(
          id: _currentPost.id,
          userId: _currentPost.userId,
          username: _currentPost.username,
          userImage: _currentPost.userImage,
          text: _currentPost.text,
          createdAt: _currentPost.createdAt,
          updatedAt: _currentPost.updatedAt,
          likes: _currentPost.likes + 1,
          likedBy: newLikedBy,
          comments: _currentPost.comments,
          songName: _currentPost.songName,
          artistName: _currentPost.artistName,
          coverImage: _currentPost.coverImage,
          isHidden: _currentPost.isHidden,
          isDeleted: _currentPost.isDeleted,
        );
      }
    });

    try {
      // Call the API
      final result =
          await _thoughtsService.likeThoughts(_currentPost.id, context);

      if (result['success'] == true && result['data'] != null) {
        // Update with server response
        final updatedPost = ThoughtsPost.fromJson(result['data']);
        setState(() {
          _currentPost = updatedPost;
        });

        // Notify parent widget of the update
        widget.onPostUpdated?.call(updatedPost);
      } else {
        // Revert optimistic update on error
        setState(() {
          _currentPost = originalPost;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to like post'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        _currentPost = originalPost;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error liking post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleComment() async {
    // Get current user ID - try AuthProvider first, then SharedPreferences as fallback
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String? currentUserId = authProvider.user?.id;

    print('[DEBUG] _handleComment: AuthProvider user ID: $currentUserId');
    print('[DEBUG] _handleComment: AuthProvider user: ${authProvider.user}');

    // Fallback to SharedPreferences if AuthProvider doesn't have user ID
    if (currentUserId == null) {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      print(
          '[DEBUG] _handleComment: SharedPreferences user_data: $userDataString');

      final userData = userDataString != null
          ? jsonDecode(userDataString)
          : {'id': '685fb750cc084ba7e0ef8533'}; // Fallback for testing
      currentUserId = userData['id'];
      print('[DEBUG] _handleComment: Fallback user ID: $currentUserId');
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
        print('[DEBUG] Fetched latest comments: ${latestComments.length}');
      }
    }

    // Convert ThoughtsComment to Comment format
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: CommentSection(
          comments: convertedComments,
          onAddComment: (text) async {
            print('[DEBUG] Adding comment: $text');
            print('[DEBUG] Post ID: ${_currentPost.id}');
            print('[DEBUG] User ID: $currentUserId');
            print('[DEBUG] Comment text: $text');

            // Get current user info for optimistic update
            final prefs = await SharedPreferences.getInstance();
            final userDataString = prefs.getString('user_data');
            final userData = userDataString != null
                ? jsonDecode(userDataString)
                : {'id': currentUserId, 'name': 'User'};

            // Create optimistic comment (show immediately)
            final optimisticComment = data_model.Comment(
              id: 'temp_${DateTime.now().millisecondsSinceEpoch}', // Temporary ID
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

            print('[DEBUG] Showing optimistic comment immediately');

            // Now add to database in background
            try {
              final result = await _thoughtsService.addComment(
                _currentPost.id,
                currentUserId!,
                text,
                context,
              );

              print('[DEBUG] Comment add result: $result');
              print('[DEBUG] Comment add result type: ${result.runtimeType}');
              print('[DEBUG] Comment add result keys: ${result.keys}');
              print('[DEBUG] Comment add success value: ${result['success']}');
              print('[DEBUG] Comment add data value: ${result['data']}');

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

                print('[DEBUG] Comment successfully added to database');

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Comment added successfully!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );

                return convertedUpdatedComments;
              } else {
                // Database failed, remove optimistic comment
                print('[DEBUG] Database failed, removing optimistic comment');

                // Handle error message - it might be a string or array
                String errorMessage = 'Failed to add comment';
                if (result['message'] != null) {
                  if (result['message'] is String) {
                    errorMessage = result['message'];
                  } else if (result['message'] is List) {
                    errorMessage = (result['message'] as List).join(', ');
                  }
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: Colors.red,
                  ),
                );

                return convertedComments; // Return original comments without optimistic one
              }
            } catch (e) {
              // Network error, remove optimistic comment
              print('[DEBUG] Network error: $e');

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Network error. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );

              return convertedComments; // Return original comments without optimistic one
            }

            // Return optimistic comments for immediate display
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
    const double postAspectRatio = 490 / 350;

    return Stack(
      children: [
        // Main card container
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 350, // Reduced height constraint
            ),
            child: AspectRatio(
              aspectRatio: postAspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background layer with custom shape
                  CustomPaint(
                    painter: PostShape(backgroundColor: backgroundColor),
                    child: Container(),
                  ),
                  // Content layer
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
                    child: _ThoughtsContent(
                      post: _currentPost,
                      onUserTap: widget.onUserTap,
                      backgroundColor: _extractedColor ?? _defaultColor,
                      onPlayPause: widget.onPlayPause,
                      isPlaying: widget.isPlaying,
                      isCurrentTrack: widget.isCurrentTrack,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 10,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Song info on the left
              Expanded(
                child: _SongInfoSection(post: _currentPost),
              ),
              // Interaction buttons on the right
              _InteractionButtons(
                post: _currentPost,
                onLike: _handleLike,
                onComment: _handleComment,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThoughtsContent extends StatelessWidget {
  final ThoughtsPost post;
  final void Function(String userId)? onUserTap;
  final Color backgroundColor;
  final VoidCallback? onPlayPause;
  final bool isPlaying;
  final bool isCurrentTrack;

  const _ThoughtsContent({
    required this.post,
    this.onUserTap,
    required this.backgroundColor,
    this.onPlayPause,
    this.isPlaying = false,
    this.isCurrentTrack = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header section - moved to top with maximized size
        _ThoughtsHeader(
          post: post,
          onUserTap: onUserTap,
          onPlayPause: onPlayPause,
          isPlaying: isPlaying,
          isCurrentTrack: isCurrentTrack,
        ),
        const SizedBox(height: 20),
        // Main content area with left-right layout
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 1),
            child: _ThoughtsBody(
              post: post,
              backgroundColor: backgroundColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ThoughtsHeader extends StatelessWidget {
  final ThoughtsPost post;
  final void Function(String userId)? onUserTap;
  final VoidCallback? onPlayPause;
  final bool isPlaying;
  final bool isCurrentTrack;

  const _ThoughtsHeader({
    required this.post,
    this.onUserTap,
    this.onPlayPause,
    this.isPlaying = false,
    this.isCurrentTrack = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => onUserTap?.call(post.userId),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(20.0),
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
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            post.username ?? 'Unknown',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
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
          ),
      ],
    );
  }
}

class _ThoughtsBody extends StatelessWidget {
  final ThoughtsPost post;
  final Color backgroundColor;

  const _ThoughtsBody({
    required this.post,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left side - Cover image (matching song post style)
        if (post.coverImage != null && post.coverImage!.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(
              left: 9.0,
              right: 9.0,
              top: 0.0,
              bottom: 4.0,
            ),
            height: 25,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                post.coverImage!,
                width: 120,
                height: 25,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 120,
                  height: 25,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A3B8A),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        // Right side - Text content with overflow handling
        Expanded(
          child: _ThoughtsTextContent(
            post: post,
            backgroundColor: backgroundColor,
          ),
        ),
      ],
    );
  }
}

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

class _ThoughtsTextContent extends StatefulWidget {
  final ThoughtsPost post;
  final Color backgroundColor;

  const _ThoughtsTextContent({
    required this.post,
    required this.backgroundColor,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.post.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.justify,
                ),
              ),
              if (widget.post.text.length > 200) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: _showFullContentBottomSheet,
                  child: const Text(
                    'see more',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SongInfoSection extends StatelessWidget {
  final ThoughtsPost post;

  const _SongInfoSection({
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          const Icon(
            Icons.music_note,
            color: Colors.deepPurple,
            size: 14,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post.songName != null && post.songName!.isNotEmpty)
                Text(
                  post.songName!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (post.artistName != null && post.artistName!.isNotEmpty)
                Text(
                  post.artistName!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InteractionButtons extends StatefulWidget {
  final ThoughtsPost post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;

  const _InteractionButtons({
    required this.post,
    this.onLike,
    this.onComment,
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

    print('[DEBUG] _InteractionButtons.build: currentUserId = $currentUserId');
    print('[DEBUG] _InteractionButtons.build: isLiked = $isLiked');
    print(
        '[DEBUG] _InteractionButtons.build: post.likedBy = ${widget.post.likedBy}');

    return Row(
      children: [
        // Like button
        GestureDetector(
          onTap: widget.onLike,
          child: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? Colors.deepPurple : Colors.white,
            size: 24,
          ),
        ),
        SizedBox(
            width: (MediaQuery.of(context).size.width * 0.02).clamp(6.0, 20.0)),
        // Comment button
        GestureDetector(
          onTap: widget.onComment,
          child: Icon(
            LucideIcons.messageCircle,
            color: Colors.white,
            size: 22,
          ),
        ),
        SizedBox(
            width: (MediaQuery.of(context).size.width * 0.02).clamp(6.0, 20.0)),
        // Share button
        Icon(
          LucideIcons.share2,
          color: Colors.white,
          size: 22,
        ),
      ],
    );
  }
}

class _ThoughtsSpotifyControl extends StatelessWidget {
  final ThoughtsPost post;
  final VoidCallback? onPlayPause;
  final bool isPlaying;
  final bool isCurrentTrack;

  const _ThoughtsSpotifyControl({
    required this.post,
    this.onPlayPause,
    this.isPlaying = false,
    this.isCurrentTrack = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillColor = isDark ? Colors.black : Colors.white;
    final iconColor = isDark ? Colors.white : Colors.black;
    final spotifyAsset = isDark
        ? 'assets/icons/icons-spotify-dark.svg'
        : 'assets/icons/icons-spotify-light.svg';

    return Container(
      margin: const EdgeInsets.only(left: 40.0),
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: pillColor,
          borderRadius: BorderRadius.circular(14.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: SvgPicture.asset(
                spotifyAsset,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: () {
                print('[DEBUG] _ThoughtsSpotifyControl: Play button tapped');
                print(
                    '[DEBUG] _ThoughtsSpotifyControl: onPlayPause is null? ${onPlayPause == null}');
                print(
                    '[DEBUG] _ThoughtsSpotifyControl: isPlaying: $isPlaying, isCurrentTrack: $isCurrentTrack');
                if (onPlayPause != null) {
                  onPlayPause!();
                } else {
                  print(
                      '[DEBUG] _ThoughtsSpotifyControl: onPlayPause is null!');
                }
              },
              child: Icon(
                isCurrentTrack && isPlaying
                    ? LucideIcons.pause
                    : LucideIcons.play,
                color: iconColor,
                size: 18,
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
