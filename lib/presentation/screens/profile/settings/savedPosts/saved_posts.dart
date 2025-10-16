import 'package:flutter/material.dart';
// import removed, use correct import below
import '../../../../../../data/services/song_post_service.dart';
import '../../../../../../data/models/post_model.dart';
import '../../../profile/savedPosts/saved_posts_feed_screen.dart';

class SavedPostsPage extends StatefulWidget {
  final String userId;
  const SavedPostsPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<SavedPostsPage> createState() => _SavedPostsPageState();
}

class _SavedPostsPageState extends State<SavedPostsPage> {
  late Future<List<String>> _savedPostsFuture;

  @override
  void initState() {
    super.initState();
    _savedPostsFuture = _fetchSavedPosts();
    // Debug: Show userId
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('UserId: ${widget.userId}')),
      );
    });
  }

  Future<List<String>> _fetchSavedPosts() async {
    final service = SongPostService();
    final result = await service.getSavedPosts(widget.userId, context);
    if (result['success'] == true && result['savedPosts'] != null) {
      List<String> ids = (result['savedPosts'] as List).cast<String>();
      // Debug: Show saved post IDs
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved IDs: ${ids.length} items')),
        );
      });
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

  @override
  Widget build(BuildContext context) {
    if (widget.userId.isEmpty) {
      return Scaffold(
          body: Center(child: Text('Please login to view saved posts')));
    }
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Posts'),
        backgroundColor: theme.colorScheme.background,
        foregroundColor: theme.colorScheme.onBackground,
        elevation: 0,
      ),
      body: FutureBuilder<List<String>>(
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SavedPostsFeedScreen(
                            userId: widget.userId,
                            savedPostIds: postIds,
                            initialPostId: post.id,
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
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
      ),
    );
  }
}
