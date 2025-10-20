import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../data/services/song_post_service.dart';
import '../../../../../data/services/thoughts_service.dart';
import '../../../../../data/models/post_model.dart';
import '../../../../../data/models/thoughts_model.dart';
// import 'package:provider/provider.dart';
// import '../../../../../core/providers/auth_provider.dart';

class HiddenPostsPage extends StatefulWidget {
  const HiddenPostsPage({Key? key}) : super(key: key);

  @override
  State<HiddenPostsPage> createState() => _HiddenPostsPageState();
}

class _HiddenPostsPageState extends State<HiddenPostsPage> {
  late Future<List<Post>> _songPostsFuture;
  late Future<List<ThoughtsPost>> _thoughtsPostsFuture;
  final List<Post> _songPosts = [];
  final List<ThoughtsPost> _thoughtsPosts = [];
  final SongPostService _service = SongPostService();
  final ThoughtsService _thoughtsService = ThoughtsService();
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
      // print('[DEBUG] HiddenPosts: Error reading SharedPreferences: $e');
    }

    if (mounted) {
      setState(() {
        _songPostsFuture = _fetchHiddenSongPostsForUser(userId);
        _thoughtsPostsFuture = _fetchHiddenThoughtsForUser(userId);
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

  Future<List<ThoughtsPost>> _fetchHiddenThoughtsForUser(String? userId) async {
    if (userId == null || userId.isEmpty) return <ThoughtsPost>[];

    final res = await _thoughtsService.getHiddenThoughtsByUserId(userId);
    if (res['success'] == true && res['data'] is List) {
      final rawList = res['data'] as List;
      final converted = <ThoughtsPost>[];

      for (final e in rawList) {
        try {
          if (e is ThoughtsPost) {
            converted.add(e);
            continue;
          }

          if (e is Map<String, dynamic>) {
            converted.add(ThoughtsPost.fromJson(e));
            continue;
          }

          if (e is Map) {
            converted.add(ThoughtsPost.fromJson(Map<String, dynamic>.from(e)));
            continue;
          }

          // Handle objects that may expose toJson() (interop wrappers)
          try {
            final dynamic maybe = e as dynamic;
            final json = maybe.toJson();
            if (json is Map) {
              converted.add(ThoughtsPost.fromJson(Map<String, dynamic>.from(json)));
              continue;
            }
          } catch (_) {
            // ignore
          }

          // Last resort: attempt to cast to Map via jsonEncode/jsonDecode
          try {
            final encoded = jsonEncode(e);
            final decoded = jsonDecode(encoded) as Map<String, dynamic>;
            converted.add(ThoughtsPost.fromJson(decoded));
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

      _thoughtsPosts.clear();
      _thoughtsPosts.addAll(converted);
      return _thoughtsPosts;
    }
    return <ThoughtsPost>[];
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
          // print(
          //     '[DEBUG] HiddenPosts unhide: Error reading SharedPreferences: $e');
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

  void _unhideThought(ThoughtsPost thought) async {
    final oldIndex = _thoughtsPosts.indexWhere((p) => p.id == thought.id);
    // mark undo not pressed yet for this thought
    _undoMap[thought.id] = false;

    if (mounted) {
      setState(() {
        _thoughtsPosts.removeWhere((p) => p.id == thought.id);
      });
    }

    ScaffoldMessenger.of(context).clearSnackBars();

    final snackbar = SnackBar(
      content: const Text('Unhiding thought...'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          // mark undo pressed and restore locally
          _undoMap[thought.id] = true;
          if (mounted) {
            setState(() {
              _thoughtsPosts.insert(oldIndex >= 0 ? oldIndex : 0, thought);
            });
          }
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackbar);

    // Schedule the unhide request with a short delay to allow Undo to cancel.
    Future.delayed(const Duration(seconds: 3), () async {
      // If undo was pressed in the meantime, skip the unhide call
      if (_undoMap[thought.id] == true) {
        _undoMap.remove(thought.id);
        return;
      }

      final res = await _thoughtsService.unhideThought(thought.id);
      if (res['success'] == true) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Thought unhidden')));

        // Refresh the hidden thoughts list from server to keep UI consistent
        String? userId;
        try {
          final prefs = await SharedPreferences.getInstance();
          final userDataString = prefs.getString('user_data');
          if (userDataString != null) {
            final userData = jsonDecode(userDataString);
            userId = userData['id'];
          }
        } catch (e) {
          // print(
          //     '[DEBUG] HiddenThoughts unhide: Error reading SharedPreferences: $e');
        }

        if (mounted) {
          setState(() {
            _thoughtsPostsFuture = _fetchHiddenThoughtsForUser(userId);
          });
        }
      } else {
        // Revert on failure
        if (mounted) {
          setState(() {
            _thoughtsPosts.insert(oldIndex >= 0 ? oldIndex : 0, thought);
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to unhide: ${res['message']}')));
      }

      // cleanup undo tracking
      _undoMap.remove(thought.id);
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
              // print(
              //     '[DEBUG] HiddenPosts refresh: Error reading SharedPreferences: $e');
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
    return FutureBuilder<List<ThoughtsPost>>(
      future: _thoughtsPostsFuture,
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
        final thoughts = snapshot.data ?? _thoughtsPosts;

        // Sync internal list after future completes to keep other actions (unhide)
        if (snapshot.hasData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted &&
                !listEquals(_thoughtsPosts.map((p) => p.id).toList(),
                    thoughts.map((p) => p.id).toList())) {
              setState(() {
                _thoughtsPosts.clear();
                _thoughtsPosts.addAll(thoughts);
              });
            }
          });
        }

        if (thoughts.isEmpty) {
          return Center(
              child: Text('No hidden thoughts',
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
                  '[DEBUG] HiddenThoughts refresh: Error reading SharedPreferences: $e');
            }

            final fresh = await _fetchHiddenThoughtsForUser(userId);
            if (mounted) {
              setState(() {
                // replace list contents
                _thoughtsPosts.clear();
                _thoughtsPosts.addAll(fresh);
              });
            }
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: thoughts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final t = thoughts[i];
              return Card(
                color: Theme.of(context).cardColor,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  leading: t.coverImage != null && t.coverImage!.isNotEmpty
                      ? SizedBox(
                          width: 56,
                          height: 56,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              t.coverImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Icon(Icons.music_note,
                                  color: Theme.of(context).colorScheme.primary),
                            ),
                          ),
                        )
                      : SizedBox(
                          width: 56,
                          height: 56,
                          child: Icon(Icons.lightbulb_outline,
                              size: 32,
                              color: Theme.of(context).colorScheme.primary),
                        ),
                  title: Text(
                    t.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (t.songName != null && t.songName!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Song: ${t.songName}',
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      ],
                      if (t.artistName != null && t.artistName!.isNotEmpty) ...[
                        Text('Artist: ${t.artistName}',
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      ],
                      const SizedBox(height: 6),
                      Text(
                          'Hidden on ${t.createdAt.toLocal().toString().split(' ').first}',
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
                    onPressed: () => _unhideThought(t),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
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
