import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// CompactSongControlWidget - A pill-shaped control for play/pause and Spotify link
/// Designed to fit within song cards with minimal space
class CompactSongControlWidget extends StatelessWidget {
  final String? trackId;
  final bool isPlaying;
  final bool isCurrentTrack;
  final VoidCallback? onPlayPause;
  final VoidCallback? onSpotifyTap;

  const CompactSongControlWidget({
    super.key,
    this.trackId,
    this.isPlaying = false,
    this.isCurrentTrack = false,
    this.onPlayPause,
    this.onSpotifyTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillColor = isDark ? Colors.grey[900] : Colors.white;
    final iconColor = isDark ? Colors.white : Colors.black;
    final spotifyAsset = isDark
        ? 'assets/icons/icons-spotify-dark.svg'
        : 'assets/icons/icons-spotify-light.svg';

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: pillColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Spotify icon
          GestureDetector(
            onTap: onSpotifyTap ??
                () {
                  // Default behavior: open Spotify link
                  // print('Open Spotify for track: $trackId');
                },
            child: Container(
              padding: const EdgeInsets.all(4),
              child: SizedBox(
                width: 20,
                height: 20,
                child: SvgPicture.asset(
                  spotifyAsset,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Divider
          Container(
            width: 1,
            height: 20,
            color: iconColor.withOpacity(0.2),
          ),

          const SizedBox(width: 4),

          // Play/Pause button
          if (onPlayPause != null)
            GestureDetector(
              onTap: onPlayPause,
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  isCurrentTrack && isPlaying
                      ? LucideIcons.pause
                      : LucideIcons.play,
                  color: iconColor,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
