import 'package:flutter/material.dart';
import 'package:frontend/data/services/search_service.dart';

import 'package:frontend/presentation/widgets/song_post/post.dart';
import 'package:frontend/presentation/widgets/search/explore_feed.dart';
import 'package:frontend/presentation/widgets/search/segmant_divider.dart';
import 'package:frontend/presentation/widgets/song_post/post_shape.dart';
import 'package:frontend/presentation/widgets/despost/widgets/des_post_content_widget.dart' as DesPost;
import 'package:frontend/presentation/widgets/home/feed_widget.dart';
import 'package:frontend/data/models/post_model.dart' as data_model;
import 'package:frontend/data/models/feed_item.dart';

import 'package:frontend/presentation/widgets/search/searchbar.dart';

import 'package:frontend/presentation/widgets/search/category_selector.dart';
import 'package:frontend/presentation/widgets/search/user_search_results.dart';
import 'package:frontend/presentation/widgets/search/fanbase_search_results.dart';

class SearchFeedScreen extends StatefulWidget {
  const SearchFeedScreen({Key? key}) : super(key: key);

  @override
  State<SearchFeedScreen> createState() => _SearchFeedScreenState();
}

class _SearchFeedScreenState extends State<SearchFeedScreen> {
  void _onSearchChanged(String value) {
    setState(() {
      _query = value;
      _hasSearched = false;
    });
  }

  Future<void> _onSearchSubmitted(String value) async {
    setState(() {
      _query = value;
      _hasSearched = true;
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await _searchService.search(_query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Search failed. Please try again.';
      });
    }
  }

  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _hasSearched = false;
  int _selectedSegment = 0;

  final List<String> _segments = [
    'All',
    'People',
    'Posts',
    'Song Posts',
    'Fanbases',
  ];

  final SearchService _searchService = SearchService();
  Map<String, dynamic> _searchResults = {};
  bool _isLoading = false;
  String? _error;

  List<String> _exploreImages = [];

