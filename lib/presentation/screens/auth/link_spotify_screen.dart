import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:Noot/data/services/auth_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/router/route_names.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/services/profile_service.dart';
import '../../widgets/auth/custom_button.dart';
// Conditional import for openSpotifyAuth
import 'link_spotify_mobile.dart'
    if (dart.library.html) 'link_spotify_web.dart';

class LinkSpotifyScreen extends StatelessWidget {
  const LinkSpotifyScreen({Key? key}) : super(key: key);

  /// Check if user has a profile and navigate accordingly
  Future<void> _checkProfileAndNavigate(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;

    if (userId != null) {
      try {
        final profileService = ProfileService();
        final profileResult = await profileService.getUserProfile(userId);

        if (context.mounted) {
          if (profileResult['success'] == false ||
              profileResult['data'] == null) {
            // No profile exists, go to create profile
            context.go(AppRoutes.createProfile);
            return;
          }
        }
      } catch (e) {
        // If error checking profile, still allow navigation to home
        print('[DEBUG] Error checking profile: $e');
      }
    }

    // Profile exists or couldn't check, continue to home
    if (context.mounted) {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _handleLinkSpotify(BuildContext context) async {
    try {
      if (kIsWeb) {
        // On web, use openSpotifyAuth from conditional import
        final backendUrl = 'http://localhost:3000/spotify/login/alt';
        openSpotifyAuth(backendUrl);
        // Check authentication and profile before redirecting
        if (context.mounted) {
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          if (authProvider.isAuthenticated) {
            await _checkProfileAndNavigate(context);
          } else {
            context.go(AppRoutes.login);
          }
        }
        return;
      }
      final authService = Provider.of<AuthService>(context, listen: false);
      final dio = authService.dio; // Authenticated Dio instance
      final response = await dio.post('/spotify/login');
      if (response.statusCode == 200) {
        final data = response.data;
        final regex = RegExp(r'Redirecting to (https?://\S+)');
        final match = regex.firstMatch(data.toString());
        final url = match != null ? match.group(1) : null;
        if (url != null) {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url),
                mode: LaunchMode.externalApplication);
            // Check authentication and profile before redirecting
            if (context.mounted) {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              if (authProvider.isAuthenticated) {
                await _checkProfileAndNavigate(context);
              } else {
                context.go(AppRoutes.login);
              }
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to get Spotify redirect URL.')),
          );
        }
      } else if (response.statusCode == 302 &&
          response.headers['location'] != null) {
        final url = response.headers['location']!.first;
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          // Check authentication and profile before redirecting
          if (context.mounted) {
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            if (authProvider.isAuthenticated) {
              await _checkProfileAndNavigate(context);
            } else {
              context.go(AppRoutes.login);
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to launch Spotify authorization URL.')),
          );
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'You must be logged in to link Spotify. Please log in first.')),
        );
        context.go(AppRoutes.login);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initiate Spotify login.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          SizedBox.expand(
            child: Image.asset(
              'assets/backgrounds/black-and-green-background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // 50% opacity black overlay
          Container(
            color: Colors.black.withOpacity(0.8),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.9),
              borderRadius: BorderRadius.circular(40),
            ),
          ),
          // Existing widget content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Link account',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 36.0),
                  child: Text(
                    'Inorder to access more features, a spotify account is required.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 30),
                // Replace ElevatedButton with CustomButton
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: CustomButton(
                    onPressed: () => _handleLinkSpotify(context),
                    isLoading: false,
                    text: 'Link Spotify',
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32.0, vertical: 18.0),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Check authentication and profile before redirecting
                      final authProvider =
                          Provider.of<AuthProvider>(context, listen: false);
                      if (authProvider.isAuthenticated) {
                        await _checkProfileAndNavigate(context);
                      } else {
                        context.go(AppRoutes.login);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                    ),
                    child: const Text(
                      "Skip for now",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
