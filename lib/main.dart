import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'core/styles/theme.dart';
import 'data/services/auth_service.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/feed_provider.dart';
import 'core/providers/profile_provider.dart';

void main() async {
  // Ensure Flutter bindings are initialized before accessing plugins
  WidgetsFlutterBinding.ensureInitialized();

  // Configure URL strategy for web (removes hash from URLs)
  if (kIsWeb) {
    // For Flutter 3.x+, go_router handles this automatically
    // No additional configuration needed
  }

  // Create providers
  final authProvider = AuthProvider();
  final themeProvider = ThemeProvider();
  final feedProvider = FeedProvider();
  final profileProvider = ProfileProvider();

  // Load user data and theme preferences from shared preferences
  await authProvider.loadUserDataFromSharedPreferences();
  await themeProvider.init();

  // Create auth service
  final authService = AuthService(authProvider);

  // Create the router instance
  final appRouter = AppRouter(authProvider);

  // Initialize services (but don't wait for completion - splash screen will handle this)
  authService.initialize().catchError((e) {
    debugPrint('Error initializing auth service: $e');
  });

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: themeProvider),
      ChangeNotifierProvider.value(value: authProvider),
      ChangeNotifierProvider.value(value: feedProvider),
      ChangeNotifierProvider.value(value: profileProvider),
      Provider.value(value: authService),
    ],
    child: MyApp(appRouter: appRouter),
  ));
}

class MyApp extends StatelessWidget {
  final AppRouter appRouter;

  const MyApp({Key? key, required this.appRouter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp.router(
      title: 'Noot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: appRouter.router,
    );
  }
}
