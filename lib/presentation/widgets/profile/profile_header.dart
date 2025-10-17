import 'package:flutter/material.dart';
import 'profile_stat_column.dart';
import '../common/full_screen_image_viewer.dart';

class ProfileHeader extends StatelessWidget {
  final String username;
  final String fullName;
  final int posts;
  final int followers;
  final int following;
  final String? profileImage;
  final String description;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;

  const ProfileHeader({
    Key? key,
    required this.username,
    required this.fullName,
    required this.posts,
    required this.followers,
    required this.following,
    required this.profileImage,
    required this.description,
    this.onFollowersTap,
    this.onFollowingTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  // Open full screen image viewer
                  final imageToShow =
                      profileImage != null && profileImage!.isNotEmpty
                          ? profileImage!
                          : 'assets/images/hehe.png';
                  final isAsset = profileImage == null || profileImage!.isEmpty;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImageViewer(
                        imageUrl: imageToShow,
                        isAssetImage: isAsset,
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag:
                      'profile_image_${profileImage ?? 'assets/images/hehe.png'}',
                  child: CircleAvatar(
                    radius: 44,
                    backgroundImage:
                        profileImage != null && profileImage!.isNotEmpty
                            ? NetworkImage(profileImage!)
                            : const AssetImage('assets/images/hehe.png')
                                as ImageProvider,
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ProfileStatColumn(label: 'Posts', count: posts),
                    GestureDetector(
                      onTap: onFollowersTap,
                      child: ProfileStatColumn(
                          label: 'Followers', count: followers),
                    ),
                    GestureDetector(
                      onTap: onFollowingTap,
                      child: ProfileStatColumn(
                          label: 'Following', count: following),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.isNotEmpty ? fullName : username,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
