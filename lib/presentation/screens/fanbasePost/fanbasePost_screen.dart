import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert'; // ✅ Add this import
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ Add this import
import '../../../data/services/fanbase_post_service.dart';
import '../../../data/services/auth_service.dart';
import 'fanbasePost_screen_comments.dart';
import 'fanbasePost_screen_songControl.dart';
import 'package:dio/dio.dart';

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

  // User identification for permissions
  final String? postCreatorId; // ✅ Add post creator ID
  final String? fanbaseOwnerId; // ✅ Add fanbase owner ID

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
    this.postCreatorId, // ✅ Add to constructor
    this.fanbaseOwnerId, // ✅ Add to constructor
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

  // Add these state variables for music playback
  String? _currentlyPlayingTrackId;
  bool _isPlaying = false;
  String? _currentUserId; // ✅ Add current user ID

  @override
  void initState() {
    super.initState();
    _comments = List.from(widget.comments);
    // Initialize playback state based on widget properties
    _currentlyPlayingTrackId = widget.isPlaying ? widget.trackId : null;
    _isPlaying = widget.isPlaying && widget.isCurrentTrack;
    _loadCurrentUserId(); // ✅ Load current user ID

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  // ✅ Update method to use SharedPreferences
  Future<void> _loadCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        if (mounted) {
          setState(() {
            _currentUserId = userData['id'];
          });
          print('[DEBUG] Current user ID loaded: $_currentUserId');
        }
      }
    } catch (e) {
      print('[ERROR] Failed to load current user ID: $e');
    }
  }

  /// Refreshes the page by fetching updated post data
  Future<void> _refreshPost() async {
    try {
      final updatedPost = await FanbasePostService.getFanbasePost(
        widget.postId,
        context,
        fanbaseId: widget.fanbaseId,
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

  /// Handles play/pause button press
  Future<void> _handlePlayPause() async {
    if (widget.trackId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No track available for this post'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // If this track is currently playing, pause it
    if (_currentlyPlayingTrackId == widget.trackId && _isPlaying) {
      // Optimistically update UI
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
      try {
        await _pausePlayback();
        // Success - state already updated
      } catch (e) {
        // Only show error and revert state if there's an actual error
        // print('[ERROR] Failed to pause: $e');
        if (mounted) {
          setState(() {
            _isPlaying = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Failed to pause: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Optimistically update UI
      if (mounted) {
        setState(() {
          _currentlyPlayingTrackId = widget.trackId;
          _isPlaying = true;
        });
      }

      try {
        await _playTrack();
        // Success - state already updated, no need to show message
      } catch (e) {
        // Only show error and revert state if there's an actual error
        // print('[ERROR] Failed to play: $e');
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _currentlyPlayingTrackId = null;
          });

          String errorMessage = 'Failed to play track';
          String errorStr = e.toString();

          if (errorStr.contains('401') || errorStr.contains('Unauthorized')) {
            errorMessage = 'Please connect your Spotify account';
          } else if (errorStr.contains('404')) {
            errorMessage = 'Track not found';
          } else if (errorStr.contains('403')) {
            errorMessage = 'Playback restricted';
          } else {
            // Remove "Exception: " prefix for cleaner message
            errorMessage = errorStr
                .replaceAll('Exception: ', '')
                .replaceAll('Failed to play track: ', '');
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  /// Plays the track using Spotify API
  Future<void> _playTrack() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;

      // print('[DEBUG] Attempting to play track: ${widget.trackId}');

      final response = await dio.post(
        '/spotify/player/post/play',
        data: {'track_id': widget.trackId},
      );

      // print('[DEBUG] Play response status: ${response.statusCode}');
      // print('[DEBUG] Play response data: ${response.data}');

      // Accept any 2xx status code as success
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        // print('[DEBUG] Track started playing successfully');
        // State is already updated optimistically in _handlePlayPause
        return; // Exit successfully
      } else {
        // This should rarely happen
        throw Exception('Unexpected status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      // print('[ERROR] DioException in _playTrack:');
      // print('[ERROR] - Message: ${e.message}');
      // print('[ERROR] - Type: ${e.type}');
      // print('[ERROR] - Response status: ${e.response?.statusCode}');
      // print('[ERROR] - Response data: ${e.response?.data}');

      // Check if it's actually a success that Dio is treating as an error
      if (e.response?.statusCode != null &&
          e.response!.statusCode! >= 200 &&
          e.response!.statusCode! < 300) {
        // print('[DEBUG] Response was actually successful despite DioException');
        return; // It's actually success
      }

      String errorMsg = 'Failed to play track';
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data['message'] != null) {
          errorMsg = data['message'].toString();
        } else if (data is String && data.isNotEmpty) {
          errorMsg = data;
        }
      } else if (e.message != null && e.message!.isNotEmpty) {
        errorMsg = e.message!;
      }

      throw Exception(errorMsg);
    } catch (e) {
      // print('[ERROR] Unexpected error in _playTrack: $e');
      throw Exception('Playback error: ${e.toString()}');
    }
  }

  /// Pauses Spotify playback
  Future<void> _pausePlayback() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;

      // print('[DEBUG] Attempting to pause playback');

      final response = await dio.put('/spotify/player/post/pause');

      // print('[DEBUG] Pause response status: ${response.statusCode}');

      // Accept any 2xx status code as success
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        // print('[DEBUG] Playback paused successfully');
        // State is already updated optimistically in _handlePlayPause
        return; // Exit successfully
      } else {
        throw Exception('Unexpected status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      // print('[ERROR] DioException in _pausePlayback:');
      // print('[ERROR] - Message: ${e.message}');
      // print('[ERROR] - Type: ${e.type}');
      // print('[ERROR] - Response status: ${e.response?.statusCode}');
      // print('[ERROR] - Response data: ${e.response?.data}');

      // Check if it's actually a success that Dio is treating as an error
      if (e.response?.statusCode != null &&
          e.response!.statusCode! >= 200 &&
          e.response!.statusCode! < 300) {
        // print('[DEBUG] Response was actually successful despite DioException');
        return; // It's actually success
      }

      String errorMsg = 'Failed to pause playback';
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data['message'] != null) {
          errorMsg = data['message'].toString();
        } else if (data is String && data.isNotEmpty) {
          errorMsg = data;
        }
      }

      throw Exception(errorMsg);
    } catch (e) {
      // print('[ERROR] Unexpected error in _pausePlayback: $e');
      throw Exception('Pause error: ${e.toString()}');
    }
  }

  /// Handles opening Spotify (could open app or web player)
  void _handleSpotifyTap() {
    // TODO: Implement opening Spotify with the track
    // You could use url_launcher package to open spotify:track:{trackId}
    // print('Opening Spotify for track: ${widget.trackId}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening in Spotify...'),
        duration: Duration(seconds: 1),
      ),
    );
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
              bottom: bottomPadding,
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
                  currentUserId: _currentUserId, // ✅ Pass current user ID
                  postCreatorId: widget.postCreatorId, // ✅ Pass post creator ID
                  fanbaseOwnerId:
                      widget.fanbaseOwnerId, // ✅ Pass fanbase owner ID
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
          // Use the CompactSongControlWidget with actual functionality
          CompactSongControlWidget(
            trackId: widget.trackId,
            isPlaying: _isPlaying,
            isCurrentTrack: _currentlyPlayingTrackId == widget.trackId,
            onPlayPause: _handlePlayPause,
            onSpotifyTap: _handleSpotifyTap,
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
