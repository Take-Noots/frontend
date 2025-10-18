import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/auth_provider.dart';
import 'token_manager_service.dart';

class AuthService {
  final AuthProvider authProvider;
  late TokenManagerService _tokenManager;

  // Constructor now requires authProvider
  AuthService(this.authProvider) {
    _tokenManager = TokenManagerService(authProvider);
  }

  // Initialize the service and check for stored tokens
  Future<void> initialize() async {
    try {
      await _tokenManager.initialize();
    } catch (e) {
      debugPrint('Error initializing AuthService: $e');
      rethrow;
    }
  }

  // Get the token manager for direct access when needed
  TokenManagerService get tokenManager => _tokenManager;

  // Helper function to get specific error messages based on DioException type
  String _getConnectionErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Server is taking too long to respond.';
      case DioExceptionType.sendTimeout:
        return 'Send timeout. Request is taking too long to send.';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout. Server response is taking too long.';
      case DioExceptionType.connectionError:
        return 'Connection error. Unable to connect to server. ${e.message ?? ''}';
      case DioExceptionType.unknown:
        return 'Network error. ${e.message ?? 'Please check your internet connection.'}';
      default:
        return 'Connection error. Please check your connection and try again.';
    }
  }

  // Login with credentials and handle token storage
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _tokenManager.unauthenticatedDio.post(
        '${AppConstants.baseUrl}/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        final String? token = responseData['accessToken'];

        if (token != null) {
          // Save token to secure storage and memory
          await _tokenManager.saveAccessToken(token);

          // Update user data in auth provider
          authProvider.setUser(responseData['user']);

          // Set the token and update authentication status to true
          authProvider.setToken(token);

          // Return both token and user data
          return {
            'status': 200, // Using status for consistency with login_screen
            'success': true,
            'user': responseData['user'],
            'token': token,
            'message': responseData['message'] ?? 'Login successful'
          };
        } else {
          return {'success': false, 'message': 'Token not found in response'};
        }
      } else {
        return {
          'success': false,
          'message':
              response.data['message'] ?? 'Login failed. Please try again.'
        };
      }
    } on DioException catch (e) {
      debugPrint('Login error: ${e.message}');
      // Check for specific error responses
      if (e.response != null) {
        return {
          'success': false,
          'message':
              e.response?.data?['message'] ?? 'Login failed. Please try again.'
        };
      }

      return {
        'success': false,
        'message': _getConnectionErrorMessage(e),
      };
    } catch (e) {
      debugPrint('Login error: $e');
      return {
        'success': false,
        'message':
            'An error occurred. Please check your connection and try again.'
      };
    }
  }

  Future<Map<String, dynamic>> register(
      String email, String username, String password) async {
    try {
      final response = await _tokenManager.unauthenticatedDio.post(
        '/auth/register',
        data: {
          'email': email,
          'username': username,
          'role': 'user',
          'password': password,
        },
      );

      if (response.statusCode == 201) {
        // Log in the new user using authService.login
        final loginResponse = await login(
          email,
          password,
        );
        return {
          'success': true,
          'message': 'Registration successful',
          'user': response.data['user'],
          'login': loginResponse,
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ??
              'Registration failed. Please try again.'
        };
      }
    } on DioException catch (e) {
      debugPrint('Registration error: ${e.message}');
      // Check for specific error responses
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response?.data?['message'] ??
              '[DIO FAIL]Registration failed. Please try again.'
        };
      }

      return {'success': false, 'message': _getConnectionErrorMessage(e)};
    } catch (e) {
      debugPrint('Registration error: $e');
      return {
        'success': false,
        'message':
            'An error occurred. Please check your connection and try again.'
      };
    }
  }

  // Logout and clear tokens
  Future<Map<String, dynamic>> logout() async {
    try {
      // Attempt to call logout endpoint
      try {
        await _tokenManager.authenticatedDio.post('/auth/logout');
      } catch (_) {
        // Ignore errors from the logout endpoint
      }

      // Clear tokens regardless of API call success
      await _tokenManager.clearTokens();

      return {'success': true, 'message': 'Logged out successfully'};
    } catch (e) {
      debugPrint('Logout error: $e');
      // Still attempt to clear tokens even if there was an error
      try {
        await _tokenManager.clearTokens();
      } catch (_) {}

      return {'success': false, 'message': 'Error during logout'};
    }
  }

  // Check if user is authenticated
  bool get isAuthenticated => authProvider.isAuthenticated;

  // Get authenticated Dio instance for API calls
  Dio get dio => _tokenManager.authenticatedDio;

  // Check if email is already registered
  Future<bool> isEmailRegistered(String email) async {
    try {
      final response = await _tokenManager.unauthenticatedDio.get(
        '/user/isEmailRegistered/$email',
      );

      if (response.statusCode == 200) {
        return response.data['isRegistered'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking email registration: $e');
      return false;
    }
  }

  // Check if username is already registered
  Future<bool> isUsernameRegistered(String username) async {
    try {
      final response = await _tokenManager.unauthenticatedDio.get(
        '/user/isUsernameRegistered/$username',
      );

      if (response.statusCode == 200) {
        return response.data['isRegistered'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking username registration: $e');
      return false;
    }
  }
}
