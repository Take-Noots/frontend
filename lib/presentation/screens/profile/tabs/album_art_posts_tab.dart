import 'package:flutter/material.dart';
import '../../../widgets/profile/profile_stat_column.dart';
import '../../../../data/services/profile_service.dart';
import '../../../widgets/common/full_screen_image_viewer.dart';
// import '../../../widgets/profile/profile_header.dart';
import '../profile_feed_screen.dart';

class AlbumArtPostsTab extends StatelessWidget {
  final String username;
  final String fullName;
  final int posts;
  final int followers;
  final int following;
  final List<String> albumImages;
  final String description;
  final bool showGrid;
  final String? profileImage;
  final List<dynamic> postsList;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;
  final void Function(String postId)? onPostTap;

  const AlbumArtPostsTab({
    Key? key,
    required this.username,
    required this.fullName,
    required this.posts,
    required this.followers,
    required this.following,
    required this.albumImages,
    required this.description,
    this.showGrid = true,
    this.profileImage,
    required this.postsList,
    this.onFollowersTap,
    this.onFollowingTap,
    this.onPostTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userId = postsList.isNotEmpty
        ? (postsList[0] is Map ? postsList[0]['userId'] : postsList[0].userId)
        : '';
    return FutureBuilder<List<dynamic>>(
      future: ProfileService().getUserPostStats(userId),
      builder: (context, snapshot) {
        final postStats = snapshot.data ?? [];
        // Make sure the grid is in a scrollable container
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              if (!showGrid) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 24.0, horizontal: 16.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Open full screen image viewer
                          final imageToShow =
                              profileImage != null && profileImage!.isNotEmpty
                                  ? profileImage!
                                  : 'assets/images/hehe.png';
                          final isAsset =
                              profileImage == null || profileImage!.isEmpty;

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
              if (showGrid) ...[
                const SizedBox(height: 16),
                albumImages.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            'No album arts to display.',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: albumImages.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 2,
                          crossAxisSpacing: 2,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) {
                          final post = postsList[index];
                          final postId = post is Map ? post['id'] : post.id;
                          final userId =
                              post is Map ? post['userId'] : post.userId;
                          final stat = postStats.firstWhere(
                            (s) => s['postId'] == postId,
                            orElse: () => null,
                          );
                          print('post.id: $postId, stat: $stat');
                          final likeCount =
                              stat != null ? stat['likes'] ?? 0 : 0;
                          final commentCount =
                              stat != null ? stat['commentsCount'] ?? 0 : 0;
                          return GestureDetector(
                            onTap: () {
                              if (onPostTap != null && postId != null) {
                                onPostTap!(postId);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProfileFeedScreen(
                                      userId: userId,
                                      initialPostId: postId,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Stack(
                              children: [
                                Image.network(
                                  albumImages[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                                if (likeCount > 0 || commentCount > 0)
                                  Positioned(
                                    bottom: 4,
                                    left: 4,
                                    right: 4,
                                    child: Container(
                                      color: Colors.black54,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 2),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          if (likeCount > 0)
                                            Row(
                                              children: [
                                                const Icon(Icons.favorite,
                                                    color: Colors.purple,
                                                    size: 16),
                                                const SizedBox(width: 2),
                                                Text('$likeCount',
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12)),
                                              ],
                                            )
                                          else
                                            const Icon(Icons.favorite_border,
                                                color: Colors.white, size: 16),
                                          if (commentCount > 0)
                                            Row(
                                              children: [
                                                const Icon(Icons.comment,
                                                    color: Colors.white,
                                                    size: 16),
                                                const SizedBox(width: 2),
                                                Text('$commentCount',
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12)),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ],
          ),
        );
      },
    );
  }
}
