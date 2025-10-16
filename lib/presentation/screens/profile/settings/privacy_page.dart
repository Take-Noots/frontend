import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy',
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
              'Privacy & Security',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: Text(
              'Private Account',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(
              'Only approved followers can see your posts',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12),
            ),
            value: false,
            onChanged: (bool value) {
              // Handle private account toggle
            },
            secondary: Icon(Icons.lock,
                color: Theme.of(context).colorScheme.onSurface),
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          Divider(color: Theme.of(context).dividerColor),
          SwitchListTile(
            title: Text(
              'Show Online Status',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(
              'Let others see when you\'re active',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12),
            ),
            value: true,
            onChanged: (bool value) {
              // Handle online status toggle
            },
            secondary: Icon(Icons.circle,
                color: Theme.of(context).colorScheme.primary, size: 16),
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          Divider(color: Theme.of(context).dividerColor),
          SwitchListTile(
            title: Text(
              'Allow Messages from Everyone',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(
              'Anyone can send you direct messages',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12),
            ),
            value: false,
            onChanged: (bool value) {
              // Handle message settings toggle
            },
            secondary: Icon(Icons.message,
                color: Theme.of(context).colorScheme.onSurface),
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          Divider(color: Theme.of(context).dividerColor),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Data & History',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.history,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text(
              'Clear Search History',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(
              'Remove all your search history',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12),
            ),
            trailing: Icon(Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 16),
            onTap: () {
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Theme.of(context).dialogBackgroundColor,
                  title: Text(
                    'Clear Search History?',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  content: Text(
                    'This will remove all your search history permanently.',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Handle clear history
                      },
                      child: Text('Clear',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                    ),
                  ],
                ),
              );
            },
          ),
          Divider(color: Theme.of(context).dividerColor),
          ListTile(
            leading: Icon(Icons.block,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text(
              'Blocked Accounts',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(
              'Manage blocked users',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12),
            ),
            trailing: Icon(Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 16),
            onTap: () {
              // Navigate to blocked accounts
            },
          ),
          Divider(color: Theme.of(context).dividerColor),
          ListTile(
            leading: Icon(Icons.download,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text(
              'Download Your Data',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(
              'Request a copy of your data',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12),
            ),
            trailing: Icon(Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 16),
            onTap: () {
              // Handle data download request
            },
          ),
        ],
      ),
    );
  }
}
