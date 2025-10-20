import 'package:flutter/material.dart';
import '../../../data/services/spotify_session_service.dart';

/// Dialog to warn user about Spotify connection issues
/// and get confirmation before unlinking
class SpotifyConnectionDialog extends StatelessWidget {
  final SpotifySessionStatus status;
  final VoidCallback? onRetry;
  final VoidCallback? onUnlink;
  final VoidCallback? onDismiss;

  const SpotifyConnectionDialog({
    Key? key,
    required this.status,
    this.onRetry,
    this.onUnlink,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(
            status.isPermanentFailure
                ? Icons.warning_amber_rounded
                : Icons.info_outline_rounded,
            color: status.isPermanentFailure ? Colors.orange : Colors.blue,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              status.isPermanentFailure
                  ? 'Spotify Connection Lost'
                  : 'Spotify Connection Issue',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main message
            Text(
              status.message ??
                  (status.isPermanentFailure
                      ? 'Your Spotify connection has been lost. This usually happens when you\'ve disconnected Spotify from another device or revoked access.'
                      : 'We\'re having trouble connecting to your Spotify account. This might be a temporary issue.'),
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.8),
                fontSize: 14,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),

            // Retry count indicator (only if retrying)
            if (status.retryCount > 0) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Retry attempts: ${status.retryCount}/3',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Error details (collapsible)
            if (status.lastError != null && status.lastError!.isNotEmpty) ...[
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Error Details',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.lastError!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red.shade700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        // Dismiss button
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDismiss?.call();
          },
          child: Text(
            'Dismiss',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),

        // Retry button (only if not permanent failure)
        if (!status.isPermanentFailure) ...[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry?.call();
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue.withOpacity(0.1),
            ),
            child: const Text(
              'Retry Connection',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],

        // Unlink & Re-link button
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onUnlink?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                status.isPermanentFailure ? Colors.orange : colorScheme.error,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          child: Text(
            status.isPermanentFailure
                ? 'Reconnect Spotify'
                : 'Disconnect & Re-link',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// Helper function to show the Spotify connection dialog
Future<void> showSpotifyConnectionDialog({
  required BuildContext context,
  required SpotifySessionStatus status,
  VoidCallback? onRetry,
  VoidCallback? onUnlink,
  VoidCallback? onDismiss,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => SpotifyConnectionDialog(
      status: status,
      onRetry: onRetry,
      onUnlink: onUnlink,
      onDismiss: onDismiss,
    ),
  );
}
