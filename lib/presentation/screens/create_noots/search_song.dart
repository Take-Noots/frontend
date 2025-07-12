import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '/data/services/spotify_service.dart';
import 'dart:async';
import 'create_new_noot.dart';
import '../../widgets/create_post/button.dart';
import '../../widgets/common/musicplayer_bar.dart';
import 'package:provider/provider.dart';
import '../../../data/services/auth_service.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({Key? key}) : super(key: key);

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _searchResults;
  Timer? _debounce;

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
            SnackBar(content: Text('Error searching: ${response.statusCode}')),
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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

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

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Noots'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // MusicPlayerBar(title: 'Now Playing', playing: false),
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
            if (_searchResults != null) ...[
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _searchResults?['tracks']?['items']?.length ?? 0,
                  itemBuilder: (context, index) {
                    final track = _searchResults?['tracks']?['items']?[index];
                    if (track == null) return const SizedBox.shrink();
                    return ListTile(
                      leading: track['album'] != null &&
                              track['album'].toString().isNotEmpty
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
                        style: TextStyle(
                            color: colorScheme.onPrimary.withOpacity(0.6)),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CreateNewNootPage(track: track),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        onSharePost: () {},
        onShareThoughts: () {},
      ),
    );
  }
}
