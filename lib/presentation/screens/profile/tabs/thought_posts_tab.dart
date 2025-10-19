import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../../../data/services/thoughts_service.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/models/thoughts_model.dart';
import '../../../widgets/thoughts/thoughts_feed_card.dart';
import '../../../widgets/loading_screens/common_loading.dart';
import '../thought_feed.dart';

class ThoughtPostsTab extends StatefulWidget {
  final List<dynamic>? postsList;
  final String? userId;

  const ThoughtPostsTab({Key? key, this.postsList, this.userId})
      : super(key: key);

  @override
  State<ThoughtPostsTab> createState() => _ThoughtPostsTabState();
}

class _ThoughtPostsTabState extends State<ThoughtPostsTab> {
  final ThoughtsService _service = ThoughtsService();
  List<ThoughtsPost> _posts = [];
  bool _isLoading = true;
  bool _isPlaying = false;
  String? _currentlyPlayingTrackId;

  @override
  void initState() {
    super.initState();
    print(
        'ThoughtPostsTab: initState called. postsList is ${widget.postsList == null ? 'null' : 'present (${widget.postsList!.length})'}; userId=${widget.userId}');
    if (widget.postsList != null) {
      print(
          'ThoughtPostsTab: inspecting provided postsList sample: ${widget.postsList!.isNotEmpty ? widget.postsList![0].toString() : 'empty list'}');
      // Detect whether the provided postsList contains thought posts
      final containsThoughtLike = widget.postsList!.any((p) {
        if (p is ThoughtsPost) return true;
        if (p is Map<String, dynamic>) {
          return p.containsKey('text') ||
              p.containsKey('thoughtsText') ||
              p.containsKey('comments');
        }
        return false;
      });

      print('ThoughtPostsTab: containsThoughtLike = $containsThoughtLike');
      if (containsThoughtLike) {
        _posts = widget.postsList!
            .map<ThoughtsPost>((p) {
              if (p is ThoughtsPost) return p;
              if (p is Map<String, dynamic>) return ThoughtsPost.fromJson(p);
              return ThoughtsPost.fromJson({});
            })
            .where((p) => p.isHidden == 0 && p.isDeleted == 0)
            .toList();
        print(
            'ThoughtPostsTab: loaded ${_posts.length} thought posts from provided list');
        _isLoading = false;
      } else {
         
          // print(
          //     'ThoughtPostsTab: provided postsList does not contain thought posts; will fetch by userId');
        _fetchPosts();
      }
    } else {
      _fetchPosts();
    }
  }

  Future<void> _fetchPosts() async {
    if (widget.userId == null) {
      print('ThoughtPostsTab: _fetchPosts called but userId is null');
      setState(() => _isLoading = false);
      return;
    }
    try {
      
      var result = await _service.getUserThoughts(widget.userId!, context);
      //print('ThoughtPostsTab: raw getUserThoughts result: $result');
      if (!(result['success'] == true && result['data'] != null)) {
        print('ThoughtPostsTab: getUserThoughts returned no data or failed, falling back to followers endpoint');
        result = await _service.getFollowerThoughts(widget.userId!);
        //print('ThoughtPostsTab: raw getFollowerThoughts result: $result');
      }

      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> data = result['data'];
        //print('ThoughtPostsTab: fetched data length=${data.length}');
        final posts = data
            .map<ThoughtsPost>((json) {
              if (json is ThoughtsPost) return json;
              if (json is Map<String, dynamic>)
                return ThoughtsPost.fromJson(json);
              return ThoughtsPost.fromJson({});
            })
            .where((p) => p.isHidden == 0 && p.isDeleted == 0)
            .toList();
        //print('ThoughtPostsTab: parsed ${posts.length} visible thought posts');
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      print('ThoughtPostsTab: Error fetching thought posts: $e');
    }
    setState(() {
      _posts = [];
      _isLoading = false;
    });
  }

