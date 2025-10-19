import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '/data/services/spotify_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/thoughts_service.dart';
import '../../widgets/create_post/button.dart';
import '../../widgets/common/musicplayer_bar.dart';
import '../../../core/router/route_names.dart';
import 'search_song.dart';

// Screen for sharing thoughts/descriptions with optional cover image
class CreateDescriptionNootPage extends StatefulWidget {
  const CreateDescriptionNootPage({Key? key}) : super(key: key);

  @override
  State<CreateDescriptionNootPage> createState() => _CreateDescriptionNootPageState();
}

class _CreateDescriptionNootPageState extends State<CreateDescriptionNootPage> {
  
  // Controller for thoughts text input
  final TextEditingController _thoughtsController = TextEditingController();
  
  // Controller for song search input
  final TextEditingController _searchController = TextEditingController();
  
  // Loading state for song search
  bool _isSearchLoading = false;
  
  // Loading state for sharing thoughts
  bool _isShareLoading = false;
  
  // Search results from Spotify API - cover image
  Map<String, dynamic>? _searchResults;
  
  // Debounce timer for search input
  Timer? _debounce;
  
  // Show image search interface
  bool _showImageSearch = false;
  
  // Selected cover image URL
  String? _selectedCoverImage;

  // Selected song and artist
  String? _selectedSongName;
  String? _selectedArtistName;
  String? _selectedTrackId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _thoughtsController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  //waits for 500ms after user stops typing, then searches for songs
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) {
        _performSearch(_searchController.text);
      } else {
        setState(() {
          _searchResults = null;
        });
      }
    });
  }

  // calls spotify api to search for cover image
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearchLoading = true;
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
          _isSearchLoading = false;
        });
      } else {
        setState(() {
          _isSearchLoading = false;
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
        _isSearchLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching: $e')),
        );
      }
    }
  }

  // handles sharing thoughts posts 
  Future<void> _shareThoughts() async {
    if (_isShareLoading) return;

    final thoughtsText = _thoughtsController.text.trim();
    if (thoughtsText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write your thoughts before sharing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isShareLoading = true;
    });

    try {
      // Create thoughts post service
      final thoughtsService = ThoughtsService();
      
      // Call API to create thoughts post
      final result = await thoughtsService.createThoughts(
        thoughtsText: thoughtsText,
        coverImage: _selectedCoverImage,
        songName: _selectedSongName,
        artistName: _selectedArtistName,
        trackId: _selectedTrackId,
        inAFanbase: false,
        fanbaseID: null,
        context: context,
      );
      
      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Thoughts shared successfully!'),
              backgroundColor: const Color(0xFF8E08EF),
            ),
          );
          

          _thoughtsController.clear();
          setState(() {
            _selectedCoverImage = null;
            _showImageSearch = false;
            _searchResults = null;
          });
          
          
          context.go(AppRoutes.home);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to share thoughts'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error sharing thoughts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing thoughts: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isShareLoading = false;
        });
      }
    }
  }
  
  // header icon and title
  Widget _buildHeader(ColorScheme colorScheme) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.purpleAccent.withOpacity(0.9),
                    Colors.deepPurple.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purpleAccent.withOpacity(0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.lightbulb_outline,
              size: 54,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.deepPurple.withOpacity(0.4),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            Positioned(
              bottom: 14,
              right: 18,
              child: Icon(
                Icons.music_note_rounded,
                size: 32,
                color: Colors.purpleAccent.shade100,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Share Your Thoughts',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Express your ideas, feelings',
          style: TextStyle(
            fontSize: 16,
            color: colorScheme.onPrimary.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // thoughts text input area
  Widget _buildThoughtsInput(ThemeData theme, ColorScheme colorScheme) {
    return Expanded(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.onPrimary.withOpacity(0.2),
          ),
        ),
        child: TextField(
          controller: _thoughtsController,
          maxLines: null,
          expands: true,
          style: TextStyle(color: colorScheme.onPrimary),
          decoration: InputDecoration(
            hintText: 'What\'s on your mind? Share your thoughts here...',
            hintStyle: TextStyle(
              color: colorScheme.onPrimary.withOpacity(0.5),
            ),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  //add cover image button
  Widget _buildAddImageButton(ThemeData theme, ColorScheme colorScheme) {
    if (_showImageSearch) return const SizedBox.shrink();
    
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          _showImageSearch = true;
        });
      },
      icon: const Icon(Icons.image),
      label: const Text('Add Song'),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.cardColor.withOpacity(0.2),
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  //  image search interface
  Widget _buildImageSearch(ThemeData theme, ColorScheme colorScheme) {
    if (!_showImageSearch) return const SizedBox.shrink();
    
    return Column(
      children: [
        const SizedBox(height: 16),
        const SizedBox(height: 8),
        _buildSearchField(theme, colorScheme),
        _buildSearchResults(colorScheme),
      ],
    );
  }

  // search text field
  Widget _buildSearchField(ThemeData theme, ColorScheme colorScheme) {
    return TextField(
      controller: _searchController,
      style: TextStyle(color: colorScheme.onPrimary),
      decoration: InputDecoration(
        hintText: 'Search for a song or artist...',
        hintStyle: TextStyle(color: colorScheme.onPrimary.withOpacity(0.5)),
        prefixIcon: Icon(Icons.search,
            color: colorScheme.onPrimary.withOpacity(0.5)),
        suffixIcon: _isSearchLoading
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
                icon: Icon(Icons.close,
                    color: colorScheme.onPrimary.withOpacity(0.5)),
                onPressed: () {
                  setState(() {
                    _showImageSearch = false;
                    _searchController.clear();
                    _searchResults = null;
                  });
                },
              ),
        filled: true,
        fillColor: theme.cardColor.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.onPrimary.withOpacity(0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.onPrimary.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  //search results list
  Widget _buildSearchResults(ColorScheme colorScheme) {
    if (_searchResults == null || _searchResults!['tracks'] == null) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: (_searchResults!['tracks']['items']?.length ?? 0),
            itemBuilder: (context, index) {
              final track = _searchResults!['tracks']['items'][index];
              if (track == null) return const SizedBox.shrink();
              
              final imageUrl = track['album'] != null && track['album'].toString().isNotEmpty
                  ? track['album']
                  : null;
              
              return _buildSearchResultItem(track, imageUrl, colorScheme);
            },
          ),
        ),
      ],
    );
  }

  //individual search result item
  Widget _buildSearchResultItem(Map<String, dynamic> track, String? imageUrl, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCoverImage = imageUrl;
          _selectedSongName = track['name'];
          _selectedArtistName = (track['artists'] is List)
              ? (track['artists'] as List).join(', ')
              : track['artists']?.toString();
          _selectedTrackId = track['id'];
          _showImageSearch = false;
          _searchController.clear();
          _searchResults = null;
        });
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 8),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey,
                          child: const Icon(Icons.music_note),
                        );
                      },
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey,
                      child: const Icon(Icons.music_note),
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              track['name'] ?? 'Unknown',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  //selected cover image display
  Widget _buildSelectedCoverImage() {
    if (_selectedCoverImage == null) return const SizedBox.shrink();
    
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          height: 100,
          width: 100,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _selectedCoverImage!,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCoverImage = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Noot'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.8),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildHeader(colorScheme),
              _buildThoughtsInput(theme, colorScheme),
              const SizedBox(height: 16),
              _buildAddImageButton(theme, colorScheme),
              _buildImageSearch(theme, colorScheme),
              _buildSelectedCoverImage(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ShareButton(
                  onPressed: _shareThoughts,
                  isLoading: _isShareLoading,
                  text: 'Share',
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        onSharePost: () {
          // Navigate to song post creation page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const CreatePostPage(),
            ),
          );
        },
        onShareThoughts: () {
          // Already on thoughts page 
        },
      ),
    );
  }
}