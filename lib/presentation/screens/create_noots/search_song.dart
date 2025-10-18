
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:convert';


import '/data/services/spotify_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/profile_service.dart';
import '../../../data/models/profile_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../widgets/create_post/button.dart';
import '../../widgets/common/musicplayer_bar.dart';
import 'create_new_noot.dart';
import 'create_description_noot.dart';
import '../../../core/router/route_names.dart';


class CreatePostPage extends StatefulWidget {
  const CreatePostPage({Key? key}) : super(key: key);

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {

  // Controller for song search input
  final TextEditingController _searchController = TextEditingController();

  //Loading state for API calls
  bool _isLoading = false;

  //store the search results from Spotify API
  Map<String, dynamic>? _searchResults;

  //a timer to avoid searching too frequently
  Timer? _debounce;

  // User type for conditional UI
  String? userType;
  bool isProfileLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchUserType();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Fetch user type from profile
  Future<void> _fetchUserType() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      if (userId == null) {
        setState(() {
          isProfileLoading = false;
        });
        return;
      }

      final profileService = ProfileService();
      final profileResult = await profileService.getUserProfile(userId);

      if (profileResult['success'] == true && profileResult['data'] != null) {
        final profile = ProfileModel.fromJson(profileResult['data']);
        setState(() {
          userType = profile.userType;
          isProfileLoading = false;
        });
      } else {
        setState(() {
          isProfileLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isProfileLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching profile: $e')),
        );
      }
    }
  }

  //waits for 600ms after user stops typing, then searches for songs
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

  //search songs using Spotify API
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

  
  Widget _buildSharePostInterface(ColorScheme colorScheme, ThemeData theme) {
    return Column(
      children: [
        // Song search input field
        TextField(
          controller: _searchController,
          style: TextStyle(color: colorScheme.onPrimary),
          decoration: InputDecoration(
            hintText: 'Search for a song or artist...',
            hintStyle: TextStyle(color: colorScheme.onPrimary.withOpacity(0.5)),
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
              borderSide: BorderSide(color: colorScheme.onPrimary.withOpacity(0.4)),
            ),
          ),
        ),
        
        // Search results list
        if (_searchResults != null) ...[
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults?['tracks']?['items']?.length ?? 0,
              itemBuilder: (context, index) {
                final track = _searchResults?['tracks']?['items']?[index];
                if (track == null) return const SizedBox.shrink();
                
                return ListTile(
                  leading: track['album'] != null && track['album'].toString().isNotEmpty
                      ? Image.network(
                          track['album'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : const SizedBox(width: 50, height: 50),
                  title: Text(
                    track['name'] ?? 'Unknown Track',
                    style: TextStyle(color: colorScheme.onPrimary),
                  ),
                  subtitle: Text(
                    track['artists'] is List
                        ? track['artists'].join(', ')
                        : track['artists']?.toString() ?? 'Unknown Artist',
                    style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.6)),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateNewNootPage(track: track),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Songs'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate back to home
            context.go(AppRoutes.home);
          },
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildSharePostInterface(colorScheme, theme),
      ),
      bottomNavigationBar: CustomBottomBar(
        onSharePost: () {
          // Already on search song page - do nothing
        },
        onShareThoughts: () {
          // Navigate to thoughts creation page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateDescriptionNootPage(),
            ),
          );
        },
        onMakeAdvertisements: userType == 'business' ? () => context.go(AppRoutes.createAdvertisement) : null,
      ),
    );
  }
}
