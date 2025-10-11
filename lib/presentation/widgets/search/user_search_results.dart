import 'package:flutter/material.dart';
import '../../screens/profile/user_profiles.dart'; // Import for navigation

class UserSearchResults extends StatelessWidget {
  final List<dynamic> users;
  final String? query;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Function(String) onUserTap;

  const UserSearchResults({
    Key? key,
    required this.users,
    this.query,
    this.shrinkWrap = false,
    this.physics,
    required this.onUserTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            query == null || query!.isEmpty
                ? 'Start typing to search for users...'
                : 'No users found for "\$query"',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final userImage =
            user['userImage'] ?? 'assets/images/profile_picture.jpg';
        final isNetworkImage = userImage.startsWith('http');
        final userId = user['id'] ?? user['userId'] ?? '';

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: isNetworkImage
                ? NetworkImage(userImage) as ImageProvider
                : AssetImage(userImage) as ImageProvider,
          ),
          title: Text(user['name'] ?? 'No name'),
          subtitle: Text(
              '@${user['name']?.toLowerCase().replaceAll(' ', '') ?? 'username'}'),
          trailing: ElevatedButton(
            onPressed: () {
              // Handle follow action
            },
            child: const Text('Follow'),
          ),
          onTap: userId.isNotEmpty 
              ? () => onUserTap(userId)
              : null,
        );
      },
    );
  }
}