  // Play/pause functionality for thoughts posts with songs
  Future<void> _handlePlay(ThoughtsPost post) async {
    print('[DEBUG] ThoughtPostsTab._handlePlay called for post: ${post.id}');
    print('[DEBUG] ThoughtPostsTab._handlePlay songName: ${post.songName}');
    print('[DEBUG] ThoughtPostsTab._handlePlay trackId: ${post.trackId}');
    
    // Only play if the post has song information and trackId
    if (post.songName == null || post.songName!.isEmpty || post.trackId == null || post.trackId!.isEmpty) {
      print('[DEBUG] ThoughtPostsTab._handlePlay: No song information or trackId, returning early');
      return;
    }

    if (_currentlyPlayingTrackId == post.trackId && _isPlaying) {
      setState(() {
        _isPlaying = false;
      });
      try {
        await _pausePlayback();
      } catch (e) {
        setState(() {
          _isPlaying = true;
        });
      }
    } else {
      setState(() {
        _currentlyPlayingTrackId = post.trackId;
        _isPlaying = true;
      });
      try {
        await _playTrack(post);
      } catch (e) {
        setState(() {
          _isPlaying = false;
          _currentlyPlayingTrackId = null;
        });
      }
    }
  }

  Future<void> _playTrack(ThoughtsPost post) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;
      final response = await dio.post(
        '/spotify/player/post/play',
        data: {'track_id': post.trackId}, 
      );
      if (response.statusCode == 200 ||
          response.statusCode == 202 ||
          response.statusCode == 204) {
        setState(() {
          _currentlyPlayingTrackId = post.trackId;
          _isPlaying = true;
        });
      } else {
        print('[DEBUG] ThoughtPostsTab.PlayTrack: Unexpected status code: ${response.statusCode}');
      }
    } catch (e) {
      print('[DEBUG] ThoughtPostsTab.PlayTrack Error: $e');
      setState(() {
        _isPlaying = false;
        _currentlyPlayingTrackId = null;
      });
    }
  }

  Future<void> _pausePlayback() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;
      final response = await dio.put('/spotify/player/post/pause');
      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _isPlaying = false;
        });
      }
    } catch (e) {
      print('[DEBUG] ThoughtPostsTab.PausePlayback Error: $e');
      setState(() {
        _isPlaying = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return Center(
          child: CommonLoading.purple(message: "Loading thoughts..."));

    if (_posts.isEmpty) {
      print('ThoughtPostsTab: build - no posts to show');
      return Center(
        child: Text('No thought posts',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: _posts.map((post) {
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ThoughtFeedScreen(
                    posts: _posts,
                    userId: widget.userId,
                    initialPostId: post.id,
                    onRefresh: () {
                      
                    },
                  ),
                ),
              ).then((_) {
                _fetchPosts();
              });
            },
            child: Stack(
              children: [
                // The thoughts feed card
                ThoughtsFeedCard(
              post: post,
              showCoverImage: false,
              onLike: () {
                // liking handled elsewhere; left as no-op
              },
              onComment: () {
                // navigate to comment view if desired
              },
                  onPlayPause: () {
                    print('[DEBUG] ThoughtPostsTab: onPlayPause callback called for post: ${post.id}');
                    _handlePlay(post);
                  },
                  isPlaying: _isPlaying && _currentlyPlayingTrackId == post.trackId,
                  isCurrentTrack: _currentlyPlayingTrackId == post.trackId,
                  onPostUpdated: (updatedPost) {
                    _fetchPosts();
                  },
                  onUserTap: (String userId, String? username) {},
                ),
                // Blurred overlay for interaction buttons area
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              (Theme.of(context).brightness == Brightness.dark
                                      ? Colors.black
                                      : Colors.white)
                                  .withOpacity(0.3),
                              (Theme.of(context).brightness == Brightness.dark
                                      ? Colors.black
                                      : Colors.white)
                                  .withOpacity(0.6),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.black.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.touch_app_rounded,
                                  size: 16,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '',
                                  style: TextStyle(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
