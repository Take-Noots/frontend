import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/screens/shell_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/signup_screen.dart';
import 'presentation/screens/auth/username_screen.dart';
import 'presentation/screens/auth/terms_screen.dart';
import 'presentation/screens/auth/link_spotify_screen.dart';
import 'presentation/screens/create_noots/search_song.dart';
import 'core/styles/theme.dart';
import 'data/services/auth_service.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/auth_provider.dart';
import 'presentation/screens/profile/my_profile.dart';
import 'presentation/screens/search/search_feed_screen.dart';
import 'presentation/screens/fanbase/fanbase_details.dart';
import 'presentation/screens/splash_screen.dart';
import '/presentation/screens/fanbase/fanbase.dart';
import 'presentation/screens/request/request.dart';
import 'presentation/screens/notifications/notifications_screen.dart';
import 'data/helpers/notification_helper.dart';
import 'data/services/notification_manager.dart'; // Add this import


void main() async {
  // Ensure Flutter bindings are initialized before accessing plugins
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  await NotificationHelper.init();

  // Create providers
  final authProvider = AuthProvider();
  final themeProvider = ThemeProvider();

  // Create auth service
  final authService = AuthService(authProvider);

  // Initialize services
  authService.initialize().then((_) {
    // Initialize notification manager after auth is ready
    if (authProvider.isAuthenticated) {
      NotificationManager.instance.initialize().catchError((e) {
        debugPrint('Error initializing notification manager: $e');
      });
    }
  }).catchError((e) {
    debugPrint('Error initializing auth service: $e');
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: authProvider),
        Provider.value(value: authService),
        // Add notification manager as a provider
        Provider.value(value: NotificationManager.instance),
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

    // Listen to auth state changes to initialize/dispose notification manager
    authProvider.addListener(() {
      if (authProvider.isAuthenticated) {
        NotificationManager.instance.initialize();
      } else {
        NotificationManager.instance.dispose();
      }
    });

    return MaterialApp(
      title: 'Noot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(
        nextScreen: ShellScreen(),
        authScreen: LoginScreen(),
      ),
      onGenerateRoute: (settings) {
        // Route protection logic
        final isAuthenticated = authProvider.isAuthenticated;

        // List of protected routes that require authentication
        final protectedRoutes = ['/home', '/link-account', '/demodespost', '/notifications'];

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
          return MaterialPageRoute(
            builder: (_) => FanbaseDetailScreen(fanbaseId: id),
          );
        }

        // Add other routes
        switch (settings.name) {
          case '/home':
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
          case '/notifications':
            return MaterialPageRoute(builder: (_) => const NotificationsScreen());
          case '/request':
            return MaterialPageRoute(builder: (_) => const RequestScreen());
          case '/link-account':
            return MaterialPageRoute(builder: (_) => const LinkSpotifyScreen());
          default:
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                body: Center(child: Text('Page not found: ${settings.name}')),
              ),
            );
        }
      },
    );
  }
}