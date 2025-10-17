import 'package:flutter/material.dart';
import './user_profiles.dart'; // Import the UserProfilePage

// following: List<Map<String, dynamic>> with userId, username, profileImage
class FollowingListPage extends StatelessWidget {
  final List<dynamic> following;

  const FollowingListPage({Key? key, required this.following})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Following'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: following.isEmpty
          ? Center(
              child: Text(
                'Not following anyone yet.',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            )
          : ListView.builder(
              itemCount: following.length,
              itemBuilder: (context, index) {
                final user = following[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (user['profileImage'] != null &&
                            user['profileImage'].toString().isNotEmpty)
                        ? NetworkImage(user['profileImage'])
                        : null,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                  ),
                  title: Text(
                    user['username'] ?? 'Unknown',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  subtitle: (user['fullName'] != null &&
                          user['fullName'].toString().isNotEmpty)
                      ? Text(
                          user['fullName'],
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 12),
                        )
                      : null,
                  onTap: () {
                    if (user['userId'] != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => UserProfilePage(
                            userId: user['userId'],
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}
