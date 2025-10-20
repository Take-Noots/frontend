import 'package:flutter/material.dart';
import '../../../../data/services/thoughts_service.dart';
import '../../../../data/models/thoughts_model.dart';
import '../../../widgets/loading_screens/profile_grid_skeleton.dart';
import '../thought_feed.dart';

class ThoughtPostsTab extends StatefulWidget {
  final List<dynamic>? postsList;
  final String? userId;
  final ValueNotifier<bool>? refreshNotifier;

  const ThoughtPostsTab(
      {Key? key, this.postsList, this.userId, this.refreshNotifier})
      : super(key: key);

  @override
  State<ThoughtPostsTab> createState() => _ThoughtPostsTabState();
}

class _ThoughtPostsTabState extends State<ThoughtPostsTab> {
  final ThoughtsService _service = ThoughtsService();
  List<ThoughtsPost> _posts = [];
  bool _isLoading = true;

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
    widget.refreshNotifier?.addListener(_onRefresh);
  }

  @override
  void dispose() {
    widget.refreshNotifier?.removeListener(_onRefresh);
    // Cancel any ongoing operations
    _isLoading = false;
    super.dispose();
  }

  void _onRefresh() {
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    if (widget.userId == null) {
      print('ThoughtPostsTab: _fetchPosts called but userId is null');
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }
    try {
      var result = await _service.getUserThoughts(widget.userId!, context);
      if (!mounted) return; // Check after async call

      //print('ThoughtPostsTab: raw getUserThoughts result: $result');
      if (!(result['success'] == true && result['data'] != null)) {
        print(
            'ThoughtPostsTab: getUserThoughts returned no data or failed, falling back to followers endpoint');
        result = await _service.getFollowerThoughts(widget.userId!);
        if (!mounted) return; // Check after async call
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
        if (!mounted) return;
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      print('ThoughtPostsTab: Error fetching thought posts: $e');
    }
    if (!mounted) return;
    setState(() {
      _posts = [];
      _isLoading = false;
    });
  }

  // Helper to build a colored background for thought posts when there's no cover image.
  Widget _buildThoughtsColorBackground(ThoughtsPost thought, ThemeData theme) {
    Color backgroundColor = const Color(0xFF2D1B69); // Default purple
    if (thought.backgroundColor != null) {
      try {
        backgroundColor = Color(
            int.parse(thought.backgroundColor!.replaceFirst('#', '0xFF')));
      } catch (e) {
        // Use default color if parsing fails
      }
    }

    return Container(
      color: backgroundColor,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            thought.text.length > 50
                ? '${thought.text.substring(0, 50)}...'
                : thought.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const ProfileGridSkeleton();

    if (_posts.isEmpty) {
      print('ThoughtPostsTab: build - no posts to show');
      return Center(
        child: Text('No thought posts',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      );
    }

    // Show thought posts in a 3-column grid similar to saved_posts.dart
    final theme = Theme.of(context);
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ThoughtFeedScreen(
                  posts: _posts,
                  userId: widget.userId,
                  initialPostId: post.id,
                  onRefresh: () {},
                ),
              ),
            ).then((_) {
              _fetchPosts();
            });
          },
          child: Stack(
            children: [
              // If the thought has a cover image show it, otherwise colored background
              post.coverImage != null && post.coverImage!.isNotEmpty
                  ? Image.network(
                      post.coverImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildThoughtsColorBackground(post, theme),
                    )
                  : _buildThoughtsColorBackground(post, theme),

              // Overlay like/comment counts similar to saved_posts
              if (post.likes > 0 || post.comments.isNotEmpty)
                Positioned(
                  bottom: 4,
                  left: 4,
                  right: 4,
                  child: Container(
                    color: Colors.black54,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (post.likes > 0)
                          Row(
                            children: [
                              const Icon(Icons.favorite,
                                  color: Colors.purple, size: 16),
                              const SizedBox(width: 2),
                              Text('${post.likes}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12)),
                            ],
                          )
                        else
                          const Icon(Icons.favorite_border,
                              color: Colors.white, size: 16),
                        if (post.comments.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.comment,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 2),
                              Text('${post.comments.length}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
