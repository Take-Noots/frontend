import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import 'settings_page.dart';
import 'privacy_page.dart';
import 'savedPosts/saved_posts.dart';
import 'help_page.dart';
import 'about_page.dart';

class OptionsPage extends StatelessWidget {
  const OptionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Options',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        centerTitle: true,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.settings,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text('Settings',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.lock,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text('Privacy',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrivacyPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.visibility_off,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text('Hidden Posts',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            onTap: () {
              context.go(AppRoutes.hiddenPosts);
            },
          ),
          ListTile(
            leading: Icon(Icons.bookmark,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text('Saved Post',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            onTap: () {
              final userId =
                  Provider.of<AuthProvider>(context, listen: false).user?.id ??
                      '';
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SavedPostsPage(userId: userId)),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.help_outline,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text('Help',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.info_outline,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text('About',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
            },
          ),
          Divider(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)),
          Provider.of<AuthProvider>(context, listen: false).isSpotifyLinked
              ? const SizedBox.shrink()
              : ListTile(
                  leading: Icon(Icons.account_circle,
                      color: Theme.of(context).colorScheme.onSurface),
                  title: Text('Link Account to Spotify',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface)),
                  onTap: () {
                    context.go(AppRoutes.linkSpotify);
                  },
                ),
          ListTile(
            leading:
                Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text('Logout',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/login', (route) => false);
            },
          ),
        ],
      ),
    );
  }
}
