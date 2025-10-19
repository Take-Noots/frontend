import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/models/feed_item.dart';
import '../../data/models/post_model.dart' as data_model;
import '../../data/models/thoughts_model.dart';
import '../../data/services/song_post_service.dart';
import '../../data/services/thoughts_service.dart';

class FeedProvider extends ChangeNotifier {
  final SongPostService _songPostService = SongPostService();
  final ThoughtsService _thoughtsService = ThoughtsService();

  List<FeedItem> _feedItems = [];
  bool _isLoading = false;
  bool _hasLoadedOnce =
      false; // 🔑 Global cache flag - persists across navigation
  String? _error;
  String? _userId;

  // Getters
  List<FeedItem> get feedItems => _feedItems;
  bool get isLoading => _isLoading;
  bool get hasLoadedOnce => _hasLoadedOnce;
  String? get error => _error;
  bool get hasData => _feedItems.isNotEmpty;

  /// Load feed data - uses cache if already loaded
  Future<void> loadFeed(String userId,
      {BuildContext? context, bool forceRefresh = false}) async {
    // If we've already loaded and not forcing refresh, use cached data
    if (_hasLoadedOnce && !forceRefresh && _userId == userId && hasData) {
      debugPrint('🔄 Using cached feed data (no API call)');
      return;
    }

    debugPrint('🌐 Loading fresh feed data (API call)');
    _userId = userId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch data in parallel, always pass context for authenticated requests
      final results = await Future.wait([
        _songPostService.getFollowerPosts(userId, context),
        _thoughtsService.getFollowerThoughts(userId, context),
      ]);

      final songResult = results[0];
      final thoughtsResult = results[1];
      List<FeedItem> feedItems = [];

      // Process song posts
      if (songResult['success'] == true && songResult['data'] != null) {
        final posts = (songResult['data'] as List).map((json) {
          final post = data_model.Post.fromJson(json);
          post.likedByMe =
              (json['likedBy'] as List?)?.contains(userId) ?? false;
          return FeedItem.song(post);
        }).where((item) =>
            item.songPost == null ||
            (item.songPost!.isHidden == 0 && item.songPost!.isDeleted == 0));
        feedItems.addAll(posts);
      }

      // Process thoughts
      if (thoughtsResult['success'] == true && thoughtsResult['data'] != null) {
        debugPrint(
            '🧠 Fetched thoughts data: ' + thoughtsResult['data'].toString());
        final thoughts = (thoughtsResult['data'] as List).map((json) {
          return FeedItem.thought(ThoughtsPost.fromJson(json));
        }).where((item) =>
            item.thoughtsPost == null ||
            (item.thoughtsPost!.isHidden == 0 &&
                item.thoughtsPost!.isDeleted == 0));
        feedItems.addAll(thoughts);
      }

      // Sort by creation date (newest first)
      feedItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _feedItems = feedItems;
      _isLoading = false;
      _hasLoadedOnce = true; // 🔑 Mark as loaded globally
      _error = null;

      debugPrint('✅ Feed loaded successfully: ${_feedItems.length} items');
    } catch (e) {
      debugPrint('❌ Error loading feed: $e');
      _error = 'Error loading feed: $e';
      _isLoading = false;
    }

    notifyListeners();
  }

  /// Force refresh the feed
  Future<void> refreshFeed({BuildContext? context}) async {
    if (_userId != null) {
      debugPrint('🔄 Manual refresh requested');
      await loadFeed(_userId!, context: context, forceRefresh: true);
    }
  }

  /// Invalidate cache (useful after follow/unfollow)
  void invalidateCache() {
    debugPrint('🗑️ Cache invalidated');
    _hasLoadedOnce = false;
    notifyListeners();
  }

  /// Clear all cached data
  void clearCache() {
    debugPrint('🧹 Cache cleared completely');
    _feedItems = [];
    _hasLoadedOnce = false;
    _error = null;
    notifyListeners();
  }

  /// Update a specific post in cache (e.g., after liking)
  void updatePost(String postId, FeedItem updatedItem) {
    final index = _feedItems.indexWhere((item) =>
        item.songPost?.id == postId || item.thoughtsPost?.id == postId);

    if (index != -1) {
      _feedItems[index] = updatedItem;
      notifyListeners();
    }
  }

  /// Remove a post from cache (e.g., after hiding/deleting)
  void removePost(String postId) {
    _feedItems.removeWhere((item) =>
        item.songPost?.id == postId || item.thoughtsPost?.id == postId);
    notifyListeners();
  }
}
