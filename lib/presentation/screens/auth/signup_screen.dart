import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/auth/custom_text_form_field.dart';
import '../../widgets/auth/custom_button.dart';
import '../../widgets/auth/custom_snack_bar.dart';
import '../../../core/utils/temp_storage.dart';
import '../../../data/services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<bool> _validateInputs() async {
    final authService = context.read<AuthService>();

    // Check if email is already registered
    final email = _emailController.text.trim();
    if (email.isNotEmpty) {
      final isEmailTaken = await authService.isEmailRegistered(email);
      if (isEmailTaken) {
        // Show error message to user using CustomSnackBar
        CustomSnackBar.show(
          context,
          title: 'Error',
          text: 'This email is already registered',
          type: SnackBarType.destructive,
        );
        return false;
      }
    }

    return true;
  }

  void handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final isValid = await _validateInputs();
    if (!isValid) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Store credentials temporarily in secure storage
    TempStorage.store('signup_email', _emailController.text.trim());
    TempStorage.store('signup_password', _passwordController.text);

    setState(() {
      _isLoading = false;
    });

    // Navigate to username screen without sensitive data
    Navigator.pushNamed(context, '/username');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent automatic resizing
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
          // Scrollable content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom -
                      40,
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // App Logo
                        Padding(
                          padding: EdgeInsets.only(
                              left: 20.0, bottom: 40.0, top: 20.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Image.asset(
                              'assets/images/logo.png',
                              height: 40,
                            ),
                          ),
                        ),

                        // Title
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Description
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text(
                            'Start your journey of rediscovering music socially',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),

                        const SizedBox(height: 32),

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
                              final emailRegex = RegExp(
                                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

                              if (!emailRegex.hasMatch(value)) {
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

                        const SizedBox(height: 6),

                        // Confirm Password Field
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: CustomTextFormField(
                            controller: _confirmPasswordController,
                            hintText: 'Confirm your password',
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Signup Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: CustomButton(
                            onPressed: handleRegister,
                            isLoading: _isLoading,
                            text: 'Sign Up',
                          ),
                        ),

                        const SizedBox(height: 10),

                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                            ),
                            child: const Text(
                              "Already have an account?",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
