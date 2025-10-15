import 'package:flutter/material.dart';
import '../../../../data/services/thoughts_service.dart';
import '../../../../data/models/thoughts_model.dart';
import '../../../widgets/thoughts/thoughts_feed_card.dart';
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
        // The provided postsList doesn't look like thought posts; fetch from service
        print(
            'ThoughtPostsTab: provided postsList does not contain thought posts; will fetch by userId');
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
      print(
          'ThoughtPostsTab: fetching user thoughts for userId=${widget.userId} (profile endpoint)');
      var result = await _service.getUserThoughts(widget.userId!);
      print('ThoughtPostsTab: raw getUserThoughts result: $result');
      if (!(result['success'] == true && result['data'] != null)) {
        print(
            'ThoughtPostsTab: getUserThoughts returned no data or failed, falling back to followers endpoint');
        result = await _service.getFollowerThoughts(widget.userId!);
        print('ThoughtPostsTab: raw getFollowerThoughts result: $result');
      }

      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> data = result['data'];
        print('ThoughtPostsTab: fetched data length=${data.length}');
        final posts = data
            .map<ThoughtsPost>((json) {
              if (json is ThoughtsPost) return json;
              if (json is Map<String, dynamic>)
                return ThoughtsPost.fromJson(json);
              return ThoughtsPost.fromJson({});
            })
            .where((p) => p.isHidden == 0 && p.isDeleted == 0)
            .toList();
        print('ThoughtPostsTab: parsed ${posts.length} visible thought posts');
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

  // timestamp formatting is handled by ThoughtsFeedCard; helper removed

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

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
                  ),
                ),
              );
            },
            child: ThoughtsFeedCard(
              post: post,
              showCoverImage: false,
              onLike: () {
                // liking handled elsewhere; left as no-op
              },
              onComment: () {
                // navigate to comment view if desired
              },
              onUserTap: (userId) {},
            ),
          );
        }).toList(),
      ),
    );
  }
}
