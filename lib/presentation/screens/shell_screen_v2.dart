import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../widgets/common/bottom_bar.dart';
import '../widgets/common/musicplayer_bar.dart';

/// ShellScreenV2: Simplified persistent layout using GoRouter's ShellRoute
/// This version wraps any child content with persistent bottom bar and music player
class ShellScreenV2 extends StatefulWidget {
  final Widget child;

  const ShellScreenV2({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<ShellScreenV2> createState() => _ShellScreenV2State();
}

class _ShellScreenV2State extends State<ShellScreenV2> {
  bool _showMusicPlayer = true; // Start as true to avoid hot restart issues

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Main content area - this is where child routes are rendered
          Expanded(
            child: widget.child,
          ),

          // Music player widget - conditionally visible
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: _showMusicPlayer ? null : 0.0,
              constraints: _showMusicPlayer
                  ? null
                  : const BoxConstraints(maxHeight: 0.0),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: MusicPlayerBar(
                  isHidden: !_showMusicPlayer,
                  onSessionStatusChanged: (isActive) {
                    if (mounted) {
                      setState(() {
                        _showMusicPlayer = isActive;
                      });
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      // Persistent bottom navigation bar
      bottomNavigationBar: const BottomBar(),
    );
  }
}
