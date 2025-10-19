import 'package:flutter/material.dart';
// import removed, use correct import below
import '../../../../../../data/services/song_post_service.dart';
import '../../../../../../data/services/thoughts_service.dart';
import '../../../../../../data/models/post_model.dart';
import '../../../../../../data/models/thoughts_model.dart';
import 'saved_posts_feed_screen.dart';

class SavedPostsPage extends StatefulWidget {
  final String userId;
  const SavedPostsPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<SavedPostsPage> createState() => _SavedPostsPageState();
}

class _SavedPostsPageState extends State<SavedPostsPage> {
  late Future<List<String>> _savedPostsFuture;
  late Future<List<String>> _savedThoughtsFuture;

  @override
  void initState() {
    super.initState();
    _savedPostsFuture = _fetchSavedPosts();
    _savedThoughtsFuture = _fetchSavedThoughts();
  }

  Future<List<String>> _fetchSavedPosts() async {
    final service = SongPostService();
    final result = await service.getSavedPosts(widget.userId, context);
    if (result['success'] == true && result['savedPosts'] != null) {
      List<String> ids = (result['savedPosts'] as List).cast<String>();
      return ids;
    }
    return [];
  }

  Future<List<String>> _fetchSavedThoughts() async {
    final service = ThoughtsService();
    final result = await service.getSavedThoughtsPosts(widget.userId, context);
    if (result['success'] == true && result['savedPosts'] != null) {
      List<String> ids = (result['savedPosts'] as List).cast<String>();
      return ids;
    }
    return [];
  }

  Future<List<Post>> _fetchPostDetails(List<String> ids) async {
    if (ids.isEmpty) return [];
    final service = SongPostService();
    final postsResult = await service.getPostsByIds(ids, context);
    if (postsResult['success'] == true) {
      return (postsResult['posts'] as List)
          .map((json) => Post.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<List<ThoughtsPost>> _fetchThoughtsDetails(List<String> ids) async {
    if (ids.isEmpty) return [];
    final service = ThoughtsService();
    final postsResult = await service.getThoughtsPostsByIds(ids, context);
    if (postsResult['success'] == true) {
      return (postsResult['posts'] as List)
          .map((json) => ThoughtsPost.fromJson(json))
          .toList();
    }
    return [];
  }

  Widget _buildSongPostsTab() {
    if (widget.userId.isEmpty) {
      return Center(child: Text('Please login to view saved posts'));
    }
    final theme = Theme.of(context);
    return FutureBuilder<List<String>>(
      future: _savedPostsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading saved posts'));
        }
        final postIds = snapshot.data ?? [];
        if (postIds.isEmpty) {
          return Center(child: Text('No saved posts'));
        }

        // Fetch full post details for grid preview
        return FutureBuilder<List<Post>>(
          future: _fetchPostDetails(postIds),
          builder: (context, postSnapshot) {
            if (postSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final posts = postSnapshot.data ?? [];
            if (posts.isEmpty) {
              return Center(child: Text('Failed to load post details'));
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: posts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final post = posts[index];
                return GestureDetector(
                  onTap: () async {
                    // Get saved thoughts IDs for passing to feed screen
                    final savedThoughts = await _savedThoughtsFuture;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SavedPostsFeedScreen(
                          userId: widget.userId,
                          savedPostIds: postIds,
                          savedThoughtsIds: savedThoughts,
                          initialPostId: post.id,
                          initialTabIndex: 0, 
                        ),
                      ),
                    );
                  },
                  child: Stack(
                    children: [
                      Image.network(
                        post.albumImage ?? '',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: theme.colorScheme.surfaceVariant,
                          child: Icon(Icons.music_note,
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                      if (post.likes > 0 || post.commentsCount > 0)
                        Positioned(
                          bottom: 4,
                          left: 4,
                          right: 4,
                          child: Container(
                            color: Colors.black54,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
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
                                              color: Colors.white,
                                              fontSize: 12)),
                                    ],
                                  )
                                else
                                  const Icon(Icons.favorite_border,
                                      color: Colors.white, size: 16),
                                if (post.commentsCount > 0)
                                  Row(
                                    children: [
                                      const Icon(Icons.comment,
                                          color: Colors.white, size: 16),
                                      const SizedBox(width: 2),
                                      Text('${post.commentsCount}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12)),
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
          },
        );
      },
    );
  }

  Widget _buildThoughtsTab() {
    if (widget.userId.isEmpty) {
      return Center(child: Text('Please login to view saved thoughts'));
    }
    final theme = Theme.of(context);
    return FutureBuilder<List<String>>(
      future: _savedThoughtsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading saved thoughts'));
        }
        final thoughtIds = snapshot.data ?? [];
        if (thoughtIds.isEmpty) {
          return Center(child: Text('No saved thought posts'));
        }

        // Fetch full thoughts post details for grid preview
        return FutureBuilder<List<ThoughtsPost>>(
          future: _fetchThoughtsDetails(thoughtIds),
          builder: (context, thoughtSnapshot) {
            if (thoughtSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final thoughts = thoughtSnapshot.data ?? [];
            if (thoughts.isEmpty) {
              return Center(child: Text('Failed to load thought details'));
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: thoughts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final thought = thoughts[index];
                return GestureDetector(
                  onTap: () async {
                    // Get saved song post IDs for passing to feed screen
                    final savedSongs = await _savedPostsFuture;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SavedPostsFeedScreen(
                          userId: widget.userId,
                          savedPostIds: savedSongs,
                          savedThoughtsIds: thoughtIds,
                          initialPostId: thought.id,
                          initialTabIndex: 1, 
                        ),
                      ),
                    );
                  },
                  child: Stack(
                    children: [
                      // Show cover image if available, otherwise show colored background
                      thought.coverImage != null && thought.coverImage!.isNotEmpty
                          ? Image.network(
                              thought.coverImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildThoughtsColorBackground(
                                      thought, theme),
                            )
                          : _buildThoughtsColorBackground(thought, theme),
                      // Overlay with like/comment counts
                      if (thought.likes > 0 || thought.comments.isNotEmpty)
                        Positioned(
                          bottom: 4,
                          left: 4,
                          right: 4,
                          child: Container(
                            color: Colors.black54,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (thought.likes > 0)
                                  Row(
                                    children: [
                                      const Icon(Icons.favorite,
                                          color: Colors.purple, size: 16),
                                      const SizedBox(width: 2),
                                      Text('${thought.likes}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12)),
                                    ],
                                  )
                                else
                                  const Icon(Icons.favorite_border,
                                      color: Colors.white, size: 16),
                                if (thought.comments.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(Icons.comment,
                                          color: Colors.white, size: 16),
                                      const SizedBox(width: 2),
                                      Text('${thought.comments.length}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12)),
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
          },
        );
      },
    );
  }

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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Saved Posts'),
          backgroundColor: Theme.of(context).colorScheme.background,
          foregroundColor: Theme.of(context).colorScheme.onBackground,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.onSurface,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurfaceVariant,
            tabs: const [Tab(text: 'Song Posts'), Tab(text: 'Thought Posts')],
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: TabBarView(
          children: [
            _buildSongPostsTab(),
            _buildThoughtsTab(),
          ],
        ),
      ),
    );
  }
}
