import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import './user_profiles.dart'; // Import the UserProfilePage
import '../../../core/providers/auth_provider.dart';
import '../../../core/router/route_names.dart';
import '../../widgets/loading_screens/user_list_skeleton.dart';

// following: List<Map<String, dynamic>> with userId, username, profileImage
class FollowingListPage extends StatelessWidget {
  final List<dynamic> following;
  final void Function(String userId, String? username)? onUserTap;
  final bool isLoading;
  final Set<String> currentUserFollowing;
  final Future<void> Function(String targetUserId, bool isFollow)
      onFollowToggle;
  final Set<String> loadingUserIds;
  final Set<String> pendingRequests;

  const FollowingListPage({
    Key? key,
    required this.following,
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
      return const UserListSkeleton(title: 'Following');
    }

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
                      final authProvider =
                          Provider.of<AuthProvider>(context, listen: false);
                      final currentUserId = authProvider.user?.id;
                      if (user['userId'] == currentUserId) {
                        context.go(AppRoutes.profile);
                      } else {
                        if (onUserTap != null) {
                          onUserTap!(user['userId'], user['username']);
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => UserProfilePage(
                                userId: user['userId'],
                                username: user['username'],
                              ),
                            ),
                          );
                        }
                      }
                    }
                  },
                  trailing: (user['userId'] != null &&
                          user['userId'] !=
                              Provider.of<AuthProvider>(context, listen: false)
                                  .user
                                  ?.id)
                      ? ElevatedButton(
                          onPressed: loadingUserIds.contains(user['userId'])
                              ? null
                              : () {
                                  final isFollowing = currentUserFollowing
                                      .contains(user['userId']);
                                  final isRequested =
                                      pendingRequests.contains(user['userId']);
                                  if (isRequested) {
                                    onFollowToggle(user['userId'],
                                        false); // Cancel request
                                  } else {
                                    onFollowToggle(
                                        user['userId'], !isFollowing);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                currentUserFollowing.contains(user['userId'])
                                    ? Theme.of(context).colorScheme.surface
                                    : (pendingRequests.contains(user['userId'])
                                        ? Colors.grey[400]
                                        : const Color(0xFF8E08EF)),
                            foregroundColor:
                                currentUserFollowing.contains(user['userId'])
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Colors.white,
                            side: currentUserFollowing.contains(user['userId'])
                                ? BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.outline)
                                : null,
                          ),
                          child: loadingUserIds.contains(user['userId'])
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
                                  currentUserFollowing.contains(user['userId'])
                                      ? 'Unfollow'
                                      : (pendingRequests
                                              .contains(user['userId'])
                                          ? 'Requested'
                                          : 'Follow'),
                                ),
                        )
                      : null,
                );
              },
            ),
    );
  }
}
