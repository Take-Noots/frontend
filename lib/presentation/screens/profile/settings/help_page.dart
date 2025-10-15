import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help & Support',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
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
              'Frequently Asked Questions',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildHelpItem(
            context,
            icon: Icons.music_note,
            title: 'How do I link my Spotify account?',
            description:
                'Go to Options > Link Account to Spotify and follow the authentication process.',
          ),
          _buildHelpItem(
            context,
            icon: Icons.post_add,
            title: 'How do I create a post?',
            description:
                'Tap the + button on the home screen to create a new music post.',
          ),
          _buildHelpItem(
            context,
            icon: Icons.group,
            title: 'What are Fanbases?',
            description:
                'Fanbases are communities for fans of specific artists or genres to share music and connect.',
          ),
          _buildHelpItem(
            context,
            icon: Icons.visibility_off,
            title: 'How do I hide a post?',
            description:
                'Tap the three dots on any post and select "Hide Post" to remove it from your feed.',
          ),
          _buildHelpItem(
            context,
            icon: Icons.report,
            title: 'How do I report inappropriate content?',
            description:
                'Tap the three dots on the post and select "Report" to flag inappropriate content.',
          ),
          Divider(color: Theme.of(context).dividerColor, height: 32),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Contact Support',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.email,
                color: Theme.of(context).colorScheme.onSurface),
            title: const Text(
              'Email Support',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'support@noot.com',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios,
                color: Colors.white54, size: 16),
            onTap: () {
              // Open email client
            },
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.chat, color: Colors.white),
            title: const Text(
              'Live Chat',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Chat with our support team',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios,
                color: Colors.white54, size: 16),
            onTap: () {
              // Open live chat
            },
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.feedback, color: Colors.white),
            title: const Text(
              'Send Feedback',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Share your thoughts and suggestions',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios,
                color: Colors.white54, size: 16),
            onTap: () {
              // Open feedback form
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return ExpansionTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      iconColor: Colors.white,
      collapsedIconColor: Colors.white54,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            description,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
