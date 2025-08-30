// import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Uncomment this
import 'dart:convert'; // Uncomment this
import 'tabs/album_art_posts_tab.dart';
import 'tabs/thought_posts_tab.dart';
import 'tabs/tagged_posts_tab.dart';
import 'settings/edit_profile.dart';

import 'settings/create_profile.dart';
import './settings/options.dart';
import 'followers_list.dart';
import 'following_list.dart';
import 'profile_feed_screen.dart';
import 'tabs/artist/new_releases_tab.dart'; // Create this for artist features
import 'tabs/artist/concerts_tab.dart'; // Create this for artist features
import 'tabs/artist/upcoming_tab.dart'; // Create this for artist features
import 'tabs/artist/insights_tab.dart'; // Create this for artist features
import 'tabs/business/ads_tab.dart'; // Create this for business features
import 'tabs/business/ad_insights_tab.dart'; // Create this for business features

import '../../../data/services/profile_service.dart';
import '../../../data/models/profile_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/models/post_model.dart';
import '../../widgets/common/bottom_bar.dart';

class NormalUserProfilePage extends StatefulWidget {
  static const routeName = '/profile/normal';

  const NormalUserProfilePage({Key? key}) : super(key: key);

  @override
  State<NormalUserProfilePage> createState() => _NormalUserProfilePageState();
}

