/* Note:
SafeArea should be applied inside each screen's Scaffold body (e.g., HomeScreen, CreatePostPage)
to prevent UI from being obscured by device notches, status bars, or system UI elements.

class ExampleScreen extends StatelessWidget {
  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Text('Hello, SafeArea!'),
        ),
      ),
    );
  }
}

*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'presentation/screens/home_screen.dart';

import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/signup_screen.dart';

import 'presentation/screens/create_noots/search_song.dart';
import 'core/styles/theme.dart';
import 'data/services/spotify_service.dart';
// import 'data/services/auth_service.dart';
import 'core/constants/app_constants.dart';

import 'core/providers/theme_provider.dart'; // Theme provider
import 'core/providers/auth_provider.dart'; // Auth provider for global access
import 'core/providers/user_profile_provider.dart'; // User profile provider
import 'presentation/screens/fanbase/fanbase.dart';
import 'presentation/screens/profile/normal_user.dart';
// import 'package:frontend/presentation/screens/search/search_feed_screen.dart';
import 'presentation/widgets/despost/demo.dart';
import 'presentation/screens/search/search_feed_screen.dart';
import 'presentation/widgets/view_song_post/feed.dart';
import 'presentation/screens/show_all_posts_screen.dart';
import 'presentation/screens/fanbase/fanbase_details.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Noot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '');
        if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'fanbase') {
          final id = uri.pathSegments[1];
          return MaterialPageRoute(
            builder: (_) => FanbaseDetailScreen(fanbaseId: id),
          );
        }

        // Add other routes
        switch (settings.name) {
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          // case '/signup':
          //   return MaterialPageRoute(builder: (_) => const SignupScreen());
          case '/create':
            return MaterialPageRoute(
              builder: (_) => CreatePostPage(
                spotifyService: SpotifyService(
                  accessToken: AppConstants.spotifyAccessToken,
                ),
              ),
            );
          case '/fanbases':
            return MaterialPageRoute(builder: (_) => FanbasePage());
          case '/profile':
            return MaterialPageRoute(builder: (_) => NormalUserProfilePage());
          case '/search':
            return MaterialPageRoute(builder: (_) => SearchFeedScreen());
          case '/demodespost':
            return MaterialPageRoute(builder: (_) => DemoScreen2());
          case '/feed':
            return MaterialPageRoute(builder: (_) => FeedPage());
          case '/showpost':
            return MaterialPageRoute(
                builder: (_) => const ShowAllPostsScreen());
          default:
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                body: Center(child: Text('Page not found: ${settings.name}')),
              ),
            );
        }
      },
      initialRoute: '/home',
    );
  }
}