  // Fetch song posts for explore feed (album images, ascending by date)
  Future<void> _fetchExploreImages() async {
    try {
      final results = await _searchService.search(''); // Empty query to get all
      final songPosts = (results['songPosts'] ?? []) as List;
      // If backend supports sorting, you should add sort there. Otherwise, sort here if date is available.
      setState(() {
        _exploreImages = songPosts
            .map<String>(
                (post) => post['albumImage'] ?? 'assets/images/song.png')
            .toList();
      });
    } catch (e) {
      // fallback to empty or default
      setState(() {
        _exploreImages = [];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchExploreImages();
  }

  final List<String> _categories = [
    'Trending',
    'Pop',
    'Superhits',
    'Kollywood',
    'Raps',
    'Kpop'
  ];
  int _selectedCategory = 0;

  @override
  Widget build(BuildContext context) {
    final showResults = _hasSearched && _query.isNotEmpty;

    Widget temporaryFanbaseCard() {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          leading: const CircleAvatar(
            backgroundImage: AssetImage('assets/images/hehe.png'),
          ),
          title: const Text('Temporary Fanbase'),
          subtitle: const Text(
              'This is a temporary fanbase card shown in search feed.'),
          onTap: () {
            // TODO: Add tap action if needed
          },
        ),
      );
    }

    Widget temporaryPostCard(int index) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage: AssetImage('assets/images/hehe.png'),
          ),
          title: Text('Temporary Post #$index'),
          subtitle:
              const Text('This is a temporary post shown in search feed.'),
          onTap: () {
            // TODO: Add tap action if needed
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: InstagramSearchBar(
          controller: _searchController,
          onChanged: _onSearchChanged,
          onSubmitted: _onSearchSubmitted,
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          if (showResults)
            SegmentDivider(
              segments: _segments,
              selectedIndex: _selectedSegment,
              onSegmentSelected: (index) {
                setState(() {
                  _selectedSegment = index;
                });
              },
            )
          else
            CategorySelector(
              categories: _categories,
              selectedIndex: _selectedCategory,
              onCategorySelected: (index) {
                setState(() {
                  _selectedCategory = index;
                });
              },
            ),
          Expanded(
            child: showResults
                ? (_isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _selectedSegment == 0 // All
                        ? SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if ((_searchResults['users'] ?? []).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      'People',
                                      style: Theme.of(context).textTheme.headlineSmall,
                                    ),
                                  ),
                                if ((_searchResults['users'] ?? []).isNotEmpty)
                                  UserSearchResults(
                                    users: (_searchResults['users'] ?? []) as List,
                                    query: _query,
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    onUserTap: (userId) {
                                      Navigator.pushNamed(context, '/profile/$userId');
                                    },
                                  ),
                                if ((_searchResults['fanbases'] ?? []).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      'Fanbases',
                                      style: Theme.of(context).textTheme.headlineSmall,
                                    ),
                                  ),
                                if ((_searchResults['fanbases'] ?? []).isNotEmpty)
                                  FanbaseSearchResults(
                                    fanbases: (_searchResults['fanbases'] ?? []) as List,
                                    query: _query,
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                  ),
                                if ((_searchResults['posts'] ?? []).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      'Posts',
                                      style: Theme.of(context).textTheme.headlineSmall,
                                    ),
                                  ),
                                if ((_searchResults['posts'] ?? []).isNotEmpty)
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: (_searchResults['posts'] ?? []).length,
                                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final post = (_searchResults['posts'] ?? [])[index];
                                      return DesPost.Post(
                                        trackId: post['trackId'] ?? '',
                                        songName: post['songName'] ?? '',
                                        artists: post['artists'] ?? '',
                                        albumImage: post['albumImage'] ?? '',
                                        caption: post['caption'] ?? '',
                                        username: post['username'] ?? 'Unknown User',
                                        userImage: post['userImage'] ?? 'assets/images/profile_picture.jpg',
                                        descriptionTitle: post['topic'] ?? '',
                                        description: post['description'] ?? '',
                                        onLike: () => print('Liked post: ${post['_id']}'),
                                        onComment: () => print('Comment: ${post['_id']}'),
                                        onShare: () => print('Share: ${post['_id']}'),
                                        onPlayPause: () => print('Play/Pause: ${post['_id']}'),
                                        onUsernameTap: () => print('Username tap: ${post['username']}'),
                                        isLiked: false,
                                        isPlaying: false,
                                        isCurrentTrack: false,
                                      );
                                    },
                                  ),
                                if ((_searchResults['songPosts'] ?? []).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      'Song Posts',
                                      style: Theme.of(context).textTheme.headlineSmall,
                                    ),
                                  ),
                                if ((_searchResults['songPosts'] ?? []).isNotEmpty)
                                  FeedWidget(
                                    feedItems: (_searchResults['songPosts'] ?? []).map<FeedItem>((post) => FeedItem.song(data_model.Post.fromJson(post))).toList(),
                                    isLoading: false,
                                    error: null,
                                    onRefresh: () {},
                                    onSongLike: (post) => print('Liked song post: ${post.id}'),
                                    onSongComment: (post) => print('Comment song post: ${post.id}'),
                                    onSongPlay: (post) => print('Play/Pause song post: ${post.id}'),
                                    onSongShare: (post) => print('Share song post: ${post.id}'),
                                    currentlyPlayingTrackId: null,
                                    isPlaying: false,
                                    onUserTap: (userId) => print('User tapped: $userId'),
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                  ),
                              ],
                            ),
                          )
                    : _selectedSegment == 1 // People
                        ? Builder(
                            builder: (context) {
                              final users =
                                  (_searchResults['users'] ?? []) as List;
                              return UserSearchResults(
                                users: users,
                                query: _query,
                                onUserTap: (userId) {
                                  Navigator.pushNamed(context, '/profile/$userId');
                                },
                              );
                            },
                          )
                        : _selectedSegment == 3 // Song Posts
                            ? Builder(
                                builder: (context) {
                                  final songPosts =
                                      (_searchResults['songPosts'] ?? [])
                                          as List;
                                  print('Song Posts data from search results: $songPosts');
                                  if (songPosts.isEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.all(32.0),
                                      child: Center(
                                        child: Text(
                                          _query.isEmpty
                                              ? 'Start typing to search Song Posts...'
                                              : 'There is no related posts',
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey[600]),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    );
                                  }
                                  // Show song posts as a vertical list
                                  return FeedWidget(
                                    feedItems: songPosts.map<FeedItem>((post) => FeedItem.song(data_model.Post.fromJson(post))).toList(),
                                    isLoading: false,
                                    error: null,
                                    onRefresh: () {},
                                    onSongLike: (post) => print('Liked song post: ${post.id}'),
                                    onSongComment: (post) => print('Comment song post: ${post.id}'),
                                    onSongPlay: (post) => print('Play/Pause song post: ${post.id}'),
                                    onSongShare: (post) => print('Share song post: ${post.id}'),
                                    currentlyPlayingTrackId: null,
                                    isPlaying: false,
                                    onUserTap: (userId) => print('User tapped: $userId'),
                                  );
                                },
                              )
                        : _selectedSegment == 4 // Fanbases
                            ? Builder(
                                builder: (context) {
                                  final fanbases =
                                      (_searchResults['fanbases'] ?? [])
                                          as List;
                                  return FanbaseSearchResults(
                                    fanbases: fanbases,
                                    query: _query,
                                  );
                                },
                              )
                        : _selectedSegment == 2 // Posts
                            ? Builder(
                                builder: (context) {
                                  final posts =
                                      (_searchResults['posts'] ?? [])
                                          as List;
                                  if (posts.isEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.all(32.0),
                                      child: Center(
                                        child: Text(
                                          'no related results',
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey[600]),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    );
                                  }
                                  // Show only topics of posts as a vertical list
                                  return ListView.separated(
                                    itemCount: posts.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final post = posts[index];
                                      return DesPost.Post(
                                        trackId: post['trackId'] ?? '',
                                        songName: post['songName'] ?? '',
                                        artists: post['artists'] ?? '',
                                        albumImage: post['albumImage'] ?? '',
                                        caption: post['caption'] ?? '',
                                        username: post['username'] ?? 'Unknown User',
                                        userImage: post['userImage'] ?? 'assets/images/profile_picture.jpg',
                                        descriptionTitle: post['topic'] ?? '',
                                        description: post['description'] ?? '',
                                        onLike: () => print('Liked post: ${post['_id']}'),
                                        onComment: () => print('Comment: ${post['_id']}'),
                                        onShare: () => print('Share: ${post['_id']}'),
                                        onPlayPause: () => print('Play/Pause: ${post['_id']}'),
                                        onUsernameTap: () => print('Username tap: ${post['username']}'),
                                        isLiked: false,
                                        isPlaying: false,
                                        isCurrentTrack: false,
                                      );
                                    },
                                  );
                                },
                              )
                            : ExploreFeed(imageUrls: _exploreImages))
                : ExploreFeed(imageUrls: _exploreImages),
          ),
        ],
      ),
    );
  }
}