import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../data/services/song_post_service.dart';
import '../../../../../data/models/post_model.dart';
import 'package:provider/provider.dart';
import '../../../../../core/providers/auth_provider.dart';

class HiddenPostsPage extends StatefulWidget {
  const HiddenPostsPage({Key? key}) : super(key: key);

  @override
  State<HiddenPostsPage> createState() => _HiddenPostsPageState();
}

class _HiddenPostsPageState extends State<HiddenPostsPage> {
  late Future<List<Post>> _songPostsFuture;
  final List<Post> _songPosts = [];
  final SongPostService _service = SongPostService();
  final Map<String, bool> _undoMap =
      {}; // tracks if undo was pressed for a post id

  @override
  void initState() {
    super.initState();
    _loadHiddenPosts();
  }

  Future<void> _loadHiddenPosts() async {
    // Get userId from SharedPreferences
    String? userId;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        userId = userData['id'];
      }
    } catch (e) {
      print('[DEBUG] HiddenPosts: Error reading SharedPreferences: $e');
    }

    if (mounted) {
      setState(() {
        _songPostsFuture = _fetchHiddenSongPostsForUser(userId);
      });
    }
  }

  Future<List<Post>> _fetchHiddenSongPostsForUser(String? userId) async {
    if (userId == null || userId.isEmpty) return <Post>[];

    final res = await _service.getHiddenPostsByUserId(userId);
    if (res['success'] == true && res['data'] is List) {
      final rawList = res['data'] as List;
      final converted = <Post>[];

      for (final e in rawList) {
        try {
          if (e is Post) {
            converted.add(e);
            continue;
          }

          if (e is Map<String, dynamic>) {
            converted.add(Post.fromJson(e));
            continue;
          }

          if (e is Map) {
            converted.add(Post.fromJson(Map<String, dynamic>.from(e)));
            continue;
          }

          // Handle objects that may expose toJson() (interop wrappers)
          try {
            final dynamic maybe = e as dynamic;
            final json = maybe.toJson();
            if (json is Map) {
              converted.add(Post.fromJson(Map<String, dynamic>.from(json)));
              continue;
            }
          } catch (_) {
            // ignore
          }

          // Last resort: attempt to cast to Map via jsonEncode/jsonDecode
          try {
            final encoded = jsonEncode(e);
            final decoded = jsonDecode(encoded) as Map<String, dynamic>;
            converted.add(Post.fromJson(decoded));
            continue;
          } catch (_) {
            // if we get here we cannot convert this element; skip it
            continue;
          }
        } catch (_) {
          // ignore malformed element
          continue;
        }
      }

      _songPosts.clear();
      _songPosts.addAll(converted);
      return _songPosts;
    }
    return <Post>[];
  }

  void _unhideSongPost(Post post) async {
    final oldIndex = _songPosts.indexWhere((p) => p.id == post.id);
    // mark undo not pressed yet for this post
    _undoMap[post.id] = false;

    if (mounted) {
      setState(() {
        _songPosts.removeWhere((p) => p.id == post.id);
      });
    }

    ScaffoldMessenger.of(context).clearSnackBars();

    final snackbar = SnackBar(
      content: const Text('Unhiding post...'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          // mark undo pressed and restore locally
          _undoMap[post.id] = true;
          if (mounted) {
            setState(() {
              _songPosts.insert(oldIndex >= 0 ? oldIndex : 0, post);
            });
          }
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackbar);

    // Schedule the unhide request with a short delay to allow Undo to cancel.
    Future.delayed(const Duration(seconds: 3), () async {
      // If undo was pressed in the meantime, skip the unhide call
      if (_undoMap[post.id] == true) {
        _undoMap.remove(post.id);
        return;
      }

      final res = await _service.unhidePost(post.id);
      if (res['success'] == true) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Post unhidden')));

        // Refresh the hidden posts list from server to keep UI consistent
        String? userId;
        try {
          final prefs = await SharedPreferences.getInstance();
          final userDataString = prefs.getString('user_data');
          if (userDataString != null) {
            final userData = jsonDecode(userDataString);
            userId = userData['id'];
          }
        } catch (e) {
          print(
              '[DEBUG] HiddenPosts unhide: Error reading SharedPreferences: $e');
        }

        if (mounted) {
          setState(() {
            _songPostsFuture = _fetchHiddenSongPostsForUser(userId);
          });
        }
      } else {
        // Revert on failure
        if (mounted) {
          setState(() {
            _songPosts.insert(oldIndex >= 0 ? oldIndex : 0, post);
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to unhide: ${res['message']}')));
      }

      // cleanup undo tracking
      _undoMap.remove(post.id);
    });
  }

  Widget _buildSongPostsTab() {
    return FutureBuilder<List<Post>>(
      future: _songPostsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary));
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error)));
        }

        // Prefer snapshot data when available to avoid state desync
        final posts = snapshot.data ?? _songPosts;

        // Sync internal list after future completes to keep other actions (unhide)
        if (snapshot.hasData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted &&
                !listEquals(_songPosts.map((p) => p.id).toList(),
                    posts.map((p) => p.id).toList())) {
              setState(() {
                _songPosts.clear();
                _songPosts.addAll(posts);
              });
            }
          });
        }

        if (posts.isEmpty) {
          return Center(
              child: Text('No hidden song posts',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)));
        }

        return RefreshIndicator(
          onRefresh: () async {
            String? userId;
            try {
              final prefs = await SharedPreferences.getInstance();
              final userDataString = prefs.getString('user_data');
              if (userDataString != null) {
                final userData = jsonDecode(userDataString);
                userId = userData['id'];
              }
            } catch (e) {
              print(
                  '[DEBUG] HiddenPosts refresh: Error reading SharedPreferences: $e');
            }

            final fresh = await _fetchHiddenSongPostsForUser(userId);
            if (mounted) {
              setState(() {
                // replace list contents
                _songPosts.clear();
                _songPosts.addAll(fresh);
              });
            }
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final p = posts[i];
              return Card(
                color: Theme.of(context).cardColor,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  leading: SizedBox(
                    width: 56,
                    height: 56,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: p.albumImage != null
                          ? Image.network(
                              p.albumImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Icon(Icons.music_note,
                                  color: Theme.of(context).colorScheme.primary),
                            )
                          : Icon(Icons.music_note,
                              color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  title: Text(p.songName,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.artists,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 6),
                      if (p.caption != null && p.caption!.isNotEmpty)
                        Text(p.caption!,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      const SizedBox(height: 6),
                      Text(
                          'Hidden on ${p.createdAt.toLocal().toString().split(' ').first}',
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: Icon(Icons.visibility,
                        color: Theme.of(context).colorScheme.primary),
                    tooltip: 'Unhide',
                    onPressed: () => _unhideSongPost(p),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildThoughtsTab() {
    return const Center(child: Text('Hidden thoughts — coming soon'));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Hidden posts',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          bottom: TabBar(
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.onSurface,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurfaceVariant,
            tabs: const [Tab(text: 'Songs'), Tab(text: 'Thoughts')],
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
