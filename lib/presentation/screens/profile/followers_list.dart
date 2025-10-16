import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './user_profiles.dart'; // Import the ProfileScreen
import './my_profile.dart';
import '../../../core/providers/auth_provider.dart';

// followers: List<Map<String, dynamic>> with userId, username, profileImage
class FollowersListPage extends StatelessWidget {
  final List<dynamic> followers;
  final void Function(String userId, String? username)? onUserTap;

  const FollowersListPage({Key? key, required this.followers, this.onUserTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Followers'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: followers.isEmpty
          ? Center(
              child: Text(
                'No followers yet.',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            )
          : ListView.builder(
              itemCount: followers.length,
              itemBuilder: (context, index) {
                final follower = followers[index];
                // Defensive: handle both string and map, but expect map with userId, username, profileImage
                if (follower is Map<String, dynamic>) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: (follower['profileImage'] != null &&
                              follower['profileImage'].toString().isNotEmpty)
                          ? NetworkImage(follower['profileImage'])
                          : null,
                      backgroundColor:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      follower['username'] ?? follower['userId'] ?? 'Unknown',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                    subtitle: (follower['fullName'] != null &&
                            follower['fullName'].toString().isNotEmpty)
                        ? Text(
                            follower['fullName'],
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 12),
                          )
                        : null,
                    onTap: () {
                      if (follower['userId'] != null) {
                        final authProvider =
                            Provider.of<AuthProvider>(context, listen: false);
                        final currentUserId = authProvider.user?.id;
                        if (follower['userId'] == currentUserId) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const NormalUserProfilePage(),
                            ),
                          );
                        } else {
                          if (onUserTap != null) {
                            onUserTap!(
                                follower['userId'], follower['username']);
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => UserProfilePage(
                                  userId: follower['userId'],
                                  username: follower['username'],
                                ),
                              ),
                            );
                          }
                        }
                      }
                    },
                  );
                } else if (follower is String) {
                  // fallback for string-only entries
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                      child: Icon(Icons.person,
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                    title: Text(
                      follower,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                    subtitle: Text(
                      'No details available',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12),
                    ),
                    onTap: () {
                      // For string entries, we'll assume the string is the userId
                      final authProvider =
                          Provider.of<AuthProvider>(context, listen: false);
                      final currentUserId = authProvider.user?.id;
                      if (follower == currentUserId) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const NormalUserProfilePage(),
                          ),
                        );
                      } else {
                        if (onUserTap != null) {
                          onUserTap!(follower, null);
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => UserProfilePage(
                                userId: follower,
                              ),
                            ),
                          );
                        }
                      }
                    },
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
    );
  }
}
