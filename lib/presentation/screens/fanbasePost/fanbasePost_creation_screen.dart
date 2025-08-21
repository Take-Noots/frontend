import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:dio/dio.dart';
import 'dart:async';

import '../../../data/services/auth_service.dart';
import '../../../data/services/fanbase_post_service.dart';
// import '../../../data/models/fanbase_post_model.dart';
// import '../../widgets/home/header_bar.dart';

class FanbasePostCreationScreen extends StatefulWidget {
  final String fanbaseId;
  final String fanbaseName;

  const FanbasePostCreationScreen({
    Key? key,
    required this.fanbaseId,
    required this.fanbaseName,
  }) : super(key: key);

  @override
  State<FanbasePostCreationScreen> createState() =>
      _FanbasePostCreationScreenState();
}

class _FanbasePostCreationScreenState extends State<FanbasePostCreationScreen> {
  // Controllers for post creation
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // Loading states
  bool _isLoading = false;
  bool _isCreatingPost = false;

  // Search results from Spotify API
  Map<String, dynamic>? _searchResults;
  Map<String, dynamic>? _selectedTrack;

  // Debounce timer for search input
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Waits for 600ms after user stops typing, then searches for songs
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (_searchController.text.isNotEmpty) {
        _performSearch(_searchController.text);
      } else {
        setState(() {
          _searchResults = null;
        });
      }
    });
  }

  // Search songs using Spotify API
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;
      final response = await dio.get(
        '/spotify/search/track',
        queryParameters: {'track_name': query},
      );

      if (response.statusCode == 200) {
        setState(() {
          _searchResults = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response.statusMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching: $e')),
        );
      }
    }
  }

  // Create the post
  Future<void> _createPost() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill in both topic and description')),
      );
      return;
    }

    setState(() {
      _isCreatingPost = true;
    });

    try {
      final createdPost = await FanbasePostService.createFanbasePost(
        fanbaseId: widget.fanbaseId,
        topic: _titleController.text.trim(),
        description: _contentController.text.trim(),
        spotifyTrackId: _selectedTrack?['id'],
        songName: _selectedTrack?['name'],
        artistName: _selectedTrack?['artists'] is List
            ? _selectedTrack!['artists'].join(', ')
            : _selectedTrack?['artists']?.toString(),
        albumArt: _selectedTrack?['album'],
        context: context,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
        );
        Navigator.pop(context, createdPost); // Return the created post
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating post: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingPost = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isCreatingPost ? null : _createPost,
            child: _isCreatingPost
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Post',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fanbase info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.onPrimary.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Creating post for:',
                    style: TextStyle(
                      color: colorScheme.onPrimary.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.fanbaseName,
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Title input
            Text(
              'Topic:',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              style: TextStyle(color: colorScheme.onPrimary),
              decoration: InputDecoration(
                hintText: 'Enter post topic...',
                hintStyle:
                    TextStyle(color: colorScheme.onPrimary.withOpacity(0.5)),
                filled: true,
                fillColor: theme.cardColor.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: colorScheme.onPrimary.withOpacity(0.4)),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Content input
            Text(
              'Description:',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              style: TextStyle(color: colorScheme.onPrimary),
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Describe your post...',
                hintStyle:
                    TextStyle(color: colorScheme.onPrimary.withOpacity(0.5)),
                filled: true,
                fillColor: theme.cardColor.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: colorScheme.onPrimary.withOpacity(0.4)),
                ),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 24),

            // Selected track (if any)
            if (_selectedTrack != null) ...[
              Text(
                'Selected Track:',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.onPrimary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _selectedTrack!['album'] != null
                          ? Image.network(
                              _selectedTrack!['album'],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              color: colorScheme.onPrimary.withOpacity(0.1),
                              child: Icon(
                                Icons.music_note,
                                color: colorScheme.onPrimary.withOpacity(0.5),
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedTrack!['name'] ?? 'Unknown Track',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedTrack!['artists'] is List
                                ? _selectedTrack!['artists'].join(', ')
                                : _selectedTrack!['artists']?.toString() ??
                                    'Unknown Artist',
                            style: TextStyle(
                              color: colorScheme.onPrimary.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: colorScheme.onPrimary.withOpacity(0.7),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedTrack = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Song search section
            Text(
              'Add Music (Optional):',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              style: TextStyle(color: colorScheme.onPrimary),
              decoration: InputDecoration(
                hintText: 'Search for a song or artist...',
                hintStyle:
                    TextStyle(color: colorScheme.onPrimary.withOpacity(0.5)),
                prefixIcon: Icon(Icons.search,
                    color: colorScheme.onPrimary.withOpacity(0.5)),
                suffixIcon: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.onPrimary.withOpacity(0.5)),
                        ),
                      )
                    : IconButton(
                        icon: Icon(Icons.clear,
                            color: colorScheme.onPrimary.withOpacity(0.5)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = null;
                          });
                        },
                      ),
                filled: true,
                fillColor: theme.cardColor.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: colorScheme.onPrimary.withOpacity(0.4)),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Search results list
            if (_searchResults != null) ...[
              Container(
                height: 300,
                child: ListView.builder(
                  itemCount: _searchResults?['tracks']?['items']?.length ?? 0,
                  itemBuilder: (context, index) {
                    final track = _searchResults?['tracks']?['items']?[index];
                    if (track == null) return const SizedBox.shrink();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: theme.cardColor.withOpacity(0.1),
                      child: ListTile(
                        leading: track['album'] != null &&
                                track['album'].toString().isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  track['album'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: colorScheme.onPrimary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.music_note,
                                  color: colorScheme.onPrimary.withOpacity(0.5),
                                ),
                              ),
                        title: Text(
                          track['name'] ?? 'Unknown Track',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          track['artists'] is List
                              ? track['artists'].join(', ')
                              : track['artists']?.toString() ??
                                  'Unknown Artist',
                          style: TextStyle(
                              color: colorScheme.onPrimary.withOpacity(0.6)),
                        ),
                        trailing: Icon(
                          Icons.add,
                          color: colorScheme.onPrimary.withOpacity(0.7),
                          size: 20,
                        ),
                        onTap: () {
                          setState(() {
                            _selectedTrack = track;
                            _searchResults = null;
                            _searchController.clear();
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Create Post Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCreatingPost ? null : _createPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isCreatingPost
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Create Post',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
