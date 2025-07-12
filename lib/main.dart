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
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'presentation/screens/shell_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/create_noots/search_song.dart';
import 'core/styles/theme.dart';
import 'data/services/spotify_service.dart';
import 'data/services/auth_service.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/auth_provider.dart';
import 'presentation/screens/fanbase/fanbase.dart';
import 'presentation/screens/profile/normal_user.dart';
// import 'package:frontend/presentation/screens/search/search_feed_screen.dart';
import 'presentation/widgets/despost/demo.dart';
import 'presentation/screens/search/search_feed_screen.dart';
import 'presentation/widgets/song_post/feed.dart';
import 'presentation/screens/show_all_posts_screen.dart';
import 'presentation/screens/fanbase/fanbase_details.dart';
import 'presentation/screens/splash_screen.dart'; // Import the SplashScreen

void main() async {
  // Ensure Flutter bindings are initialized before accessing plugins
  WidgetsFlutterBinding.ensureInitialized();

  // Create providers
  final authProvider = AuthProvider();
  final themeProvider = ThemeProvider();

  // Create auth service
  final authService = AuthService(authProvider);

  // Initialize services (but don't wait for completion - splash screen will handle this)
  authService.initialize().catchError((e) {
    debugPrint('Error initializing auth service: $e');
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: authProvider),
        Provider.value(value: authService),
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
    final authProvider = Provider.of<AuthProvider>(context);

    // Use SplashScreen as the initial entry point for the app
    return MaterialApp(
      title: 'Noot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: SplashScreen(
        nextScreen: const ShellScreen(), // Show this when authenticated
        authScreen: const LoginScreen(), // Show this when not authenticated
      ),
      onGenerateRoute: (settings) {
        // Route protection logic
        final isAuthenticated = authProvider.isAuthenticated;

        // List of protected routes that require authentication
        final protectedRoutes = ['/home', '/demodespost'];

        // Redirect to login if trying to access protected route while not authenticated
        if (protectedRoutes.contains(settings.name) && !isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => const LoginScreen(),
            settings: RouteSettings(name: '/login'),
          );
        }

        // Original route handling
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
            // Use the shell screen instead of directly navigating to HomeScreen
            return MaterialPageRoute(builder: (_) => const ShellScreen());
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          // case '/signup':
          //   return MaterialPageRoute(builder: (_) => const SignupScreen());
          case '/create':
            return MaterialPageRoute(
              builder: (_) => CreatePostPage(),
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
      // Remove initialRoute as we're using home with SplashScreen instead
    );
  }
}
