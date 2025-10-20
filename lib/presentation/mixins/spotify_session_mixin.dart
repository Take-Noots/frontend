import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/spotify_session_service.dart';
import '../widgets/dialogs/spotify_connection_dialog.dart';
import 'package:go_router/go_router.dart';

/// Mixin to add Spotify session checking functionality to any screen
/// Usage: Add this mixin to any StatefulWidget that uses Spotify features
mixin SpotifySessionMixin<T extends StatefulWidget> on State<T> {
  SpotifySessionService? _spotifySessionService;
  bool _isCheckingSpotifyStatus = false;

  /// Initialize the Spotify session service
  SpotifySessionService get spotifySessionService {
    if (_spotifySessionService == null) {
      final authService = Provider.of<AuthService>(context, listen: false);
      _spotifySessionService = SpotifySessionService(authService.dio);
    }
    return _spotifySessionService!;
  }

  /// Check Spotify session status and show dialog if needed
  /// Call this in initState or when screen becomes visible
  Future<void> checkSpotifySessionStatus({
    bool showDialogIfIssue = true,
  }) async {
    // Prevent concurrent checks
    if (_isCheckingSpotifyStatus) return;

    _isCheckingSpotifyStatus = true;

    try {
      final status = await spotifySessionService.getSessionStatus();

      if (!mounted) return;

      // Only proceed if there's an issue
      if (status != null && status.hasIssues && showDialogIfIssue) {
        // Show dialog if user confirmation is required
        if (status.requiresConfirmation) {
          await _showSpotifyWarningDialog(status);
        } else if (status.isTemporaryFailure) {
          // For temporary failures, just show a snackbar
          _showSpotifySnackbar(
            status.message ??
                'Spotify connection issue (attempt ${status.retryCount}/3). Will retry automatically.',
            isWarning: true,
          );
        }
      }
    } catch (e) {
      print('[Spotify Session Mixin] Error checking status: $e');
    } finally {
      _isCheckingSpotifyStatus = false;
    }
  }

  /// Show the Spotify warning dialog with action buttons
  Future<void> _showSpotifyWarningDialog(SpotifySessionStatus status) async {
    if (!mounted) return;

    await showSpotifyConnectionDialog(
      context: context,
      status: status,
      onRetry: () => _handleRetryConnection(),
      onUnlink: () => _handleUnlinkSpotify(),
      onDismiss: () {
        print('[Spotify] User dismissed warning dialog');
      },
    );
  }

  /// Handle retry connection action
  Future<void> _handleRetryConnection() async {
    try {
      _showSpotifySnackbar('Retrying Spotify connection...', isLoading: true);

      final success = await spotifySessionService.retryConnection();

      if (!mounted) return;

      if (success) {
        _showSpotifySnackbar(
          'Retry initiated. System will attempt to reconnect.',
          isSuccess: true,
        );

        // Wait a moment then check status again
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          await checkSpotifySessionStatus(showDialogIfIssue: false);
        }
      } else {
        _showSpotifySnackbar(
          'Failed to retry connection. Please try again.',
          isError: true,
        );
      }
    } catch (e) {
      print('[Spotify] Error retrying connection: $e');
      if (mounted) {
        _showSpotifySnackbar('Error: ${e.toString()}', isError: true);
      }
    }
  }

  /// Handle unlink Spotify action
  Future<void> _handleUnlinkSpotify() async {
    // Show confirmation dialog first
    final confirmed = await _showUnlinkConfirmation();

    if (!confirmed || !mounted) return;

    try {
      _showSpotifySnackbar('Disconnecting Spotify...', isLoading: true);

      final success = await spotifySessionService.confirmClearSession();

      if (!mounted) return;

      if (success) {
        _showSpotifySnackbar(
          'Spotify disconnected successfully. You can reconnect anytime.',
          isSuccess: true,
        );

        // Navigate to Spotify link screen after a short delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          context.push('/link-spotify');
        }
      } else {
        _showSpotifySnackbar(
          'Failed to disconnect Spotify. Please try again.',
          isError: true,
        );
      }
    } catch (e) {
      print('[Spotify] Error unlinking: $e');
      if (mounted) {
        _showSpotifySnackbar('Error: ${e.toString()}', isError: true);
      }
    }
  }

  /// Show confirmation dialog before unlinking
  Future<bool> _showUnlinkConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Disconnect Spotify?'),
            content: const Text(
              'This will remove your Spotify connection. You\'ll need to reconnect '
              'your account to play music again.\n\n'
              'Are you sure you want to continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Yes, Disconnect'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Show a snackbar with Spotify-related message
  void _showSpotifySnackbar(
    String message, {
    bool isSuccess = false,
    bool isError = false,
    bool isWarning = false,
    bool isLoading = false,
  }) {
    if (!mounted) return;

    Color backgroundColor;
    IconData icon;

    if (isSuccess) {
      backgroundColor = Colors.green;
      icon = Icons.check_circle;
    } else if (isError) {
      backgroundColor = Colors.red;
      icon = Icons.error;
    } else if (isWarning) {
      backgroundColor = Colors.orange;
      icon = Icons.warning;
    } else if (isLoading) {
      backgroundColor = Colors.blue;
      icon = Icons.refresh;
    } else {
      backgroundColor = Colors.grey;
      icon = Icons.info;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isLoading ? 2 : 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Manual check that can be called when a Spotify API error occurs
  Future<void> onSpotifyError(dynamic error) async {
    print('[Spotify] Error occurred: $error');

    // Check if it's a token-related error
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('token') ||
        errorString.contains('unauthorized') ||
        errorString.contains('401')) {
      // Check session status and potentially show dialog
      await checkSpotifySessionStatus();
    }
  }
}
