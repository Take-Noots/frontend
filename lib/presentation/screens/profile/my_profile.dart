import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Uncomment this
import 'dart:convert'; // Uncomment this
import 'tabs/album_art_posts_tab.dart';
import 'tabs/thought_posts_tab.dart';

import 'settings/create_profile.dart';
import 'settings/edit_profile.dart';
import './settings/options.dart';
import 'followers_list_wrapper.dart';
import 'following_list_wrapper.dart';
import 'profile_feed_screen.dart';
import './user_profiles.dart';
import 'tabs/business/ads_tab.dart';
import '../../widgets/loading_screens/profile_loading_screen.dart';
import 'follow_requests.dart';

import '../../../data/models/profile_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../data/services/profile_service.dart';
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
    _tabController = TabController(length: 2, vsync: this);
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
      int tabCount = 2; // Default for normal users
      if (userType == 'artist')
        tabCount = 3;
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

    if (cachedProfile.hasError) {
      // If provider already marked it as not found, reflect that
      if (cachedProfile.isProfileNotFound) {
        if (mounted) {
          setState(() {
            profile = null;
            profileNotFound = true;
            isLoading = false;
          });
        }
        return;
      }

      // Otherwise we may have a different error (network/server). Try a
      // lightweight existence check using ProfileService.getUserProfile to
      // distinguish 'Profile not found' from other failures. This helps show
      // the Create Profile button when the backend explicitly reports absence.
      try {
        final profileService = ProfileService();
        final result = await profileService.getUserProfile(userId!);
        if (result['message'] == 'Profile not found') {
          if (mounted) {
            setState(() {
              profile = null;
              profileNotFound = true;
              isLoading = false;
            });
          }
          return;
        }
      } catch (e) {
        // ignore - we'll fall back to showing a generic error
      }

      // Fallback for other errors
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
    int tabCount = 2; // Default for normal users
    if (userType == 'artist')
      tabCount = 3;
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
    // Use smaller icon sizes to fit the reduced TabBar height
    const double iconSize = 20.0;

    if (userType == 'artist') {
      return [
        const Tab(icon: Icon(Icons.grid_on, size: iconSize), text: "Posts"),
        const Tab(
            icon: Icon(Icons.campaign, size: iconSize), text: "Advertisements"),
        const Tab(
            icon: Icon(Icons.description, size: iconSize), text: "Description"),
      ];
    } else if (userType == 'business') {
      return [
        const Tab(icon: Icon(Icons.grid_on, size: iconSize), text: "Posts"),
        const Tab(
            icon: Icon(Icons.campaign, size: iconSize), text: "Advertisements"),
        const Tab(
            icon: Icon(Icons.description, size: iconSize), text: "Description"),
      ];
    } else {
      return const [
        Tab(icon: Icon(Icons.grid_on, size: iconSize)),
        Tab(icon: Icon(Icons.description, size: iconSize)),
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
        BusinessAdsTab(userId: userId!, refreshNotifier: refreshTabNotifier),
        ThoughtPostsTab(
            postsList: thoughtPosts,
            userId: userId,
            refreshNotifier: refreshTabNotifier),
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
        BusinessAdsTab(userId: userId!, refreshNotifier: refreshTabNotifier),
        ThoughtPostsTab(
            postsList: thoughtPosts,
            userId: userId,
            refreshNotifier: refreshTabNotifier),
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
    // Helper to build a consistent AppBar with settings icon so it's
    // always present even on loading/error screens.
    AppBar _buildAppBar(String title) {
      return AppBar(
        title: Text(title),
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
      );
    }

    // ⚡ Show loading screen only if we have NO profile data at all
    // If we have profile data (even if loading posts), show the profile with header
    if (isLoading && profile == null) {
      // Ensure settings icon is visible even on the loading skeleton.
      return Scaffold(
        appBar: _buildAppBar(username ?? 'My Profile'),
        body: ProfileLoadingScreen(
          title: username ?? 'My Profile',
          showSkeleton: true,
          isMyProfile: true,
          showAppBar: false, // avoid nested AppBar inside the body
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      );
    }

    if (userId == null) {
      return Scaffold(
        appBar: _buildAppBar('Profile'),
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
        appBar: _buildAppBar('Profile'),
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(
                width: 220,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CreateProfilePage()),
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Create Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14.0, horizontal: 12.0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0)),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (profile == null) {
      return Scaffold(
        appBar: _buildAppBar('Profile'),
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
              // --- Edit Profile Button ---
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Edit Profile Button
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
                    const SizedBox(width: 12),
                    // If this user is private, show Follow Requests button
                    if (profile?.userType == 'private')
                      SizedBox(
                        width: 140,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const FollowRequestsPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.person_add_alt_1),
                          label: const Text('Follow Requests'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.surface,
                            foregroundColor:
                                Theme.of(context).colorScheme.onSurface,
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
                child: SizedBox(
                  height: 50,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: Theme.of(context).colorScheme.onSurface,
                    indicatorWeight: 2,
                    isScrollable: false,
                    labelPadding:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
                    // Use explicit gray tones so the active tab icon is consistently gray
                    labelColor: Colors.grey[700],
                    unselectedLabelColor: Colors.grey[500],
                    labelStyle: const TextStyle(fontSize: 12),
                    unselectedLabelStyle: const TextStyle(fontSize: 12),
                    tabs: getProfileTabs(),
                  ),
                ),
              ),
              // TabBarView for posts - Make sure each tab view is scrollable
              SizedBox(
                height: MediaQuery.of(context).size.height - 320,
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
