import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/router/route_names.dart';
import '../../../data/services/auth_service.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../widgets/auth/custom_text_form_field.dart';
import '../../widgets/auth/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AuthService _authService;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the AuthService from the provider
    _authService = Provider.of<AuthService>(context, listen: false);
  }

  void handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final email = _emailController.text.trim();
      final password = _passwordController.text;

      try {
        final response = await _authService.login(email, password);

        // print('Login response: $response');

        if (response['status'] == 200) {
          // Print success message to console
          print('Login successful: ${response['message']}');

          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);

          // // Update the AuthProvider with the user data and token from the response.
          // if (response['user'] != null && response['token'] != null) {
          //   authProvider.login(response['user'], response['token']);
          // }

          // Check if user is authenticated in auth provider
          if (authProvider.isAuthenticated && authProvider.user != null) {
            // Navigate to home screen using GoRouter
            context.go(AppRoutes.home);
          } else {
            print('Authentication failed: User not stored in AuthProvider');
            throw Exception('Error occurred in authentication process');
          }
        } else {
          // Show error message
          print('Login failed: ${response['message']}');
          throw Exception('${response['message']}');
        }
      } catch (e) {
        print('Login error: $e');
        String errorMsg = e.toString();
        // If error contains "Login failed: Failed to login user :"
        if (errorMsg.contains('Invalid credentials - User not found')) {
          errorMsg = "Invalid credentials - User not found";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
          // Existing widget content
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40.0),
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 40,
                    ),
                  ),

                  // Email Field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: CustomTextFormField(
                      controller: _emailController,
                      hintText: 'Enter your email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Password Field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: CustomTextFormField(
                      controller: _passwordController,
                      hintText: 'Enter your password',
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Forgot password functionality would go here
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ),

                  // Login Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: CustomButton(
                      onPressed: handleLogin,
                      isLoading: _isLoading,
                      text: 'Login',
                    ),
                  ),

                  const SizedBox(height: 10),
                  // Don't have an account button
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                      ),
                      child: const Text(
                        "Don't have an account?",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
