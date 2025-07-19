import 'package:flutter/material.dart';
import 'package:frontend/presentation/screens/fanbase/fanbase.dart';
import '../widgets/common/bottom_bar.dart';
import '../widgets/common/musicplayer_bar.dart';
import 'home_screen.dart';
// import 'fanbases_screen.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';

class ShellScreen2 extends StatefulWidget {
  const ShellScreen2({Key? key}) : super(key: key);

  @override
  State<ShellScreen2> createState() => _ShellScreen2State();
}

class _ShellScreen2State extends State<ShellScreen2> {
  int _currentIndex = 4; // Start on Fanbases tab
  bool _showMusicPlayer = false;

  final List<Widget> _pages = const [
    HomeScreen(inShell: true),
    Placeholder(), // Search
    Placeholder(), // Create
    Placeholder(), // Requests
    FanbasePage(),
    Placeholder(), // Profile
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No appBar
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),
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
                    setState(() {
                      _showMusicPlayer = isActive;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
