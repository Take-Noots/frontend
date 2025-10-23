import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../data/services/profile_service.dart';
import '../../../data/services/request_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/providers/auth_provider.dart';
import './following_list.dart';
import '../../widgets/loading_screens/user_list_skeleton.dart';

/// Stateful wrapper for FollowingListPage that handles async loading
class FollowingListPageWrapper extends StatefulWidget {
  final String userId;
  final void Function(String userId, String? username)? onUserTap;

  const FollowingListPageWrapper({
    Key? key,
    required this.userId,
    this.onUserTap,
  }) : super(key: key);

  @override
  State<FollowingListPageWrapper> createState() =>
      _FollowingListPageWrapperState();
}

class _FollowingListPageWrapperState extends State<FollowingListPageWrapper> {
  bool _isLoading = true;
  List<dynamic> _following = [];
  String? _errorMessage;
  Set<String> _currentUserFollowing = {};
  Set<String> _loadingUserIds = {};
  Set<String> _pendingRequests =
      {}; // User IDs where a request is pending (from logged-in user)

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.user?.id;
      final profileService = ProfileService();

      // Load following
      final followingList =
          await profileService.getFollowingListWithDetails(widget.userId);

      // Load current user's following
      Set<String> currentUserFollowing = {};
      if (currentUserId != null) {
        final result = await profileService.getUserProfile(currentUserId);
        if (result['success'] == true) {
          final profile = result['data'] as Map<String, dynamic>;
          final following = profile['following'] as List<dynamic>? ?? [];
          currentUserFollowing = following.map((e) => e.toString()).toSet();
        }
      }

      // For each following user, query their incoming requests and mark pending
      // where the logged-in user is the sender and the request is still pending.
      Set<String> pendingRequests = {};
      if (currentUserId != null) {
        final List<String> userIds = [];
        final List<Future<List<Map<String, dynamic>>>> futures = [];
        for (final user in followingList) {
          final userId = (user is Map<String, dynamic>)
              ? user['userId']?.toString()
              : null;
          if (userId != null) {
            userIds.add(userId);
            futures.add(RequestService.getRequestsForUser(userId));
          }
        }
        final responses = await Future.wait(futures);
        for (var i = 0; i < responses.length; i++) {
          final reqs = responses[i];
          final targetUserId = userIds[i];
          for (final req in reqs) {
            if (req['requestSendUserId']?.toString() == currentUserId &&
                req['respond'] == 'pending') {
              pendingRequests.add(targetUserId);
              break;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _following = followingList;
          _currentUserFollowing = currentUserFollowing;
          _pendingRequests = pendingRequests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load following: [${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _reloadCurrentUserFollowing() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;
    if (currentUserId != null) {
      final profileService = ProfileService();
      final result = await profileService.getUserProfile(currentUserId);
      Set<String> currentUserFollowing = {};
      if (result['success'] == true) {
        final profile = result['data'] as Map<String, dynamic>;
        final following = profile['following'] as List<dynamic>? ?? [];
        currentUserFollowing = following.map((e) => e.toString()).toSet();
      }
      // Re-check pending requests for all following
      Set<String> pendingRequests = {};
      for (final user in _following) {
        final userId = (user is Map<String, dynamic>) ? user['userId'] : null;
        if (userId != null) {
          final userProfileResult = await profileService.getUserProfile(userId);
          if (userProfileResult['success'] == true &&
              userProfileResult['data'] != null) {
            final data = userProfileResult['data'];
            if (data['pendingRequests'] is List) {
              final pending = (data['pendingRequests'] as List)
                  .map((e) => e.toString())
                  .toList();
              if (pending.contains(currentUserId)) {
                pendingRequests.add(userId);
              }
            }
          }
        }
      }
      setState(() {
        _currentUserFollowing = currentUserFollowing;
        _pendingRequests = pendingRequests;
      });
    }
  }

  Future<void> _onFollowToggle(String targetUserId, bool isFollow) async {
    setState(() {
      _loadingUserIds.add(targetUserId);
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authProvider.user?.id;
    if (currentUserId == null) return;

    final profileService = ProfileService(authService: authService);

    // Fetch target user's profile to check if private
    final targetProfileResult =
        await profileService.getUserProfile(targetUserId);
    bool isPrivate = false;
    if (targetProfileResult['success'] == true &&
        targetProfileResult['data'] != null) {
      final data = targetProfileResult['data'] as Map<String, dynamic>;
      isPrivate = (data['userType'] ?? 'public') == 'private';
    }

    Map<String, dynamic> result;
    if (!isFollow && isPrivate && _pendingRequests.contains(targetUserId)) {
      // Cancel follow request
      result =
          await profileService.cancelFollowRequest(currentUserId, targetUserId);
    } else if (isFollow &&
        isPrivate &&
        !_currentUserFollowing.contains(targetUserId) &&
        !_pendingRequests.contains(targetUserId)) {
      // Send follow request
      result =
          await profileService.sendFollowRequest(currentUserId, targetUserId);
    } else {
      // Regular follow/unfollow
      result = isFollow
          ? await profileService.followUser(currentUserId, targetUserId)
          : await profileService.unfollowUser(currentUserId, targetUserId);
    }

    // After any action, update state optimistically if successful
    if (mounted) {
      if (result['success'] == true) {
        setState(() {
          if (!isFollow &&
              isPrivate &&
              _pendingRequests.contains(targetUserId)) {
            // Cancel follow request succeeded
            _pendingRequests.remove(targetUserId);
          } else if (isFollow &&
              isPrivate &&
              !_currentUserFollowing.contains(targetUserId) &&
              !_pendingRequests.contains(targetUserId)) {
            // Send follow request succeeded
            _pendingRequests.add(targetUserId);
          } else if (isFollow) {
            // Follow succeeded
            _currentUserFollowing.add(targetUserId);
            _pendingRequests.remove(targetUserId); // Clear any pending
          } else if (!isFollow) {
            // Unfollow succeeded
            _currentUserFollowing.remove(targetUserId);
            // Ensure any pending request flags are cleared and refresh current user's following
            _pendingRequests.remove(targetUserId);
            Future.microtask(() => _reloadCurrentUserFollowing());
          }
          _loadingUserIds.remove(targetUserId);
        });
      } else {
        setState(() {
          _loadingUserIds.remove(targetUserId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ??
                'Failed to ${isFollow ? 'follow' : 'unfollow'} user'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const UserListSkeleton(title: 'Following');
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Following'),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadFollowing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8E08EF),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return FollowingListPage(
      following: _following,
      onUserTap: widget.onUserTap,
      currentUserFollowing: _currentUserFollowing,
      onFollowToggle: _onFollowToggle,
      loadingUserIds: _loadingUserIds,
      pendingRequests: _pendingRequests,
    );
  }
}
