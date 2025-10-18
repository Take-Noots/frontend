import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/auth/custom_button.dart';
import '../../widgets/auth/custom_snack_bar.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/router/route_names.dart';
import '../../../core/utils/temp_storage.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({Key? key}) : super(key: key);

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _isLoading = false;
  bool _agreedToTerms = false;
  String _termsText = '';

  @override
  void initState() {
    super.initState();
    _loadTermsText();
  }

  Future<void> _loadTermsText() async {
    try {
      final text =
          await rootBundle.loadString('assets/texts/terms_and_conditions.txt');
      setState(() {
        _termsText = text;
      });
    } catch (e) {
      print('Error loading terms and conditions: $e');
      setState(() {
        _termsText =
            'Error loading terms and conditions. Please try again later.';
      });
    }
  }

  @override
  void dispose() {
    // Clear sensitive data when leaving the screen
    TempStorage.remove('signup_email');
    TempStorage.remove('signup_password');
    TempStorage.remove('signup_username');
    super.dispose();
  }

  void handleContinue() async {
    if (!_agreedToTerms) {
      CustomSnackBar.show(
        context,
        title: 'Error',
        text: 'Please agree to the terms and conditions',
        type: SnackBarType.destructive,
      );
      return;
    }

    // Get credentials from temporary storage
    final email = TempStorage.get<String>('signup_email');
    final password = TempStorage.get<String>('signup_password');
    final username = TempStorage.get<String>('signup_username');

    if (email == null || password == null || username == null) {
      CustomSnackBar.show(
        context,
        title: 'Error',
        text: 'Session expired. Please try again.',
        type: SnackBarType.destructive,
      );
      Navigator.pushReplacementNamed(context, '/signup');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await authService.register(
        email,
        username,
        password,
      );

      // Clear sensitive data after use
      TempStorage.remove('signup_email');
      TempStorage.remove('signup_password');
      TempStorage.remove('signup_username');

      if (response['success'] == true) {
        CustomSnackBar.show(
          context,
          title: 'Success',
          text: 'Registration successful!',
          type: SnackBarType.success,
        );

        // Check if user is authenticated in auth provider
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.isAuthenticated) {
          context.go(AppRoutes.linkSpotify);
        } else {
          context.go(AppRoutes.login);
        }
      } else {
        CustomSnackBar.show(
          context,
          title: 'Error',
          text: response['message'] ?? 'Registration failed',
          type: SnackBarType.destructive,
        );
      }
    } catch (e) {
      CustomSnackBar.show(
        context,
        title: 'Error',
        text: 'Registration failed. Please try again.',
        type: SnackBarType.destructive,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
              'assets/backgrounds/purple-black-painting.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // 0.8 opacity black overlay
          Container(
            color: Colors.black.withOpacity(0.8),
          ),
          // 0.9 opacity black container with border radius and margin
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 60),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.9),
              borderRadius: BorderRadius.circular(40),
            ),
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Logo
                Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 40,
                    ),
                  ),
                ),

                // Title
                const Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.left,
                ),

                const SizedBox(height: 16),

                // Description
                const Text(
                  'Please read and accept our terms and conditions',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.left,
                ),

                const SizedBox(height: 32),

                // Terms content
                Container(
                  height: 300, // Fixed height
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF212121),
                    borderRadius: BorderRadius.circular(15.0),
                    border: Border.all(color: const Color(0xFF424242)),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _termsText.isEmpty
                          ? 'Loading terms and conditions...'
                          : _termsText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Agreement checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreedToTerms = value ?? false;
                        });
                      },
                      checkColor: Colors.white,
                      fillColor: MaterialStateProperty.resolveWith((states) {
                        if (states.contains(MaterialState.selected)) {
                          return Colors.purple;
                        }
                        return Colors.transparent;
                      }),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    const Expanded(
                      child: Text(
                        'I agree to the Terms and Conditions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Complete Registration Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: CustomButton(
                    onPressed: handleContinue,
                    isLoading: _isLoading,
                    text: 'Complete Registration',
                  ),
                ),

                const SizedBox(height: 10),

                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                    ),
                    child: const Text(
                      "Go Back",
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
