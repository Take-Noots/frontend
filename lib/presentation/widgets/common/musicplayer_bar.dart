import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:Noot/core/providers/auth_provider.dart';
import 'package:Noot/data/services/auth_service.dart';

class MusicPlayerControls extends StatelessWidget {
  final bool playing;
  final VoidCallback? onPrevious;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;

  const MusicPlayerControls({
    Key? key,
    required this.playing,
    this.onPrevious,
    this.onPlayPause,
    this.onNext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            LucideIcons.skipBack,
            color: playing
                ? (onPrevious == null
                    ? Colors.white.withOpacity(0.5)
                    : Colors.white)
                : (onPrevious == null
                    ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.5)
                    : Theme.of(context).colorScheme.onPrimary),
            size: 20,
          ),
          onPressed: onPrevious,
        ),
        IconButton(
          icon: Icon(
            playing ? LucideIcons.pause : LucideIcons.play,
            color: playing
                ? (onPlayPause == null
                    ? Colors.white.withOpacity(0.5)
                    : Colors.white)
                : (onPlayPause == null
                    ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.5)
                    : Theme.of(context).colorScheme.onPrimary),
            size: 20,
          ),
          onPressed: onPlayPause,
        ),
        IconButton(
          icon: Icon(
            LucideIcons.skipForward,
            color: playing
                ? (onNext == null
                    ? Colors.white.withOpacity(0.5)
                    : Colors.white)
                : (onNext == null
                    ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.5)
                    : Theme.of(context).colorScheme.onPrimary),
            size: 20,
          ),
          onPressed: onNext,
        ),
      ],
    );
  }
}

class MusicPlayerBar extends StatefulWidget {
  // Callback to expose active session state
  final void Function(bool isActive)? onSessionStatusChanged;
  // Track whether the widget is visually hidden
  final bool isHidden;

  const MusicPlayerBar({
    Key? key,
    this.onSessionStatusChanged,
    this.isHidden = false,
  }) : super(key: key);

  @override
  _MusicPlayerBarState createState() => _MusicPlayerBarState();
}

class _MusicPlayerBarState extends State<MusicPlayerBar> {
  String _trackName = 'No track playing';
  String _artistName = '';
  bool _isPlaying = false;
  bool _controlsLocked = false;
  bool _hasActiveSession = false;
  Timer? _refreshTimer;
  late AuthService _authService;
  late Dio _dio;

