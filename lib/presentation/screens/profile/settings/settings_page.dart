import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/theme_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'General Settings',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: Text(
              'Push Notifications',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(
              'Receive notifications about likes and comments',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12),
            ),
            value: true,
            onChanged: (bool value) {
              // Handle notification toggle
            },
            secondary: Icon(Icons.notifications,
                color: Theme.of(context).colorScheme.onSurface),
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          Divider(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.24)),
          SwitchListTile(
            title: Text(
              'Dark Mode',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(
              'Use dark theme throughout the app',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12),
            ),
            value: isDarkMode,
            onChanged: (bool value) {
              themeProvider.toggleTheme();
            },
            secondary: Icon(Icons.dark_mode,
                color: Theme.of(context).colorScheme.onSurface),
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          Divider(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.24)),
          SwitchListTile(
            title: Text(
              'Auto-play Videos',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(
              'Automatically play songs in feed',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12),
            ),
            value: false,
            onChanged: (bool value) {
              // Handle auto-play toggle
            },
            secondary: Icon(Icons.play_circle,
                color: Theme.of(context).colorScheme.onSurface),
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          Divider(color: Theme.of(context).dividerColor),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Account Settings',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.language,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text(
              'Language',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(
              'English',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12),
            ),
            trailing: Icon(Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 16),
            onTap: () {
              // Navigate to language selection
            },
          ),
          Divider(color: Theme.of(context).dividerColor),
          ListTile(
            leading: Icon(Icons.visibility_off,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text(
              'Hidden Posts',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(
              'View and manage your hidden posts',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12),
            ),
            trailing: Icon(Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 16),
            onTap: () {
              context.go(AppRoutes.hiddenPosts);
            },
          ),
          Divider(color: Theme.of(context).dividerColor),
          ListTile(
            leading: Icon(Icons.language,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text(
              'Language',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(
              'Manage data and storage settings',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12),
            ),
            trailing: Icon(Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 16),
            onTap: () {
              // Navigate to data usage settings
            },
          ),
          Divider(color: Theme.of(context).dividerColor),
          ListTile(
            leading: Icon(Icons.music_note,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text(
              'Music Quality',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(
              'High quality audio playback',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12),
            ),
            trailing: Icon(Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 16),
            onTap: () {
              // Navigate to music quality settings
            },
          ),
        ],
      ),
    );
  }
}
