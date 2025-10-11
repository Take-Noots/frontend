import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'presentation/screens/shell_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/signup_screen.dart';
import 'presentation/screens/auth/username_screen.dart';
import 'presentation/screens/auth/terms_screen.dart';
import 'presentation/screens/auth/link_spotify_screen.dart';
import 'presentation/screens/create_noots/search_song.dart';
import 'core/styles/theme.dart';
// import 'data/services/spotify_service.dart';
import 'data/services/auth_service.dart';
// import 'core/constants/app_constants.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/auth_provider.dart';
import 'presentation/screens/profile/my_profile.dart';
import 'presentation/screens/profile/settings/hiddenPosts/hidden_posts.dart';
import 'presentation/screens/search/search_feed_screen.dart';
import 'presentation/screens/fanbase/fanbase_details.dart';
import 'presentation/screens/splash_screen.dart'; // Import the SplashScreen
import '/presentation/screens/fanbase/fanbase.dart';
import 'presentation/screens/request/request.dart';

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
      home: const SplashScreen(
        nextScreen: ShellScreen(), // Show this when authenticated
        authScreen: LoginScreen(), // Show this when not authenticated
      ),
      onGenerateRoute: (settings) {
        // Route protection logic
        final isAuthenticated = authProvider.isAuthenticated;

        // List of protected routes that require authentication
        final protectedRoutes = ['/home', '/link-account', '/demodespost'];

        // Redirect to login if trying to access protected route while not authenticated
        if (protectedRoutes.contains(settings.name) && !isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => const LoginScreen(),
            settings: const RouteSettings(name: '/login'),
          );
        }

        // Original route handling
        final uri = Uri.parse(settings.name ?? '');
        if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'fanbase') {
          final id = uri.pathSegments[1];
          // Get the current user ID from the auth provider
          final currentUserId = authProvider.user?.id ?? '';
          return MaterialPageRoute(
            builder: (_) =>
                FanbaseDetailScreen(fanbaseId: id, userId: currentUserId),
          );
        }

        // Add other routes
        switch (settings.name) {
          case '/home':
            // Use the shell screen instead of directly navigating to HomeScreen
            return MaterialPageRoute(builder: (_) => const ShellScreen());
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/signup':
            return MaterialPageRoute(builder: (_) => const SignupScreen());
          case '/username':
            return MaterialPageRoute(builder: (_) => const UsernameScreen());
          case '/terms':
            return MaterialPageRoute(builder: (_) => const TermsScreen());
          case '/create':
            return MaterialPageRoute(
              builder: (_) => const CreatePostPage(),
            );
          case '/fanbases':
            return MaterialPageRoute(builder: (_) => const FanbasePage());
          case '/profile':
            return MaterialPageRoute(
                builder: (_) => const NormalUserProfilePage());
          case '/search':
            return MaterialPageRoute(builder: (_) => const SearchFeedScreen());
          // case '/demodespost':
          //   return MaterialPageRoute(builder: (_) => HomeScreen2());
          // case '/feed':
          //   return MaterialPageRoute(builder: (_) => FeedPage());
          case '/request':
            return MaterialPageRoute(builder: (_) => const RequestScreen());
          case '/link-account':
            return MaterialPageRoute(builder: (_) => const LinkSpotifyScreen());
          case '/hidden-posts':
            return MaterialPageRoute(builder: (_) => const HiddenPostsPage());
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
