import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../../data/services/auth_service.dart';
import '../../../data/services/fanbase_post_service.dart';

/// Screen for creating new posts within a specific fanbase
/// Allows users to create posts with optional Spotify track attachments
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
  // Text controllers for user input fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // Loading state indicators
  bool _isLoading = false; // For Spotify search loading
  bool _isCreatingPost = false; // For post creation loading

  // Spotify search functionality
  Map<String, dynamic>? _searchResults; // Search results from Spotify API
  Map<String, dynamic>? _selectedTrack; // Currently selected track for the post

  // Debounce timer to prevent excessive API calls while user is typing
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Listen for changes in search input to trigger debounced search
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    // Clean up resources to prevent memory leaks
    _debounce?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Handles search input changes with debouncing
  /// Waits 600ms after user stops typing before performing search
  /// This prevents excessive API calls while user is still typing
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (_searchController.text.isNotEmpty) {
        _performSearch(_searchController.text);
      } else {
        // Clear search results when search field is empty
        setState(() {
          _searchResults = null;
        });
      }
    });
  }

  /// Searches for tracks using Spotify API
  /// Makes API call to backend which interfaces with Spotify
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get authenticated dio instance from auth service
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio;

      // Make request to backend Spotify search endpoint
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
        // Show error message for failed search
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response.statusMessage}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(10),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Show error message for network or other errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Creates a new fanbase post with user input and optional track
  /// Validates input fields before making API call
  Future<void> _createPost() async {
    // Validate required fields
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in both topic and description'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isCreatingPost = true;
    });

    try {
      // Create post using fanbase post service
      final createdPost = await FanbasePostService.createFanbasePost(
        fanbaseId: widget.fanbaseId,
        topic: _titleController.text.trim(),
        description: _contentController.text.trim(),
        // Optional Spotify track data
        spotifyTrackId: _selectedTrack?['id'],
        songName: _selectedTrack?['name'],
        artistName: _selectedTrack?['artists'] is List
            ? _selectedTrack!['artists'].join(', ')
            : _selectedTrack?['artists']?.toString(),
        albumArt: _selectedTrack?['album'],
        context: context,
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
          content: const Text('Post created successfully!'),
          backgroundColor: const Color(0xFFA855F7),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 2),
        ),
        );
        // Return to previous screen with created post data
        // This allows the previous screen to refresh and show the new post
        Navigator.pop(context, createdPost);
      }
    } catch (e) {
      // Show error message if post creation fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating post: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      // Reset loading state
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
      // App bar with create post action
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: [
          // Post button in app bar for quick access
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
            // Display fanbase information
            _buildFanbaseInfoCard(theme, colorScheme),

            const SizedBox(height: 24),

            // Post topic input field
            _buildTopicInputField(colorScheme, theme),

            const SizedBox(height: 20),

            // Post description input field
            _buildDescriptionInputField(colorScheme, theme),

            const SizedBox(height: 24),

            // Show selected track if any
            if (_selectedTrack != null) ...[
              _buildSelectedTrackCard(theme, colorScheme),
              const SizedBox(height: 24),
            ],

            // Spotify song search section
            _buildSongSearchSection(colorScheme, theme),

            const SizedBox(height: 16),

            // Display search results
            if (_searchResults != null) ...[
              _buildSearchResultsList(theme, colorScheme),
            ],

            const SizedBox(height: 32),

            // Main create post button
            _buildCreatePostButton(),
          ],
        ),
      ),
    );
  }

  /// Builds the fanbase information card at the top
  Widget _buildFanbaseInfoCard(ThemeData theme, ColorScheme colorScheme) {
    return Container(
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
    );
  }

  /// Builds the topic input field
  Widget _buildTopicInputField(ColorScheme colorScheme, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            hintStyle: TextStyle(color: colorScheme.onPrimary.withOpacity(0.5)),
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
      ],
    );
  }

  /// Builds the description input field
  Widget _buildDescriptionInputField(ColorScheme colorScheme, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          maxLines: 6, // Allow multiple lines for longer descriptions
          decoration: InputDecoration(
            hintText: 'Describe your post...',
            hintStyle: TextStyle(color: colorScheme.onPrimary.withOpacity(0.5)),
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
      ],
    );
  }

  /// Builds the selected track display card
  Widget _buildSelectedTrackCard(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              // Album artwork or placeholder
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
              // Track information
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
              // Remove track button
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
      ],
    );
  }

  /// Builds the song search input section
  Widget _buildSongSearchSection(ColorScheme colorScheme, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            hintStyle: TextStyle(color: colorScheme.onPrimary.withOpacity(0.5)),
            prefixIcon: Icon(Icons.search,
                color: colorScheme.onPrimary.withOpacity(0.5)),
            // Show loading indicator or clear button
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
      ],
    );
  }

  /// Builds the list of search results from Spotify
  Widget _buildSearchResultsList(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      height: 300, // Fixed height to prevent overflow
      child: ListView.builder(
        itemCount: _searchResults?['tracks']?['items']?.length ?? 0,
        itemBuilder: (context, index) {
          final track = _searchResults?['tracks']?['items']?[index];
          if (track == null) return const SizedBox.shrink();

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: theme.cardColor.withOpacity(0.1),
            child: ListTile(
              // Album artwork or placeholder
              leading:
                  track['album'] != null && track['album'].toString().isNotEmpty
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
              // Track name
              title: Text(
                track['name'] ?? 'Unknown Track',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Artist name(s)
              subtitle: Text(
                track['artists'] is List
                    ? track['artists'].join(', ')
                    : track['artists']?.toString() ?? 'Unknown Artist',
                style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.6)),
              ),
              // Add track button
              trailing: Icon(
                Icons.add,
                color: colorScheme.onPrimary.withOpacity(0.7),
                size: 20,
              ),
              // Handle track selection
              onTap: () {
                setState(() {
                  _selectedTrack = track;
                  _searchResults = null; // Hide search results
                  _searchController.clear(); // Clear search field
                });
              },
            ),
          );
        },
      ),
    );
  }

  /// Builds the main create post button
  Widget _buildCreatePostButton() {
    return SizedBox(
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
    );
  }
}
