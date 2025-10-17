import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/profile_service.dart';
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

      // Load current user's following if logged in
      Set<String> currentUserFollowing = {};
      if (currentUserId != null) {
        final result = await profileService.getUserProfile(currentUserId);
        if (result['success'] == true) {
          final profile = result['data'] as Map<String, dynamic>;
          final following = profile['following'] as List<dynamic>? ?? [];
          currentUserFollowing = following.map((e) => e.toString()).toSet();
        }
      }

      if (mounted) {
        setState(() {
          _following = followingList;
          _currentUserFollowing = currentUserFollowing;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load following: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onFollowToggle(String targetUserId, bool isFollow) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authProvider.user?.id;
    if (currentUserId == null) return;

    final profileService = ProfileService(authService: authService);
    final result = isFollow
        ? await profileService.followUser(currentUserId, targetUserId)
        : await profileService.unfollowUser(currentUserId, targetUserId);

    if (result['success'] == true) {
      setState(() {
        if (isFollow) {
          _currentUserFollowing.add(targetUserId);
        } else {
          _currentUserFollowing.remove(targetUserId);
        }
      });
    } else {
      // Show error
      if (mounted) {
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
    );
  }
}
