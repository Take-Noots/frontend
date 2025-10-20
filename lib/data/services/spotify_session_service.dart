import 'package:dio/dio.dart';

/// Service to manage Spotify session status and handle token issues
class SpotifySessionService {
  final Dio _dio;

  SpotifySessionService(this._dio);

  /// Check Spotify session status
  /// Returns session details including whether user confirmation is required
  Future<SpotifySessionStatus?> getSessionStatus() async {
    try {
      final response = await _dio.get('/spotify/session/status');

      if (response.statusCode == 200 && response.data != null) {
        return SpotifySessionStatus.fromJson(response.data);
      }

      return null;
    } catch (e) {
      print('[Spotify Session] Error checking status: $e');
      return null;
    }
  }

  /// User confirms they want to unlink/clear their Spotify account
  /// Should only be called after user explicitly confirms in a dialog
  Future<bool> confirmClearSession() async {
    try {
      final response = await _dio.post('/spotify/session/confirm-clear');

      if (response.statusCode == 200 && response.data != null) {
        final success = response.data['success'] ?? false;
        print('[Spotify Session] Clear session result: $success');
        return success;
      }

      return false;
    } catch (e) {
      print('[Spotify Session] Error clearing session: $e');
      return false;
    }
  }

  /// User wants to retry the connection without unlinking
  /// Resets retry counter and allows system to try again
  Future<bool> retryConnection() async {
    try {
      final response = await _dio.post('/spotify/session/retry');

      if (response.statusCode == 200 && response.data != null) {
        final success = response.data['success'] ?? false;
        print('[Spotify Session] Retry connection result: $success');
        return success;
      }

      return false;
    } catch (e) {
      print('[Spotify Session] Error retrying connection: $e');
      return false;
    }
  }
}

/// Model for Spotify session status
class SpotifySessionStatus {
  final bool isLinked;
  final bool requiresConfirmation;
  final int retryCount;
  final String? lastError;
  final String? message;

  SpotifySessionStatus({
    required this.isLinked,
    required this.requiresConfirmation,
    required this.retryCount,
    this.lastError,
    this.message,
  });

  factory SpotifySessionStatus.fromJson(Map<String, dynamic> json) {
    return SpotifySessionStatus(
      isLinked: json['isLinked'] ?? false,
      requiresConfirmation: json['requiresConfirmation'] ?? false,
      retryCount: json['retryCount'] ?? 0,
      lastError: json['lastError'],
      message: json['message'],
    );
  }

  bool get hasIssues => requiresConfirmation || retryCount > 0;

  bool get isPermanentFailure => requiresConfirmation;

  bool get isTemporaryFailure => retryCount > 0 && !requiresConfirmation;
}
