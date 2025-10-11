import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.black,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: Colors.black,
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'General Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text(
              'Push Notifications',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Receive notifications about likes and comments',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            value: true,
            onChanged: (bool value) {
              // Handle notification toggle
            },
            secondary: const Icon(Icons.notifications, color: Colors.white),
            activeColor: Colors.green,
          ),
          const Divider(color: Colors.white24),
          SwitchListTile(
            title: const Text(
              'Dark Mode',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Use dark theme throughout the app',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            value: true,
            onChanged: (bool value) {
              // Handle dark mode toggle
            },
            secondary: const Icon(Icons.dark_mode, color: Colors.white),
            activeColor: Colors.green,
          ),
          const Divider(color: Colors.white24),
          SwitchListTile(
            title: const Text(
              'Auto-play Videos',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Automatically play videos in feed',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            value: false,
            onChanged: (bool value) {
              // Handle auto-play toggle
            },
            secondary: const Icon(Icons.play_circle, color: Colors.white),
            activeColor: Colors.green,
          ),
          const Divider(color: Colors.white24),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Account Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language, color: Colors.white),
            title: const Text(
              'Language',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'English',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios,
                color: Colors.white54, size: 16),
            onTap: () {
              // Navigate to language selection
            },
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.visibility_off, color: Colors.white),
            title: const Text(
              'Hidden Posts',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'View and manage your hidden posts',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios,
                color: Colors.white54, size: 16),
            onTap: () {
              context.go(AppRoutes.hiddenPosts);
            },
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.language, color: Colors.white),
            title: const Text(
              'Language',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Manage data and storage settings',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios,
                color: Colors.white54, size: 16),
            onTap: () {
              // Navigate to data usage settings
            },
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.music_note, color: Colors.white),
            title: const Text(
              'Music Quality',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'High quality audio playback',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios,
                color: Colors.white54, size: 16),
            onTap: () {
              // Navigate to music quality settings
            },
          ),
        ],
      ),
    );
  }
}
