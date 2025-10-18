import 'package:flutter/material.dart';
import '../../../../core/styles/app_colors.dart';
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
          ListTile(
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
            trailing: CustomSwitch(
              value: true,
              onChanged: (bool value) {
                // Handle notification toggle
              },
            ),
            leading: Icon(Icons.notifications,
                color: Theme.of(context).colorScheme.onSurface),
          ),
          Divider(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.24)),
          ListTile(
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
            trailing: CustomSwitch(
              value: isDarkMode,
              onChanged: (bool value) async {
                await themeProvider.toggleTheme();
              },
            ),
            leading: Icon(Icons.dark_mode,
                color: Theme.of(context).colorScheme.onSurface),
          ),
          Divider(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.24)),
          ListTile(
            title: Text(
              'Auto-play Songs',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(
              'Automatically play songs in feed',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12),
            ),
            trailing: CustomSwitch(
              value: false,
              onChanged: (bool value) {
                // Handle auto-play toggle
              },
            ),
            leading: Icon(Icons.play_circle,
                color: Theme.of(context).colorScheme.onSurface),
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

/// Custom switch with outline for active state
class CustomSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const CustomSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: value
              ? AppColors.primaryPurple.withOpacity(0.2)
              : (isDark ? Colors.grey.shade900 : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value ? AppColors.primaryPurple : Colors.grey.shade500,
            width: 1.2, // Match thickness for both states
          ),
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: value
                  ? AppColors.primaryPurple
                  : (isDark ? Colors.grey.shade800 : Colors.white),
              shape: BoxShape.circle,
              boxShadow: [
                if (value)
                  BoxShadow(
                    color: AppColors.primaryPurple.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