  @override
  void initState() {
    super.initState();
    // Timer will be initialized in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize auth service and DIO
    _authService = Provider.of<AuthService>(context, listen: false);
    _dio = _authService.dio;

    // Ensure timer is always active (handles hot restart case)
    if (_refreshTimer == null || !_refreshTimer!.isActive) {
      _resetRefreshTimer();
    }

    // Fetch initial track data
    _fetchCurrentTrack();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    // This is called during hot restart in development mode
    _refreshTimer?.cancel();
    _resetRefreshTimer();

    // Wait a bit for AuthProvider to reload state from storage after hot restart
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _fetchCurrentTrack();
      }
    });
  }

  @override
  void didUpdateWidget(MusicPlayerBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the visibility state changed, adjust our timer frequency
    if (oldWidget.isHidden != widget.isHidden) {
      _resetRefreshTimer();
    }

    // Ensure timer is still active after hot restart
    if (_refreshTimer == null || !_refreshTimer!.isActive) {
      _resetRefreshTimer();
    }
  }

  Future<void> _fetchCurrentTrack() async {
    try {
      final response = await _dio.get(
        '/spotify/player/current-track',
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (mounted) {
          // Get the top-level is_playing status to determine if there's an active session
          final bool isActiveSession = data['is_playing'] ?? false;

          setState(() {
            // Store the active session status
            _hasActiveSession = isActiveSession;

            // Check if we have track data and an active session
            if (data['track'] != null && _hasActiveSession) {
              // Update track information
              _trackName = data['track']['name'] ?? 'Unknown Track';

              if (data['track']['artists'] != null &&
                  (data['track']['artists'] as List).isNotEmpty) {
                _artistName = data['track']['artists'][0];
              } else {
                _artistName = 'Unknown Artist';
              }

              // Use track.is_playing for the actual play/pause state
              _isPlaying = data['track']['is_playing'] ?? false;
            } else {
              // If no track playing or track information is not available
              _trackName = "It's silent in here...";
              _artistName = "";
              // Ensure playback status is consistent
              _isPlaying = false;
            }

            // Unlock controls after receiving an update from the backend
            _controlsLocked = false;
          });

          // Notify parent widget about session status change
          if (widget.onSessionStatusChanged != null) {
            widget.onSessionStatusChanged!(_hasActiveSession);
          }
        }
      }
    } catch (e) {
      // Silently fail - will retry on next poll
    }
  }

  // Helper method to reset and restart the refresh timer
  void _resetRefreshTimer() {
    _refreshTimer?.cancel();
    // Use a more frequent check interval when widget is hidden to detect new sessions faster
    final interval = widget.isHidden
        ? const Duration(seconds: 5)
        : const Duration(seconds: 5);

    _refreshTimer = Timer.periodic(interval, (_) {
      // Always fetch track data regardless of visibility
      _fetchCurrentTrack();
    });
  }

  Future<void> _skipToPreviousTrack() async {
    // Only proceed if user is authenticated and controls are not locked
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated || _controlsLocked) {
      return;
    }

    // Lock controls to prevent spamming
    setState(() {
      _controlsLocked = true;
    });

    try {
      final response = await _dio.post('/spotify/player/previous');

      if (response.statusCode == 200) {
        // Cancel the previous timer to avoid conflicting updates
        _refreshTimer?.cancel();

        // Immediately fetch the current track to get the updated track info
        _fetchCurrentTrack();

        // Also restart the periodic timer after a short delay
        _refreshTimer = Timer(const Duration(seconds: 2), () {
          // Fetch again after giving Spotify servers time to update
          _fetchCurrentTrack();
          // Then restart the periodic timer
          _resetRefreshTimer();
        });
      } else {
        // Unlock controls in case of error
        setState(() {
          _controlsLocked = false;
        });
      }
    } catch (e) {
      // Unlock controls in case of error
      setState(() {
        _controlsLocked = false;
      });
    }
  }

  Future<void> _skipToNextTrack() async {
    // Only proceed if user is authenticated and controls are not locked
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated || _controlsLocked) {
      return;
    }

    // Lock controls to prevent spamming
    setState(() {
      _controlsLocked = true;
    });

    try {
      final response = await _dio.post('/spotify/player/next');

      if (response.statusCode == 200) {
        // Cancel the previous timer to avoid conflicting updates
        _refreshTimer?.cancel();

        // Immediately fetch the current track to get the updated track info
        _fetchCurrentTrack();

        // Also restart the periodic timer after a short delay
        _refreshTimer = Timer(const Duration(seconds: 2), () {
          // Fetch again after giving Spotify servers time to update
          _fetchCurrentTrack();
          // Then restart the periodic timer
          _resetRefreshTimer();
        });
      } else {
        // Unlock controls in case of error
        setState(() {
          _controlsLocked = false;
        });
      }
    } catch (e) {
      // Unlock controls in case of error
      setState(() {
        _controlsLocked = false;
      });
    }
  }

  Future<void> _togglePlayback() async {
    // Only proceed if user is authenticated and controls are not locked
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated || _controlsLocked) {
      return;
    }

    // Lock controls to prevent spamming
    setState(() {
      _controlsLocked = true;
    });

    try {
      // Determine which action to take based on current playback state
      final shouldPause = _isPlaying;
      final endpoint =
          shouldPause ? '/spotify/player/pause' : '/spotify/player/play';

      final response = shouldPause
          ? await _dio.put(endpoint)
          : await _dio.post(endpoint,
              data: {}); // Empty JSON object for resuming playback

      if (response.statusCode == 200) {
        // Cancel the previous timer to avoid conflicting updates
        _refreshTimer?.cancel();

        // Immediately fetch the current track to get the actual play state
        _fetchCurrentTrack();

        // Also restart the periodic timer after a short delay
        _refreshTimer = Timer(const Duration(seconds: 2), () {
          // Fetch again after giving Spotify servers time to update
          _fetchCurrentTrack();
          // Then restart the periodic timer
          _resetRefreshTimer();
        });
      } else {
        // Unlock controls in case of error
        setState(() {
          _controlsLocked = false;
        });
      }
    } catch (e) {
      // Unlock controls in case of error
      setState(() {
        _controlsLocked = false;
      });
    }
  }

  String _truncate(String text, [int maxLength = 25]) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength) + '...';
  }

  @override
  Widget build(BuildContext context) {
    // The widget still builds and makes API calls even when hidden,
    // but we apply visual adjustments when it's hidden
    return Container(
      padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
      decoration: BoxDecoration(
        boxShadow: widget.isHidden
            ? [] // No shadow when hidden
            : [
                BoxShadow(
                  color: _isPlaying
                      ? Color(0xFFFd535f9)
                      : Theme.of(context).colorScheme.primary,
                  blurRadius: 5.0,
                  offset: Offset(0, -1),
                ),
              ],
        color: !_isPlaying
            ? Theme.of(context).colorScheme.primary
            : null, // Only set color if not playing
        gradient: _isPlaying
            ? LinearGradient(
                colors: [
                  Color(0xFF677de9), // #677de9
                  Color(0xFFFd535f9), // #d535f9
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _truncate(_trackName),
                style: TextStyle(
                  color: _isPlaying
                      ? Colors.white
                      : Theme.of(context).colorScheme.onPrimary,
                  fontSize: 13,
                  fontWeight: _isPlaying ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: _isPlaying ? 0.3 : 0.0,
                ),
              ),
              if (_artistName.isNotEmpty)
                Text(
                  _truncate(_artistName),
                  style: TextStyle(
                    color: _isPlaying
                        ? Colors.white
                        : Theme.of(context).colorScheme.onPrimary,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          // Only show controls if we have an active session with a track
          if (_trackName != "It's silent in here..." && _hasActiveSession)
            MusicPlayerControls(
              playing: _isPlaying,
              onPrevious: _controlsLocked
                  ? null
                  : () {
                      _skipToPreviousTrack();
                    },
              onPlayPause: _controlsLocked
                  ? null
                  : () {
                      _togglePlayback();
                      // Timer is already reset in _togglePlayback method
                    },
              onNext: _controlsLocked
                  ? null
                  : () {
                      _skipToNextTrack();
                    },
            ),
        ],
      ),
    );
  }
}
