import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy'),
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
              'Privacy & Security',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text(
              'Private Account',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Only approved followers can see your posts',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            value: false,
            onChanged: (bool value) {
              // Handle private account toggle
            },
            secondary: const Icon(Icons.lock, color: Colors.white),
            activeColor: Colors.green,
          ),
          const Divider(color: Colors.white24),
          SwitchListTile(
            title: const Text(
              'Show Online Status',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Let others see when you\'re active',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            value: true,
            onChanged: (bool value) {
              // Handle online status toggle
            },
            secondary: const Icon(Icons.circle, color: Colors.green, size: 16),
            activeColor: Colors.green,
          ),
          const Divider(color: Colors.white24),
          SwitchListTile(
            title: const Text(
              'Allow Messages from Everyone',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Anyone can send you direct messages',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            value: false,
            onChanged: (bool value) {
              // Handle message settings toggle
            },
            secondary: const Icon(Icons.message, color: Colors.white),
            activeColor: Colors.green,
          ),
          const Divider(color: Colors.white24),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Data & History',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.white),
            title: const Text(
              'Clear Search History',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Remove all your search history',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios,
                color: Colors.white54, size: 16),
            onTap: () {
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.grey[900],
                  title: const Text(
                    'Clear Search History?',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'This will remove all your search history permanently.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.white70)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Handle clear history
                      },
                      child: const Text('Clear',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.block, color: Colors.white),
            title: const Text(
              'Blocked Accounts',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Manage blocked users',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios,
                color: Colors.white54, size: 16),
            onTap: () {
              // Navigate to blocked accounts
            },
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.download, color: Colors.white),
            title: const Text(
              'Download Your Data',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Request a copy of your data',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios,
                color: Colors.white54, size: 16),
            onTap: () {
              // Handle data download request
            },
          ),
        ],
      ),
    );
  }
}
