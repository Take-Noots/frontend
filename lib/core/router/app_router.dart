import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/signup_screen.dart';
import '../../presentation/screens/auth/username_screen.dart';
import '../../presentation/screens/auth/link_spotify_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/search/search_feed_screen.dart';
import '../../presentation/screens/fanbase/fanbase.dart';
import '../../presentation/screens/fanbase/fanbase_details.dart';
import '../../presentation/screens/profile/my_profile.dart';
import '../../presentation/screens/profile/user_profiles.dart';
import '../../presentation/screens/profile/settings/edit_profile.dart';
import '../../presentation/screens/profile/settings/create_profile.dart';
import '../../presentation/screens/profile/settings/settings_page.dart';
import '../../presentation/screens/profile/settings/options.dart';
import '../../presentation/screens/profile/settings/privacy_page.dart';
import '../../presentation/screens/profile/settings/help_page.dart';
import '../../presentation/screens/profile/settings/about_page.dart';
import '../../presentation/screens/profile/settings/savedPosts/saved_posts.dart';
import '../../presentation/screens/profile/settings/hiddenPosts/hidden_posts.dart';
import '../../presentation/screens/request/request.dart';
import '../../presentation/screens/shell_screen_v2.dart';
import '../../presentation/screens/create_noots/search_song.dart';
import '../../presentation/screens/create_noots/create_description_noot.dart';
import 'route_names.dart';

/// Main application router configuration using GoRouter
class AppRouter {
  final AuthProvider authProvider;

  AppRouter(this.authProvider);

  late final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    refreshListenable: authProvider,
    initialLocation: AppRoutes.login,

    // Redirect logic for authentication
    redirect: (context, state) {
      print('[DEBUG] Router redirect called for: ${state.matchedLocation}');
      final isAuthenticated = authProvider.isAuthenticated;
      print('[DEBUG] isAuthenticated: $isAuthenticated');

      final isGoingToAuth = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/signup') ||
          state.matchedLocation.startsWith('/username') ||
          state.matchedLocation.startsWith('/link-spotify');

      // If not authenticated and not going to auth pages, redirect to login
      if (!isAuthenticated && !isGoingToAuth) {
        print('[DEBUG] Redirecting to login (not authenticated)');
        return AppRoutes.login;
      }

      // If authenticated and trying to access auth pages, redirect to home
      if (isAuthenticated && isGoingToAuth) {
        print('[DEBUG] Redirecting to home (already authenticated)');
        return AppRoutes.home;
      }

      print('[DEBUG] No redirect needed');
      return null; // No redirect needed
    },

    routes: [
      // Auth routes (outside shell - no bottom bar or music player)
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.username,
        builder: (context, state) => const UsernameScreen(),
      ),
      GoRoute(
        path: AppRoutes.linkSpotify,
        builder: (context, state) => const LinkSpotifyScreen(),
      ),

      // Edit Profile - OUTSIDE shell to prevent disposal issues
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfilePage(),
      ),

      // Main app shell with persistent bottom bar and music player
      ShellRoute(
        builder: (context, state, child) {
          // Hide bottom bar for create noot routes
          final isCreateRoute =
              state.matchedLocation.startsWith('/create-noot');
          return ShellScreenV2(
            hideBottomBar: isCreateRoute,
            child: child,
          );
        },
        routes: [
          // Home
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => HomeScreen(inShell: true),
          ),

          // Search
          GoRoute(
            path: AppRoutes.search,
            builder: (context, state) => const SearchFeedScreen(),
          ),

          // Fanbases - using Navigator.push for complex routes
          GoRoute(
            path: AppRoutes.fanbaseList,
            builder: (context, state) => const FanbasePage(),
          ),

          // Individual Fanbase Details
          GoRoute(
            path: '${AppRoutes.fanbaseList}/:fanbaseId',
            builder: (context, state) {
              final fanbaseId = state.pathParameters['fanbaseId']!;
              final userId = state.uri.queryParameters['userId'] ?? '';

              return FanbaseDetailScreen(
                fanbaseId: fanbaseId,
                userId: userId,
              );
            },
          ),

          // Profile routes
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const NormalUserProfilePage(),
            routes: [
              GoRoute(
                path: 'user/:userId',
                builder: (context, state) {
                  final userId = state.pathParameters['userId']!;
                  final postId = state.uri.queryParameters['postId'];
                  return UserProfilePage(
                      userId: userId, highlightPostId: postId);
                },
              ),
              GoRoute(
                path: 'create',
                builder: (context, state) => const CreateProfilePage(),
              ),
              GoRoute(
                path: 'settings',
                builder: (context, state) => const SettingsPage(),
              ),
              GoRoute(
                path: 'options',
                builder: (context, state) => const OptionsPage(),
              ),
              GoRoute(
                path: 'privacy',
                builder: (context, state) => const PrivacyPage(),
              ),
              GoRoute(
                path: 'help',
                builder: (context, state) => const HelpPage(),
              ),
              GoRoute(
                path: 'about',
                builder: (context, state) => const AboutPage(),
              ),
              GoRoute(
                path: 'saved-posts',
                builder: (context, state) {
                  final authProvider =
                      Provider.of<AuthProvider>(context, listen: false);
                  final userId = authProvider.user?.id ?? '';
                  return SavedPostsPage(userId: userId);
                },
              ),
              GoRoute(
                path: 'hidden-posts',
                builder: (context, state) => const HiddenPostsPage(),
              ),
            ],
          ),

          // Requests
          GoRoute(
            path: AppRoutes.requests,
            builder: (context, state) => const RequestScreen(),
          ),

          // Create Noot routes
          GoRoute(
            path: AppRoutes.createNoot,
            builder: (context, state) => const CreatePostPage(),
          ),
          GoRoute(
            path: AppRoutes.searchSong,
            builder: (context, state) => const CreatePostPage(),
          ),
          GoRoute(
            path: AppRoutes.createDescriptionNoot,
            builder: (context, state) => const CreateDescriptionNootPage(),
          ),
        ],
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.uri.toString()),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
