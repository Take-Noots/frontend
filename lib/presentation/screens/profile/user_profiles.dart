import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
// import 'dart:math';
import '../../../data/services/profile_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/chat_service.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/models/chat_model.dart';
import '../../screens/chat/chat_screen.dart';
import '../../widgets/loading_screens/chat_loading_screen.dart';
import '../../widgets/loading_screens/profile_loading_screen.dart';
import 'tabs/album_art_posts_tab.dart';
import 'tabs/thought_posts_tab.dart';
import 'tabs/tagged_posts_tab.dart';
import 'my_profile.dart';
import 'followers_list_wrapper.dart';
import 'following_list_wrapper.dart';
import 'profile_feed_screen.dart'; // Add this import for navigation

class UserProfilePage extends StatefulWidget {
  final String userId;
  final String? username;
  final String? highlightPostId;
  const UserProfilePage(
      {Key? key, required this.userId, this.username, this.highlightPostId})
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

      // If this is the logged user's own profile, redirect to my profile page
      if (widget.userId == loggedUserId) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const NormalUserProfilePage()),
        );
        return;
      }

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

  Future<void> _handleFollow() async {
    if (loggedUserId == null || profile == null) return;

    // Prevent following yourself
    if (loggedUserId == profile!.userId) return;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final profileService = ProfileService(authService: authService);
      final result = isFollowingUser
          ? await profileService.unfollowUser(loggedUserId!, profile!.userId)
          : await profileService.followUser(loggedUserId!, profile!.userId);

      if (result['success'] == true) {
        setState(() {
          isFollowingUser = !isFollowingUser;
          if (isFollowingUser) {
            profile!.followers.add(loggedUserId!);
          } else {
            profile!.followers.remove(loggedUserId!);
          }
        });
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ??
                'Failed to ${isFollowingUser ? 'unfollow' : 'follow'} user'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Error: ${isFollowingUser ? 'unfollowing' : 'following'} user failed'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _handleMessage() async {
    if (profile == null || loggedUserId == null) return;

    // Prevent messaging yourself
    if (loggedUserId == profile!.userId) return;

    // Navigate immediately to loading screen with seamless transition
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ChatLoadingScreen(
          profile: profile,
          loadingText: 'Starting chat...',
          onBackPressed: () => Navigator.of(context).pop(),
        ),
        transitionDuration: Duration.zero, // No transition animation
        reverseTransitionDuration: Duration.zero,
      ),
    );

    try {
      final chatService = ChatService();
      final result = await chatService.createChat(profile!.userId);

      if (result['success']) {
        final chatData = result['data'];
        final chat = Chat.fromJson(chatData, loggedUserId!);

        // Replace loading screen with actual chat screen seamlessly
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => ChatScreen(
              chat: chat,
              currentUserId: loggedUserId!,
            ),
            transitionDuration: Duration.zero, // No transition animation
            reverseTransitionDuration: Duration.zero,
          ),
        );
      } else {
        // Show error and go back to profile
        Navigator.of(context).pop(); // Remove loading screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to start chat'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      // Show error and go back to profile
      Navigator.of(context).pop(); // Remove loading screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting chat: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return ProfileLoadingScreen(
        title: widget.username ?? 'User Profile',
        // subtitle: 'Loading profile...',
        onBackPressed: () => Navigator.of(context).pop(),
        showSkeleton: true,
      );
    }
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('User Profile'),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
              Theme.of(context).scaffoldBackgroundColor,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: Theme.of(context).colorScheme.onSurface),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            onFollowersTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FollowersListPageWrapper(
                    userId: profile!.userId,
                  ),
                ),
              );
            },
            onFollowingTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FollowingListPageWrapper(
                    userId: profile!.userId,
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
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _handleFollow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowingUser
                          ? Theme.of(context).colorScheme.surface
                          : const Color(0xFFA855F7), // Purple for follow
                      foregroundColor: isFollowingUser
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isFollowingUser
                            ? BorderSide(
                                color: Theme.of(context).colorScheme.outline)
                            : BorderSide.none,
                      ),
                    ),
                    child: Text(
                      isFollowingUser ? 'Following' : 'Follow',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 140,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: _handleMessage,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                    child: const Text(
                      'Message',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
