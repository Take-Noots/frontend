import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import './user_profiles.dart'; // Import the ProfileScreen
import '../../../core/providers/auth_provider.dart';
import '../../../core/router/route_names.dart';
import '../../widgets/loading_screens/user_list_skeleton.dart';

// followers: List<Map<String, dynamic>> with userId, username, profileImage
class FollowersListPage extends StatelessWidget {
  final List<dynamic> followers;
  final void Function(String userId, String? username)? onUserTap;
  final bool isLoading;
  final Set<String> currentUserFollowing;
  final Future<void> Function(String targetUserId, bool isFollow)
      onFollowToggle;
  final Set<String> loadingUserIds;
  final Set<String> pendingRequests;

  const FollowersListPage({
    Key? key,
    required this.followers,
    this.onUserTap,
    this.isLoading = false,
    required this.currentUserFollowing,
    required this.onFollowToggle,
    this.loadingUserIds = const {},
    this.pendingRequests = const {},
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Show skeleton loading screen while loading
    if (isLoading) {
      return const UserListSkeleton(title: 'Followers');
    }

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
                          context.go(AppRoutes.profile);
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
                    trailing: (follower['userId'] != null &&
                            follower['userId'] !=
                                Provider.of<AuthProvider>(context,
                                        listen: false)
                                    .user
                                    ?.id)
                        ? ElevatedButton(
                            onPressed:
                                loadingUserIds.contains(follower['userId'])
                                    ? null
                                    : () {
                                        final isFollowing = currentUserFollowing
                                            .contains(follower['userId']);
                                        final isRequested = pendingRequests
                                            .contains(follower['userId']);
                                        if (isRequested) {
                                          onFollowToggle(follower['userId'],
                                              false); // Cancel request
                                        } else {
                                          onFollowToggle(
                                              follower['userId'], !isFollowing);
                                        }
                                      },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: currentUserFollowing
                                      .contains(follower['userId'])
                                  ? Theme.of(context).colorScheme.surface
                                  : (pendingRequests
                                          .contains(follower['userId'])
                                      ? Colors.grey[400]
                                      : const Color(0xFF8E08EF)),
                              foregroundColor: currentUserFollowing
                                      .contains(follower['userId'])
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Colors.white,
                              side: currentUserFollowing
                                      .contains(follower['userId'])
                                  ? BorderSide(
                                      color:
                                          Theme.of(context).colorScheme.outline)
                                  : null,
                            ),
                            child: loadingUserIds.contains(follower['userId'])
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : Text(
                                    currentUserFollowing
                                            .contains(follower['userId'])
                                        ? 'Unfollow'
                                        : (pendingRequests
                                                .contains(follower['userId'])
                                            ? 'Requested'
                                            : 'Follow'),
                                  ),
                          )
                        : null,
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
                        context.go(AppRoutes.profile);
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
