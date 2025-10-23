import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/auth/custom_text_form_field.dart';
import '../../widgets/auth/custom_button.dart';
import '../../widgets/auth/custom_snack_bar.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/temp_storage.dart';
import '../../../core/router/route_names.dart';

class UsernameScreen extends StatefulWidget {
  const UsernameScreen({Key? key}) : super(key: key);

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _usernameError;

  @override
  void dispose() {
    _usernameController.dispose();
    // Clear sensitive data when leaving the screen
    TempStorage.remove('signup_email');
    TempStorage.remove('signup_password');
    super.dispose();
  }

  Future<bool> _validateUsername() async {
    final authService = context.read<AuthService>();

    // Check if username is already registered
    final username = _usernameController.text.trim();
    if (username.isNotEmpty) {
      final isUsernameTaken = await authService.isUsernameRegistered(username);
      if (isUsernameTaken) {
        setState(() {
          _usernameError = 'This username is already taken';
        });

        // Show error message to user using CustomSnackBar
        CustomSnackBar.show(
          context,
          title: 'Error',
          text: 'This username is already taken',
          type: SnackBarType.destructive,
        );
        return false;
      }
    }

    // Clear any previous username error
    setState(() {
      _usernameError = null;
    });

    return true;
  }

  void handleContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Validate username availability
    final isUsernameValid = await _validateUsername();
    if (!isUsernameValid) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Save username to temporary storage
    TempStorage.store('signup_username', _usernameController.text.trim());

    setState(() {
      _isLoading = false;
    });

    // Navigate to terms and service screen
    context.push(AppRoutes.terms);
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
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo
                  Padding(
                    padding:
                        EdgeInsets.only(left: 20.0, bottom: 40.0, top: 20.0),
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
                    child: Text(
                      'Enter Username',
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
                      'Pick something that defines you. Make it unique!',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Username Field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: CustomTextFormField(
                      controller: _usernameController,
                      hintText: 'Enter your username',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your username';
                        }
                        if (value.length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Continue Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: CustomButton(
                      onPressed: handleContinue,
                      isLoading: _isLoading,
                      text: 'Continue',
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
          ),
        ],
      ),
    );
  }
}
