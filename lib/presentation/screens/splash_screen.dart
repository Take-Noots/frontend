import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Noot/core/providers/auth_provider.dart';
import 'package:Noot/data/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;
  final Widget authScreen;

  const SplashScreen({
    Key? key,
    required this.nextScreen,
    required this.authScreen,
  }) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isInitializing = true;
  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    _initializeAuthService();
  }

  Future<void> _initializeAuthService() async {
    _authService = Provider.of<AuthService>(context, listen: false);

    try {
      // Initialize auth service and attempt to load/refresh tokens
      await _authService.initialize();

      // Small delay to ensure smooth transition
      await Future.delayed(const Duration(milliseconds: 500));

      // Check authentication status after initialization
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuthenticated && mounted) {
        // Redirect to login screen by setting _isInitializing to false
        setState(() {
          _isInitializing = false;
        });
        // Optionally, you could use Navigator to push the authScreen here if you want an immediate redirect
        // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => widget.authScreen));
        return;
      }

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing auth service: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If still initializing, show splash screen
    if (_isInitializing) {
      return _buildSplashScreen();
    }

    // Check if authenticated to determine which screen to show next
    final authProvider = Provider.of<AuthProvider>(context);
    return authProvider.isAuthenticated ? widget.nextScreen : widget.authScreen;
  }

  Widget _buildSplashScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Image.asset(
              'assets/images/logo_white.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
