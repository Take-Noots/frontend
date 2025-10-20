import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Uncomment this
import 'dart:convert'; // Uncomment this
import 'tabs/album_art_posts_tab.dart';
import 'tabs/thought_posts_tab.dart';
import 'tabs/tagged_posts_tab.dart';

import 'settings/create_profile.dart';
import 'settings/edit_profile.dart';
import './settings/options.dart';
import 'followers_list_wrapper.dart';
import 'following_list_wrapper.dart';
import 'profile_feed_screen.dart';
import './user_profiles.dart';
import 'tabs/artist/new_releases_tab.dart'; // Create this for artist features
import 'tabs/artist/concerts_tab.dart'; // Create this for artist features
import 'tabs/artist/upcoming_tab.dart'; // Create this for artist features
import 'tabs/artist/insights_tab.dart'; // Create this for artist features
import 'tabs/business/ads_tab.dart'; // Create this for business features
import '../../widgets/loading_screens/profile_loading_screen.dart';

import '../../../data/models/profile_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/router/route_names.dart';

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
  String? username;
  ProfileModel? profile;
  List<dynamic> posts = [];
  List<String> albumImages = [];
  bool isLoading = true;

  bool profileNotFound = false;
  int postCount = 0;
  List<dynamic> postStats = []; // Add post stats storage
  List<dynamic> thoughtPosts = []; // Add thought posts storage
  final ValueNotifier<bool> refreshTabNotifier = ValueNotifier(false);

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
      if (authProvider.user == null) {
        final prefs = await SharedPreferences.getInstance();
        final userDataString = prefs.getString('user_data');
        print("SharedPrefs user_data: $userDataString");

        if (userDataString != null) {
          final userData = jsonDecode(userDataString);
          id = userData['id'] as String?;
          username = userData['username'] as String?;
          print("Extracted ID from SharedPrefs: $id");
          print("Extracted username from SharedPrefs: $username");
        }
      }

      if (mounted) {
        setState(() {
          userId = id;
          username = username;
        });
      }

      if (userId == null) {
        print("WARNING: User ID is still null after all attempts");
      } else {
        print("User ID set: $userId");
      }

      _fetchProfileData();
    } catch (e) {
      print("Error in _initUserIdAndFetch: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchProfileData() async {
    if (userId == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    // 🔑 Use ProfileProvider for caching
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);

    // ⚡ Two-stage loading for better UX:
    // Stage 1: Check if we have cached data - show header immediately
    final existingCache = profileProvider.getCachedProfile(userId!);
    if (existingCache != null &&
        existingCache.hasProfile &&
        existingCache.isValid) {
      // Update TabController based on cached profile
      final userType = existingCache.profile?.userType ?? 'public';
      int tabCount = 3;
      if (userType == 'artist')
        tabCount = 5;
      else if (userType == 'business') tabCount = 3;
      if (_tabController == null || _tabController!.length != tabCount) {
        _tabController?.dispose();
        _tabController = TabController(length: tabCount, vsync: this);
      }

      // Show cached header data immediately (instant!)
      if (mounted) {
        setState(() {
          profile = existingCache.profile;
          postCount = existingCache.postCount;
          isLoading = false; // Show header immediately
        });
      }

      // Then load full data (posts, stats, etc.) in background
      await profileProvider.loadProfile(userId!, context: context);
      final cachedProfile = profileProvider.getCachedProfile(userId!);

      if (cachedProfile != null && mounted) {
        setState(() {
          posts = cachedProfile.posts;
          albumImages = cachedProfile.albumImages;
          postCount = cachedProfile.postCount;
          postStats = cachedProfile.postStats;
          thoughtPosts = cachedProfile.thoughtPosts;
        });
      }
      return;
    }

    // Stage 2: No cache - fetch everything
    await profileProvider.loadProfile(userId!, context: context);

    // Get cached profile data
    final cachedProfile = profileProvider.getCachedProfile(userId!);

    if (cachedProfile == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    if (cachedProfile.isLoading) {
      // Still loading, wait
      return;
    }

    if (cachedProfile.hasError && cachedProfile.isProfileNotFound) {
      if (mounted) {
        setState(() {
          profile = null;
          profileNotFound = true;
          isLoading = false;
        });
      }
      return;
    }

    if (cachedProfile.hasError) {
      if (mounted) {
        setState(() {
          profile = null;
          profileNotFound = false;
          isLoading = false;
        });
      }
      return;
    }

    // ⚡ Performance optimization: Don't convert posts to Post objects
    // AlbumArtPostsTab can handle raw JSON, so skip expensive fromJson conversion

    final userType = cachedProfile.profile?.userType ?? 'public';
    int tabCount = 3;
    if (userType == 'artist')
      tabCount = 5;
    else if (userType == 'business') tabCount = 3;
    if (_tabController == null || _tabController!.length != tabCount) {
      _tabController?.dispose();
      _tabController = TabController(length: tabCount, vsync: this);
    }

    if (mounted) {
      setState(() {
        profile = cachedProfile.profile;
        posts = cachedProfile.posts; // Use raw JSON directly
        albumImages = cachedProfile.albumImages;
        postCount = cachedProfile.postCount;
        postStats = cachedProfile.postStats; // Store cached post stats
        thoughtPosts = cachedProfile.thoughtPosts; // Store cached thought posts
        profileNotFound = false;
        isLoading = false;
      });
    }
  }

  // 🔄 Manual refresh method (for pull-to-refresh)
  Future<void> _handleRefresh() async {
    if (userId == null) return;

    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    await profileProvider.refreshProfile(userId!, context: context);

    // Update UI with refreshed data
    await _fetchProfileData();
    refreshTabNotifier.value = !refreshTabNotifier.value;
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
          cachedPostStats: postStats, // Pass cached post stats
          isLoading: posts.isEmpty,
          onPostTap: (postId) async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileFeedScreen(
                  userId: userId!,
                  initialPostId: postId,
                ),
              ),
            );
            refreshTabNotifier.value = true;
          },
          refreshNotifier: refreshTabNotifier,
        ),
        ArtistNewReleasesTab(userId: userId!), // Implement this tab
        ThoughtPostsTab(
            postsList: thoughtPosts,
            userId: userId,
            refreshNotifier: refreshTabNotifier),
        ArtistConcertsTab(userId: userId!), // Implement this tab
        ArtistUpcomingTab(userId: userId!), // Implement this tab
        // ArtistInsightsTab(userId: userId!),
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
          cachedPostStats: postStats, // Pass cached post stats
          isLoading: posts.isEmpty,
          onPostTap: (postId) async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileFeedScreen(
                  userId: userId!,
                  initialPostId: postId,
                ),
              ),
            );
            refreshTabNotifier.value = true;
          },
          refreshNotifier: refreshTabNotifier,
        ),
        BusinessAdsTab(
            userId: userId!,
            refreshNotifier: refreshTabNotifier), // Implement this tab
        ThoughtPostsTab(
            postsList: thoughtPosts,
            userId: userId,
            refreshNotifier: refreshTabNotifier),
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
          cachedPostStats: postStats, // Pass cached post stats
          isLoading: posts.isEmpty,
          onPostTap: (postId) async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileFeedScreen(
                  userId: userId!,
                  initialPostId: postId,
                ),
              ),
            );
            refreshTabNotifier.value = true;
          },
          refreshNotifier: refreshTabNotifier,
        ),
        ThoughtPostsTab(
            postsList: thoughtPosts,
            userId: userId,
            refreshNotifier: refreshTabNotifier),
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
    // ⚡ Show loading screen only if we have NO profile data at all
    // If we have profile data (even if loading posts), show the profile with header
    if (isLoading && profile == null) {
      return ProfileLoadingScreen(
        title: username ?? 'My Profile',
        showSkeleton: true,
        isMyProfile: true,
      );
    }

    if (userId == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Text(
            'User not found. Please log in again.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      );
    }

    if (profile == null && profileNotFound) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Text(
                'No profile found for this user.',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18),
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
                  side: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface),
                ),
                child: Text(
                  'Create Profile',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (profile == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
            child: Text('Failed to load profile',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        // Remove leading, add actions for right top
        title: Text(profile?.username ?? 'Profile'),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
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
      body: RefreshIndicator(
        onRefresh: _handleRefresh, // 🔄 Pull-to-refresh support
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
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
                cachedPostStats: postStats, // Pass cached post stats
                isLoading: posts.isEmpty,

                // --- Add gesture detectors for followers/following ---
                onFollowersTap: () {
                  if (profile != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FollowersListPageWrapper(
                          userId: profile!.userId,
                          onUserTap: (userId, username) {
                            final authProvider = Provider.of<AuthProvider>(
                                context,
                                listen: false);
                            final currentUserId = authProvider.user?.id;
                            if (userId == currentUserId) {
                              context.go(AppRoutes.profile);
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserProfilePage(
                                    userId: userId,
                                    username: username,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  }
                },
                onFollowingTap: () {
                  if (profile != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FollowingListPageWrapper(
                          userId: profile!.userId,
                          onUserTap: (userId, username) {
                            final authProvider = Provider.of<AuthProvider>(
                                context,
                                listen: false);
                            final currentUserId = authProvider.user?.id;
                            if (userId == currentUserId) {
                              context.go(AppRoutes.profile);
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserProfilePage(
                                    userId: userId,
                                    username: username,
                                  ),
                                ),
                              );
                            }
                          },
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
                          icon: Icon(Icons.insights,
                              color: Theme.of(context).colorScheme.onSurface),
                          label: Text(
                            'Insights',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Theme.of(context).colorScheme.onSurface),
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
                              builder: (context) => const EditProfilePage(),
                            ),
                          );
                          // If profile was updated, refresh the page
                          if (result == true && mounted) {
                            _fetchProfileData();
                          }
                        },
                        icon: Icon(Icons.edit,
                            color: Theme.of(context).colorScheme.onSurface),
                        label: Text(
                          'Edit Profile',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: Theme.of(context).colorScheme.onSurface),
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
                color: Theme.of(context).colorScheme.surface,
                width: MediaQuery.of(context).size.width,
                padding: EdgeInsets.zero,
                margin: EdgeInsets.zero,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Theme.of(context).colorScheme.onSurface,
                  isScrollable: false,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 0),
                  // Use primary color for active tab so icons are visible over dark backgrounds
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor:
                      Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.9),
                  tabs: getProfileTabs(),
                ),
              ),
              // TabBarView for posts - Make sure each tab view is scrollable
              SizedBox(
                height: 400, // Fixed height for TabBarView inside ScrollView
                child: profile != null && _tabController != null
                    ? TabBarView(
                        physics:
                            const AlwaysScrollableScrollPhysics(), // Enable scrolling in TabBarView
                        controller: _tabController,
                        children: getProfileTabViews(),
                      )
                    : Center(
                        child: Text(
                          'No profile data available.',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }
}
