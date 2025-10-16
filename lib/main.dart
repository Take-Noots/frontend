import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'core/styles/theme.dart';
import 'data/services/auth_service.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/auth_provider.dart';

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

    // Create the router instance
    final appRouter = AppRouter(authProvider);

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
