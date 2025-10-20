import 'package:flutter/material.dart';
import '../../../widgets/common/custom_switch.dart';

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
          ListTile(
            title: Text(
              'Private Account',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(
              'Coming Soon',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12),
            ),
            trailing: CustomSwitch(
              value: false,
              onChanged: (bool value) {
                // Handle private account toggle
              },
            ),
            leading: Icon(Icons.lock,
                color: Theme.of(context).colorScheme.onSurface),
          ),
          Divider(color: Theme.of(context).dividerColor),
          ListTile(
            title: Text(
              'Show Online Status',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(
              'Coming Soon',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12),
            ),
            trailing: CustomSwitch(
              value: true,
              onChanged: (bool value) {
                // Handle online status toggle
              },
            ),
            leading: Icon(Icons.circle, color: Colors.green, size: 16),
          ),
          Divider(color: Theme.of(context).dividerColor),
          ListTile(
            title: Text(
              'Allow Messages from Everyone',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(
              'Coming Soon',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12),
            ),
            trailing: CustomSwitch(
              value: false,
              onChanged: (bool value) {
                // Handle message settings toggle
              },
            ),
            leading: Icon(Icons.message,
                color: Theme.of(context).colorScheme.onSurface),
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
              'Coming Soon',
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
              'Coming Soon',
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
              'Coming Soon',
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
