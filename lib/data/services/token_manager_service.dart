import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Noot/core/providers/auth_provider.dart';
import 'package:Noot/core/constants/app_constants.dart';

class TokenManagerService {
  // API endpoints
  // Use AppConstants for base URL
  static String get _baseUrl => AppConstants.baseUrl;

  static const String _refreshEndpoint = '/auth/refresh';

  // Storage keys
  static const String _accessTokenKey = 'access_token';

  // In-memory storage
  String? _accessToken;

  // Refresh lock to prevent concurrent refresh attempts
  bool _isRefreshing = false;

  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 3);

  // Storage services
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Dio _dio = Dio();
  final Dio _unauthenticatedDio = Dio();

  // Auth provider reference
  final AuthProvider _authProvider;

  // Constructor with required auth provider
  TokenManagerService(this._authProvider) {
    // Configure Dio to handle cookies
    _configureDio();
    _configureUnauthenticatedDio();
  }

  // Configure Dio with interceptors and cookie handling
  void _configureDio() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.options.connectTimeout = const Duration(seconds: 15);

    // Enable cookies
    _dio.options.extra['withCredentials'] = true;

    // Set additional headers for web vs mobile
    if (kIsWeb) {
      // Important for CORS in web
      _dio.options.headers['Access-Control-Allow-Origin'] = '*';
      _dio.options.headers['Access-Control-Allow-Credentials'] = 'true';
    }

    // Add request interceptor
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      // Add authorization header if we have an access token
      if (_accessToken != null) {
        options.headers['Authorization'] = 'Bearer $_accessToken';
      }
      return handler.next(options);
    }, onError: (DioException error, handler) async {
      // Only handle 401 errors for non-Spotify API calls
      // Spotify API 401s should not trigger JWT token refresh
      if (error.response?.statusCode == 401 &&
          !error.requestOptions.path.contains('/spotify/')) {
        print('[TokenManager] 401 error detected, attempting token refresh...');

        // Try to refresh the JWT token with retries
        final refreshed = await _refreshTokenWithRetry();

        if (refreshed) {
          print(
              '[TokenManager] Token refresh successful, retrying original request');
          // Retry the original request with the new token
          final opts = error.requestOptions;
          opts.headers['Authorization'] = 'Bearer $_accessToken';

          try {
            // Create new request
            final response = await _dio.fetch(opts);
            return handler.resolve(response);
          } catch (retryError) {
            print(
                '[TokenManager] Failed to retry original request: $retryError');
            return handler.next(error);
          }
        } else {
          print('[TokenManager] Token refresh failed, logging out user');
        }
      }

      // Pass the error through if we couldn't handle it
      return handler.next(error);
    }));
  }

  void _configureUnauthenticatedDio() {
    _unauthenticatedDio.options.baseUrl = _baseUrl;
    _unauthenticatedDio.options.receiveTimeout = const Duration(seconds: 15);
    _unauthenticatedDio.options.connectTimeout = const Duration(seconds: 15);
    _unauthenticatedDio.options.extra['withCredentials'] = true;
    if (kIsWeb) {
      _unauthenticatedDio.options.headers['Access-Control-Allow-Origin'] = '*';
      _unauthenticatedDio.options.headers['Access-Control-Allow-Credentials'] =
          'true';
    }
    // No auth interceptors for unauthenticated requests
  }

  // Initialize the service by loading token from storage
  Future<void> initialize() async {
    try {
      print('TokenManagerService: Starting initialization');
      await loadTokenFromStorage();
      print(
          'TokenManagerService: Initialization complete, hasToken: ${hasToken}');
    } catch (e) {
      print('TokenManagerService: Error during initialization: $e');
      rethrow;
    }
  }

  // Load token from storage
  Future<void> loadTokenFromStorage() async {
    if (kIsWeb) {
      // For web, rely primarily on SharedPreferences since secure storage has limitations
      await _loadTokenFromSharedPreferences();
    } else {
      try {
        // For mobile, prefer secure storage
        final accessToken = await _secureStorage.read(key: _accessTokenKey);

        // If token exists, update memory and auth provider
        if (accessToken != null) {
          _accessToken = accessToken;
          _authProvider.setToken(accessToken);
        }
      } catch (e) {
        print('Error loading token from storage: $e');
        // Fallback to shared preferences if secure storage fails
        await _loadTokenFromSharedPreferences();
      }
    }
  }

  // Fallback method to load token from SharedPreferences
  Future<void> _loadTokenFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(_accessTokenKey);

      if (accessToken != null) {
        _accessToken = accessToken;
        _authProvider.setToken(accessToken);
      }
    } catch (e) {
      print('Error loading token from SharedPreferences: $e');
    }
  }

  // Save access token to both memory and storage
  Future<void> saveAccessToken(String token) async {
    _accessToken = token;

    if (kIsWeb) {
      // For web, use SharedPreferences
      await _saveTokenToSharedPreferences(token);
    } else {
      try {
        // For mobile, prefer secure storage
        await _secureStorage.write(key: _accessTokenKey, value: token);
      } catch (e) {
        print('Error saving token to secure storage: $e');
        // Fallback to SharedPreferences
        await _saveTokenToSharedPreferences(token);
      }
    }

    // Update auth provider
    _authProvider.setToken(token);
  }

  // Fallback method to save token to SharedPreferences
  Future<void> _saveTokenToSharedPreferences(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, token);
    } catch (e) {
      print('Error saving token to SharedPreferences: $e');
    }
  }

  // Clear tokens for logout
  Future<void> clearTokens() async {
    _accessToken = null;

    // Always clear from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);

    // Only clear secure storage on mobile
    if (!kIsWeb) {
      try {
        await _secureStorage.delete(key: _accessTokenKey);
      } catch (e) {
        print('Error clearing tokens from secure storage: $e');
      }
    }

    // Update auth provider
    _authProvider.logout();
  }

  // Get access token
  String? get accessToken => _accessToken;

  // Check if access token exists
  bool get hasToken => _accessToken != null;

  // Helper method to refresh token with retry logic
  Future<bool> _refreshTokenWithRetry() async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      print('[TokenManager] Token refresh attempt $attempt/$_maxRetries');

      try {
        final success = await refreshToken();
        if (success) {
          print('[TokenManager] Token refresh succeeded on attempt $attempt');
          return true;
        }

        // If refresh returned false (not a network error), don't retry
        print(
            '[TokenManager] Token refresh returned false on attempt $attempt');
        if (attempt < _maxRetries) {
          // Only wait if we're going to retry
          final delay = _retryDelay * attempt; // Exponential backoff
          print('[TokenManager] Waiting ${delay.inSeconds}s before retry...');
          await Future.delayed(delay);
        }
      } catch (e) {
        print('[TokenManager] Token refresh exception on attempt $attempt: $e');

        // Check if it's a network error (should retry) or auth error (should not retry)
        if (e is DioException) {
          final statusCode = e.response?.statusCode;

          // Don't retry on 401 (invalid token) or 403 (forbidden)
          if (statusCode == 401 || statusCode == 403) {
            print('[TokenManager] Auth error ($statusCode), not retrying');
            await clearTokens();
            return false;
          }

          // Retry on network errors or 5xx errors
          if (attempt < _maxRetries) {
            final delay = _retryDelay * attempt;
            print(
                '[TokenManager] Network/server error, retrying in ${delay.inSeconds}s...');
            await Future.delayed(delay);
          }
        } else {
          // Unknown error, don't retry
          print('[TokenManager] Unknown error type, not retrying');
          return false;
        }
      }
    }

    print('[TokenManager] All $_maxRetries refresh attempts failed');
    await clearTokens();
    return false;
  }

  // Refresh token
  Future<bool> refreshToken() async {
    // Prevent concurrent refresh attempts
    if (_isRefreshing) {
      print(
          '[At Token.Manager.Service] Refresh already in progress, skipping...');
      return false;
    }

    _isRefreshing = true;
    try {
      print('[At Token.Manager.Service] Attempting to refresh token...');

      // Use unauthenticated Dio to avoid interceptor loops
      final response =
          await _unauthenticatedDio.post(_refreshEndpoint, options: Options(
              // Ensure cookies are sent with the request
              extra: {'withCredentials': true}));

      print('[At Token.Manager.Service] Refresh response: ${response.data}');

      print(
          '[At Token.Manager.Service] Refresh response status: ${response.statusCode}');

      // Handle successful response
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        // Save the new access token
        if (data['accessToken'] != null) {
          print('Successfully received new access token');
          await saveAccessToken(data['accessToken']);

          // If user data is included, update auth provider
          if (data['user'] != null) {
            print(
                '[At Token.Manager.Service] User data received in refresh response');
            _authProvider.setUser(data['user']);
          }

          return true;
        } else {
          print(
              '[At Token.Manager.Service] Refresh response missing accessToken field: ${response.data}');
        }
      } else {
        print(
            '[At Token.Manager.Service] Unexpected refresh response format or status code: ${response.statusCode}');
      }

      return false;
    } catch (e) {
      print('[At Token.Manager.Service] Error refreshing token: $e');
      if (e is DioException) {
        print(
            '[At Token.Manager.Service] DioException details - Status code: ${e.response?.statusCode}, Message: ${e.message}');
        print('[At Token.Manager.Service] Response data: ${e.response?.data}');
      }

      // Don't clear tokens here - let the retry logic handle it
      // Only rethrow to allow retry logic to catch it
      rethrow;
    } finally {
      _isRefreshing = false;
    }
  }

  // Get authenticated Dio instance
  Dio get authenticatedDio => _dio;
  Dio get unauthenticatedDio => _unauthenticatedDio;
}