class _NormalUserProfilePageState extends State<NormalUserProfilePage>
    with TickerProviderStateMixin {
  TabController? _tabController;
  final ScrollController _tabScrollController = ScrollController(); // Add this

  String? userId;
  ProfileModel? profile;
  List<dynamic> posts = [];
  List<String> albumImages = [];
  bool isLoading = true;

  bool profileNotFound = false;
  int postCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabScrollController.addListener(() {
      if (_tabScrollController.offset < 0) {
        _tabScrollController.jumpTo(0);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _initUserIdAndFetch());
  }

  Future<void> _initUserIdAndFetch() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      String? id = authProvider.user?.id;

      // Add debug print
      print("AuthProvider user ID: $id");

      // If ID is null, try to get it from SharedPreferences directly
      if (id == null) {
        final prefs = await SharedPreferences.getInstance();
        final userDataString = prefs.getString('user_data');
        print("SharedPrefs user_data: $userDataString");

        if (userDataString != null) {
          final userData = jsonDecode(userDataString);
          id = userData['id'] as String?;
          print("Extracted ID from SharedPrefs: $id");
        }
      }

      setState(() {
        userId = id;
      });

      if (userId == null) {
        print("WARNING: User ID is still null after all attempts");
      } else {
        print("User ID set: $userId");
      }

      _fetchProfileData();
    } catch (e) {
      print("Error in _initUserIdAndFetch: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchProfileData() async {
    if (userId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }
    setState(() {
      isLoading = true;
    });
    final profileService = ProfileService();
    final profileResult = await profileService.getUserProfile(userId!);
    final postsResult = await profileService.getUserPosts(userId!);
    // Convert each map to a Post object
    final postObjects = postsResult.map((json) => Post.fromJson(json)).toList();
    final albumImagesResult = await profileService.getUserAlbumImages(userId!);

    // --- Fetch post count from backend ---
    final postCountResult = await profileService.getUserPostCount(userId!);
    int fetchedPostCount = 0;
    if (postCountResult != null && postCountResult['postCount'] != null) {
      fetchedPostCount = postCountResult['postCount'];
    }

    if (profileResult['success'] == true && profileResult['data'] != null) {
      setState(() {
        profile = ProfileModel.fromJson(profileResult['data']);
        posts = postObjects;
        albumImages = albumImagesResult;
        postCount = fetchedPostCount;

        profileNotFound = false;
        isLoading = false;

        // --- Only recreate TabController here after profile is loaded ---
        final tabCount = getProfileTabs().length;
        if (_tabController == null || _tabController!.length != tabCount) {
          _tabController?.dispose();
          _tabController = TabController(length: tabCount, vsync: this);
        }
      });
    } else if (profileResult['message'] == 'Profile not found') {
      setState(() {
        profile = null;
        profileNotFound = true;

        isLoading = false;
      });
    } else {
      setState(() {
        profile = null;
        profileNotFound = false;

        isLoading = false;
      });
    }
  }

  // Helper to get user type (normal, artist, business)
  String get userType => profile?.userType ?? 'public';

  // Helper to get tabs based on user type
  List<Tab> getProfileTabs() {
    if (userType == 'artist') {
      return const [
        Tab(icon: Icon(Icons.grid_on), text: "Posts"),
        Tab(icon: Icon(Icons.music_note), text: "New Releases"),
        Tab(icon: Icon(Icons.description), text: "Description"),
        Tab(icon: Icon(Icons.event), text: "Concerts"),
        Tab(icon: Icon(Icons.upcoming), text: "Upcoming"),
        Tab(icon: Icon(Icons.person_pin), text: "Tagged"),
      ];
    } else if (userType == 'business') {
      return const [
        Tab(icon: Icon(Icons.grid_on), text: "Posts"),
        Tab(icon: Icon(Icons.campaign), text: "Advertisements"),
        Tab(icon: Icon(Icons.analytics), text: "Ad Insights"),
        Tab(icon: Icon(Icons.description), text: "Description"),
        Tab(icon: Icon(Icons.person_pin), text: "Tagged"),
      ];
    } else {
      return const [
        Tab(icon: Icon(Icons.grid_on)),
        Tab(icon: Icon(Icons.description)),
        Tab(icon: Icon(Icons.person_pin)),
      ];
    }
  }

  // Helper to get tab views based on user type
  List<Widget> getProfileTabViews() {
    if (userType == 'artist') {
      return [
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileFeedScreen(
                  userId: userId!,
                  initialPostId: postId,
                ),
              ),
            );
          },
        ),
        ArtistNewReleasesTab(userId: userId!), // Implement this tab
        ThoughtPostsTab(postsList: posts, userId: userId),
        ArtistConcertsTab(userId: userId!), // Implement this tab
        ArtistUpcomingTab(userId: userId!), // Implement this tab
        // ArtistInsightsTab(userId: userId!), // REMOVE
        const TaggedPostsTab(),
      ];
    } else if (userType == 'business') {
      return [
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileFeedScreen(
                  userId: userId!,
                  initialPostId: postId,
                ),
              ),
            );
          },
        ),
        BusinessAdsTab(userId: userId!), // Implement this tab
        BusinessAdInsightsTab(userId: userId!), // Implement this tab
        ThoughtPostsTab(postsList: posts, userId: userId),
        const TaggedPostsTab(),
      ];
    } else {
      return [
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileFeedScreen(
                  userId: userId!,
                  initialPostId: postId,
                ),
              ),
            );
          },
        ),
        ThoughtPostsTab(postsList: posts, userId: userId),
        const TaggedPostsTab(),
      ];
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _tabScrollController.dispose(); // Dispose controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userId == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'User not found. Please log in again.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    if (profile == null && profileNotFound) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          centerTitle: true,
          backgroundColor: Colors.black,
        ),
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Text(
                  'No profile found for this user.',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              SizedBox(
                width: 160,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CreateProfilePage()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                  ),
                  child: const Text(
                    'Create Profile',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (profile == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
            child: Text('Failed to load profile',
                style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        // Remove leading, add actions for right top
        title: Text(profile?.username ?? 'Profile'),
        centerTitle: true,
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OptionsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Profile details (header, stats, description)
          AlbumArtPostsTab(
            username: profile?.username ?? '',
            fullName: profile?.fullName ?? '',
            posts: postCount,
            followers: profile?.followers.length ?? 0,
            following: profile?.following.length ?? 0,
            albumImages: albumImages,
            description: profile?.bio ?? '',
            showGrid: false,
            profileImage: profile?.profileImage ?? '',
            postsList: posts,

            // --- Add gesture detectors for followers/following ---
            onFollowersTap: () async {
              if (profile != null) {
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
              }
            },
            onFollowingTap: () async {
              if (profile != null) {
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
              }
            },
            // Make posts clickable
            onPostTap: (postId) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileFeedScreen(
                    userId: userId!,
                    initialPostId: postId,
                  ),
                ),
              );
            },
          ),
          // --- Add Insights and Edit Profile Buttons aligned horizontally ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Insights Button (left side)
                if (userType == 'artist')
                  SizedBox(
                    width: 160,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ArtistInsightsTab(userId: userId!),
                          ),
                        );
                      },
                      icon: const Icon(Icons.insights, color: Colors.white),
                      label: const Text(
                        'Insights',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        backgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                if (userType == 'artist') const SizedBox(width: 12),
                // Edit Profile Button (right side)
                SizedBox(
                  width: 160,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const EditProfilePage()),
                      );
                      if (result == true) {
                        // Only fetch if profile was updated
                        await _fetchProfileData();
                      }
                    },
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text(
                      'Edit Profile',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // TabBar under profile details
          Container(
            color: Colors.black,
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.zero,
            margin: EdgeInsets.zero,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              isScrollable: false,
              labelPadding: const EdgeInsets.symmetric(horizontal: 0),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              tabs: getProfileTabs(),
            ),
          ),
          // TabBarView for posts - Make sure each tab view is scrollable
          Expanded(
            child: profile != null && _tabController != null
                ? TabBarView(
                    physics:
                        const AlwaysScrollableScrollPhysics(), // Enable scrolling in TabBarView
                    controller: _tabController,
                    children: getProfileTabViews(),
                  )
                : const Center(
                    child: Text(
                      'No profile data available.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      bottomNavigationBar: const BottomBar(),
    );
  }
}
