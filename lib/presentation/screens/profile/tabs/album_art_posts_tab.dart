import 'package:flutter/material.dart';
import '../../../widgets/profile/profile_stat_column.dart';
import '../../../../data/services/profile_service.dart';
import '../../../widgets/common/full_screen_image_viewer.dart';
// import '../../../widgets/profile/profile_header.dart';
import '../../../widgets/loading_screens/profile_grid_skeleton.dart';
import '../profile_feed_screen.dart';

class AlbumArtPostsTab extends StatefulWidget {
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
  final List<dynamic>? cachedPostStats; // Add cached post stats
  final bool isLoading; // Add loading state
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;
  final void Function(String postId)? onPostTap;
  final VoidCallback? onRefreshStats;
  final ValueNotifier<bool>? refreshNotifier;

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
    this.cachedPostStats,
    this.isLoading = false, // Default to false
    this.onFollowersTap,
    this.onFollowingTap,
    this.onPostTap,
    this.onRefreshStats,
    this.refreshNotifier,
  }) : super(key: key);

  @override
  State<AlbumArtPostsTab> createState() => _AlbumArtPostsTabState();
}

class _AlbumArtPostsTabState extends State<AlbumArtPostsTab> {
  late Future<List<dynamic>> _postStatsFuture;

  @override
  void initState() {
    super.initState();
    // Only fetch stats if not provided from cache
    if (widget.cachedPostStats == null) {
      _loadPostStats();
    }
    widget.refreshNotifier?.addListener(_onRefresh);
  }

  @override
  void dispose() {
    widget.refreshNotifier?.removeListener(_onRefresh);
    super.dispose();
  }

  void _onRefresh() {
    if (widget.refreshNotifier?.value == true) {
      refreshStats();
      widget.refreshNotifier?.value = false;
    }
  }

  void _loadPostStats() {
    final userId = widget.postsList.isNotEmpty
        ? (widget.postsList[0] is Map
            ? widget.postsList[0]['userId']
            : widget.postsList[0].userId)
        : '';
    _postStatsFuture = ProfileService().getUserPostStats(userId);
  }

  void refreshStats() {
    setState(() {
      _loadPostStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use cached stats if available, otherwise use future builder
    if (widget.cachedPostStats != null) {
      return _buildContent(widget.cachedPostStats!);
    }

    return FutureBuilder<List<dynamic>>(
      future: _postStatsFuture,
      builder: (context, snapshot) {
        final postStats = snapshot.data ?? [];
        return _buildContent(postStats);
      },
    );
  }

  Widget _buildSkeletonGrid() {
    return const ProfileGridSkeleton();
  }

  Widget _buildContent(List<dynamic> postStats) {
    // Make sure the grid is in a scrollable container
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          if (!widget.showGrid) ...[
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      // Open full screen image viewer
                      final imageToShow = widget.profileImage != null &&
                              widget.profileImage!.isNotEmpty
                          ? widget.profileImage!
                          : 'assets/images/hehe.png';
                      final isAsset = widget.profileImage == null ||
                          widget.profileImage!.isEmpty;

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
                          'profile_image_${widget.profileImage ?? 'assets/images/hehe.png'}',
                      child: CircleAvatar(
                        radius: 44,
                        backgroundImage: widget.profileImage != null &&
                                widget.profileImage!.isNotEmpty
                            ? NetworkImage(widget.profileImage!)
                            : const AssetImage('assets/images/hehe.png')
                                as ImageProvider,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ProfileStatColumn(label: 'Posts', count: widget.posts),
                        GestureDetector(
                          onTap: widget.onFollowersTap,
                          child: ProfileStatColumn(
                              label: 'Followers', count: widget.followers),
                        ),
                        GestureDetector(
                          onTap: widget.onFollowingTap,
                          child: ProfileStatColumn(
                              label: 'Following', count: widget.following),
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
                      widget.fullName.isNotEmpty
                          ? widget.fullName
                          : widget.username,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.description,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (widget.showGrid) ...[
            const SizedBox(height: 16),
            widget.albumImages.isEmpty && widget.isLoading
                ? _buildSkeletonGrid()
                : widget.albumImages.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            'No album arts to display.',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                          ),
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.albumImages.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 2,
                          crossAxisSpacing: 2,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) {
                          final post = widget.postsList[index];
                          // Check both 'id' and '_id' fields for compatibility
                          final postId = post is Map
                              ? (post['id'] ?? post['_id'])
                              : post.id;
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
                              if (widget.onPostTap != null && postId != null) {
                                widget.onPostTap!(postId);
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
                                  widget.albumImages[index],
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
  }
}
