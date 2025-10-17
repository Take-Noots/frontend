import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
// import 'dart:math';
import '../../../data/services/profile_service.dart';
import '../../../data/models/profile_model.dart';
import 'tabs/album_art_posts_tab.dart';
import 'tabs/thought_posts_tab.dart';
import 'tabs/tagged_posts_tab.dart';
// import 'my_profile.dart';
import 'followers_list.dart';
import 'following_list.dart';
import 'profile_feed_screen.dart'; // Add this import for navigation

class UserProfilePage extends StatefulWidget {
  final String userId;
  final String? highlightPostId;
  const UserProfilePage({Key? key, required this.userId, this.highlightPostId})
      : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ProfileModel? profile;
  List<dynamic> posts = [];
  List<String> albumImages = [];
  bool isLoading = true;
  String? loggedUserId;
  int postCount = 0;
  bool isPrivateProfile = false;
  bool isFollowingUser = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _getLoggedUserIdAndFetch();
  }

  Future<void> _getLoggedUserIdAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    String? id;
    if (userDataString != null) {
      final userData = jsonDecode(userDataString);
      id = userData['id'] as String?;
    }
    setState(() {
      loggedUserId = id;
    });
    await _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    setState(() {
      isLoading = true;
    });
    final profileService = ProfileService();
    final profileResult = await profileService.getUserProfile(widget.userId);
    final postsResult = await profileService.getUserPosts(widget.userId);

    // Convert raw post data to proper objects with IDs
    final formattedPosts = postsResult.map((post) {
      // Make sure each post has an id property
      if (post is Map<String, dynamic> &&
          !post.containsKey('id') &&
          post.containsKey('_id')) {
        post['id'] = post['_id']; // Ensure id exists if only _id is present
      }
      return post;
    }).toList();

    final albumImagesResult =
        await profileService.getUserAlbumImages(widget.userId);

    // --- Fetch post count from backend ---
    final postCountResult =
        await profileService.getUserPostCount(widget.userId);
    int fetchedPostCount = 0;
    if (postCountResult != null && postCountResult['postCount'] != null) {
      fetchedPostCount = postCountResult['postCount'];
    }

    if (profileResult['success'] == true && profileResult['data'] != null) {
      final profileData = ProfileModel.fromJson(profileResult['data']);

      // Check if profile is private
      final bool isPrivate = profileData.userType == 'private';

      // Check if logged user follows this user
      bool follows = false;
      if (loggedUserId != null &&
          profileData.followers.contains(loggedUserId)) {
        follows = true;
      }

      setState(() {
        profile = profileData;
        posts = formattedPosts; // Use the formatted posts
        albumImages = albumImagesResult;
        postCount = fetchedPostCount;
        isPrivateProfile = isPrivate;
        isFollowingUser = follows;
        isLoading = false;
      });

      // If highlightPostId is provided, navigate to the profile feed to show that post
      if (widget.highlightPostId != null) {
        Future.microtask(() {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileFeedScreen(
                userId: widget.userId,
                initialPostId: widget.highlightPostId,
              ),
            ),
          );
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(profile?.username ?? 'User Profile'),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
              Theme.of(context).scaffoldBackgroundColor,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: Theme.of(context).colorScheme.onSurface),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.brightness_6,
                  color: Theme.of(context).colorScheme.onSurface),
              onPressed: () {
                Provider.of<ThemeProvider>(context, listen: false)
                    .toggleTheme();
              },
            ),
          ],
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        // backgroundColor: Colors.black,
        body: Center(
            child: Text('Failed to load profile',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(profile?.username ?? 'User Profile'),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6,
                color: Theme.of(context).colorScheme.onSurface),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          AlbumArtPostsTab(
            username: profile!.username,
            fullName: profile!.fullName,
            posts: postCount,
            followers: profile!.followers.length,
            following: profile!.following.length,
            albumImages: albumImages,
            description: profile!.bio,
            showGrid: false,
            profileImage: profile!.profileImage,
            postsList: posts,
            onFollowersTap: () async {
              final profileService = ProfileService();
              final followersList = await profileService
                  .getFollowersListWithDetails(profile!.userId);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FollowersListPage(
                    followers: followersList,
                  ),
                ),
              );
            },
            onFollowingTap: () async {
              final profileService = ProfileService();
              final followingList = await profileService
                  .getFollowingListWithDetails(profile!.userId);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FollowingListPage(
                    following: followingList,
                  ),
                ),
              );
            },
            onPostTap: (postId) {
              // Debug
              print("Header section - Tapped post ID: $postId");

              // If postId is empty, try to extract it from the posts list
              String validPostId = postId;
              if (validPostId.isEmpty) {
                // Try to get the first post ID as fallback
                if (posts.isNotEmpty) {
                  final firstPost = posts[0];
                  if (firstPost is Map<String, dynamic>) {
                    validPostId =
                        (firstPost['id'] ?? firstPost['_id'])?.toString() ?? '';
                  } else if (firstPost != null) {
                    // Handle Post object if applicable
                    try {
                      validPostId = firstPost.id?.toString() ?? '';
                    } catch (e) {
                      print("Error extracting ID: $e");
                    }
                  }
                }
              }

              if (validPostId.isNotEmpty) {
                print("Header - Navigating to post ID: $validPostId");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileFeedScreen(
                      userId: widget.userId,
                      initialPostId: validPostId,
                    ),
                  ),
                );
              } else {
                print("Header - Cannot navigate: invalid post ID");
              }
            },
          ),
          // Add Follow and Message buttons for other users
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    // TODO: Implement follow functionality
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  child: Text(
                    isFollowingUser ? 'Following' : 'Follow',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () {
                    // TODO: Implement message functionality
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  child: Text(
                    'Message',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              ],
            ),
          ),

          // Only show tabs if the profile is not private or if the user follows this profile
          if (!isPrivateProfile || isFollowingUser) ...[
            Container(
              color: Theme.of(context).colorScheme.surface,
              child: TabBar(
                controller: _tabController,
                indicatorColor: Theme.of(context).colorScheme.onSurface,
                tabs: const [
                  Tab(icon: Icon(Icons.grid_on)),
                  Tab(icon: Icon(Icons.description)),
                  Tab(icon: Icon(Icons.person_pin)),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  AlbumArtPostsTab(
                    username: profile!.username,
                    fullName: profile!.fullName,
                    posts: postCount,
                    followers: profile!.followers.length,
                    following: profile!.following.length,
                    albumImages: albumImages,
                    description: profile!.bio,
                    showGrid: true,
                    profileImage: profile!.profileImage,
                    postsList: posts,
                    onPostTap: (postId) {
                      // Add debug print
                      print("Tapped post ID: $postId");

                      // Debug the post that was tapped
                      final int index = posts.indexWhere((post) {
                        if (post is Map<String, dynamic>) {
                          return post['id'] == postId || post['_id'] == postId;
                        } else if (post.runtimeType
                            .toString()
                            .contains('Post')) {
                          // Handle if it's a Post object
                          return post.id == postId;
                        }
                        return false;
                      });

                      if (index != -1) {
                        print("Found post at index: $index");
                        final post = posts[index];
                        print(
                            "Post data: ${post is Map ? post['id'] : 'object'}");
                      } else {
                        print("Post not found in list!");
                      }

                      // Ensure postId is valid and convert if needed
                      if (postId.isNotEmpty) {
                        // Ensure post ID is being passed correctly
                        final String validPostId = postId.toString();
                        print("Navigating to post ID: $validPostId");

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileFeedScreen(
                              userId: widget.userId,
                              initialPostId: validPostId,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  ThoughtPostsTab(userId: widget.userId),
                  const TaggedPostsTab(),
                ],
              ),
            ),
          ] else
            // Show private account message when profile is private and user doesn't follow
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 64,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'This Account is Private',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Follow this account to see their posts',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
