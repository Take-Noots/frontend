import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/models/profile_model.dart';
import '../../data/services/profile_service.dart';
import '../../data/services/thoughts_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  final ThoughtsService _thoughtsService = ThoughtsService();

  // Cache for multiple profiles (key: userId)
  final Map<String, CachedProfile> _profileCache = {};
  
  // Cache duration - 5 minutes (only used as maximum stale time)
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Get cached profile if valid
  CachedProfile? getCachedProfile(String userId) {
    final cached = _profileCache[userId];
    if (cached != null && cached.isValid) {
      debugPrint('✅ [ProfileProvider] Using cached profile for userId: $userId');
      return cached;
    }
    return null;
  }

  // Load profile (uses cache if valid)
  Future<void> loadProfile(String userId, {bool forceRefresh = false, BuildContext? context}) async {
    final cached = getCachedProfile(userId);
    
    // If forcing refresh, skip all cache checks
    if (forceRefresh) {
      debugPrint('🔄 [ProfileProvider] Force refresh requested for userId: $userId');
      await _fetchProfile(userId, context);
      return;
    }
    
    // If no cache exists, fetch fresh data
    if (cached == null) {
      debugPrint('🌐 [ProfileProvider] No cache found, fetching fresh data for userId: $userId');
      await _fetchProfile(userId, context);
      return;
    }
    
    // If cache is too old (> 5 minutes), always refresh
    if (!cached.isValid) {
      debugPrint('⏰ [ProfileProvider] Cache expired (> 5 min), fetching fresh data for userId: $userId');
      await _fetchProfile(userId, context);
      return;
    }
    
    // Cache is valid (< 5 min), but check if server has updates
    debugPrint('🔍 [ProfileProvider] Checking for server updates for userId: $userId');
    final hasUpdates = await _checkForServerUpdates(userId, cached, context);
    
    if (hasUpdates) {
      debugPrint('🆕 [ProfileProvider] Server has updates, fetching fresh data for userId: $userId');
      await _fetchProfile(userId, context);
    } else {
      debugPrint('✅ [ProfileProvider] Using cached profile (no server changes) for userId: $userId');
      // Cache is valid and no changes detected - use it
      return;
    }
  }

  // Check if server has updates since last fetch (lightweight check)
  Future<bool> _checkForServerUpdates(String userId, CachedProfile cached, BuildContext? context) async {
    try {
      // Strategy 1: Check post count (lightweight)
      final postCountResult = await _profileService.getUserPostCount(userId);
      final serverPostCount = postCountResult?['postCount'] ?? 0;
      
      if (serverPostCount != cached.postCount) {
        debugPrint('📊 [ProfileProvider] Post count changed: ${cached.postCount} → $serverPostCount');
        return true;
      }
      
      // Strategy 2: Get profile and check updatedAt field (if backend provides it)
      final profileResult = await _profileService.getUserProfile(userId);
      if (profileResult['success'] == true && profileResult['data'] != null) {
        final data = profileResult['data'];
        
        // Check if profile has an updatedAt field
        // Note: If ProfileModel doesn't have updatedAt, this section is skipped
        // TODO: Add updatedAt field to ProfileModel if available from backend
        
        // Check follower count changes
        if (data['followers'] != null && cached.profile != null) {
          final serverFollowersCount = (data['followers'] as List?)?.length ?? 0;
          final cachedFollowersCount = cached.profile!.followers.length;
          
          if (serverFollowersCount != cachedFollowersCount) {
            debugPrint('👥 [ProfileProvider] Followers changed: $cachedFollowersCount → $serverFollowersCount');
            return true;
          }
        }
        
        // Check following count changes
        if (data['following'] != null && cached.profile != null) {
          final serverFollowingCount = (data['following'] as List?)?.length ?? 0;
          final cachedFollowingCount = cached.profile!.following.length;
          
          if (serverFollowingCount != cachedFollowingCount) {
            debugPrint('👤 [ProfileProvider] Following changed: $cachedFollowingCount → $serverFollowingCount');
            return true;
          }
        }
      }
      
      // No changes detected
      return false;
    } catch (e) {
      debugPrint('⚠️ [ProfileProvider] Error checking for updates, will use cache: $e');
      // If check fails, use cache (fail-safe)
      return false;
    }
  }

  // Helper to fetch user thoughts with authentication
  Future<List<dynamic>> _fetchUserThoughts(String userId, BuildContext? context) async {
    try {
      final result = await _thoughtsService.getUserThoughts(userId, context);
      if (result['success'] == true && result['data'] is List) {
        return result['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [ProfileProvider] Error fetching thought posts: $e');
      return [];
    }
  }

  // Internal method to fetch profile data from server
  Future<void> _fetchProfile(String userId, BuildContext? context) async {
    
    // Update loading state
    final existingCache = _profileCache[userId];
    _profileCache[userId] = CachedProfile(
      userId: userId,
      isLoading: true,
      profile: existingCache?.profile,
      posts: existingCache?.posts ?? [],
      albumImages: existingCache?.albumImages ?? [],
      postCount: existingCache?.postCount ?? 0,
      postStats: existingCache?.postStats ?? [],
      thoughtPosts: existingCache?.thoughtPosts ?? [],
      error: null,
      lastFetchTime: DateTime.now(),
    );
    notifyListeners();

    try {
      // Fetch all profile data in parallel
      final results = await Future.wait([
        _profileService.getUserProfile(userId),
        _profileService.getUserPosts(userId),
        _profileService.getUserAlbumImages(userId),
        _profileService.getUserPostCount(userId),
        _profileService.getUserPostStats(userId),
        _fetchUserThoughts(userId, context),  // ✅ Use authenticated request
      ]);

      final profileResult = results[0] as Map<String, dynamic>;
      final postsResult = results[1] as List<dynamic>;
      final albumImagesResult = results[2] as List<String>;
      final postCountResult = results[3] as Map<String, dynamic>?;
      final postStatsResult = results[4] as List<dynamic>;
      final thoughtPostsResult = results[5] as List<dynamic>;

      if (profileResult['success'] == true && profileResult['data'] != null) {
        final profile = ProfileModel.fromJson(profileResult['data']);
        final postCount = postCountResult?['postCount'] ?? 0;

        _profileCache[userId] = CachedProfile(
          userId: userId,
          isLoading: false,
          profile: profile,
          posts: postsResult,
          albumImages: albumImagesResult,
          postCount: postCount,
          postStats: postStatsResult,
          thoughtPosts: thoughtPostsResult,
          error: null,
          lastFetchTime: DateTime.now(),
        );
      } else if (profileResult['message'] == 'Profile not found') {
        _profileCache[userId] = CachedProfile(
          userId: userId,
          isLoading: false,
          profile: null,
          posts: [],
          albumImages: [],
          postCount: 0,
          postStats: [],
          thoughtPosts: [],
          error: 'Profile not found',
          lastFetchTime: DateTime.now(),
        );
      } else {
        _profileCache[userId] = CachedProfile(
          userId: userId,
          isLoading: false,
          profile: null,
          posts: [],
          albumImages: [],
          postCount: 0,
          postStats: [],
          thoughtPosts: [],
          error: 'Failed to load profile',
          lastFetchTime: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('❌ [ProfileProvider] Error loading profile: $e');
      _profileCache[userId] = CachedProfile(
        userId: userId,
        isLoading: false,
        profile: existingCache?.profile,
        posts: existingCache?.posts ?? [],
        albumImages: existingCache?.albumImages ?? [],
        postCount: existingCache?.postCount ?? 0,
        postStats: existingCache?.postStats ?? [],
        thoughtPosts: existingCache?.thoughtPosts ?? [],
        error: 'Error loading profile: $e',
        lastFetchTime: DateTime.now(),
      );
    }

    notifyListeners();
  }

  // Force refresh profile
  Future<void> refreshProfile(String userId, {BuildContext? context}) async {
    debugPrint('🔄 [ProfileProvider] Force refreshing profile for userId: $userId');
    await loadProfile(userId, forceRefresh: true, context: context);
  }

  // Invalidate specific profile cache
  void invalidateProfile(String userId) {
    debugPrint('🗑️ [ProfileProvider] Invalidating cache for userId: $userId');
    _profileCache.remove(userId);
    notifyListeners();
  }

  // Clear all cached profiles
  void clearAllCache() {
    debugPrint('🧹 [ProfileProvider] Clearing all profile cache');
    _profileCache.clear();
    notifyListeners();
  }

  // Update profile in cache (e.g., after edit)
  void updateCachedProfile(String userId, ProfileModel updatedProfile) {
    final cached = _profileCache[userId];
    if (cached != null) {
      _profileCache[userId] = CachedProfile(
        userId: userId,
        isLoading: false,
        profile: updatedProfile,
        posts: cached.posts,
        albumImages: cached.albumImages,
        postCount: cached.postCount,
        postStats: cached.postStats,
        thoughtPosts: cached.thoughtPosts,
        error: null,
        lastFetchTime: DateTime.now(),
      );
      notifyListeners();
    }
  }
}

// Cached profile data container
class CachedProfile {
  final String userId;
  final bool isLoading;
  final ProfileModel? profile;
  final List<dynamic> posts;
  final List<String> albumImages;
  final int postCount;
  final List<dynamic> postStats;
  final List<dynamic> thoughtPosts;
  final String? error;
  final DateTime lastFetchTime;

  CachedProfile({
    required this.userId,
    required this.isLoading,
    required this.profile,
    required this.posts,
    required this.albumImages,
    required this.postCount,
    required this.postStats,
    required this.thoughtPosts,
    required this.error,
    required this.lastFetchTime,
  });

  bool get isValid {
    final now = DateTime.now();
    return now.difference(lastFetchTime) < ProfileProvider._cacheDuration;
  }

  bool get hasProfile => profile != null;
  bool get isProfileNotFound => error == 'Profile not found';
  bool get hasError => error != null && error != 'Profile not found';
}
