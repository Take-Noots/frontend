import 'package:flutter/material.dart';
import '../../../data/services/user_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String username;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isLoading = true;
  bool _isFollowLoading = false;
  String? _error;
  Map<String, dynamic>? userProfile;
  String? currentUserId;
  bool isFollowing = false;
  bool isSelf = false;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _initializeProfile();
  }

  Future<void> _initializeProfile() async {
    await _loadCurrentUser();
    await _loadUserProfile();
    if (!isSelf) {
      await _checkFollowStatus();
    }
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      final userData = jsonDecode(userDataString);
      setState(() {
        currentUserId = userData['id'];
        isSelf = currentUserId == widget.userId;
      });
    }
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _error = null;
    });

    try {
      print('Loading profile for userId: ${widget.userId}');
      // Fetch basic profile data and followers/following counts in parallel
      final results = await Future.wait([
        _userService.getUserProfile(widget.userId),
        _userService.getFollowersCount(widget.userId),
        _userService.getFollowingCount(widget.userId),
      ]);

      final profileResult = results[0] as Map<String, dynamic>;
      final followersResult = results[1] as Map<String, dynamic>;
      final followingResult = results[2] as Map<String, dynamic>;

      print('Profile result: $profileResult');
      print('Followers result: $followersResult');
      print('Following result: $followingResult');

      if (profileResult['success']) {
        final profile = profileResult['data'];
        final followersCount = followersResult['success'] ? followersResult['count'] : 0;
        final followingCount = followingResult['success'] ? followingResult['count'] : 0;

        setState(() {
          userProfile = {
            'id': profile['_id'] ?? profile['userId'],
            'username': profile['username'] ?? widget.username,
            'email': profile['email'] ?? '',
            'fullName': profile['fullName'] ?? '',
            'profileImage': profile['profileImage'],
            'bio': profile['bio'] ?? 'No bio available',
            'joinDate': DateTime.now().subtract(const Duration(days: 30)), // Default
            'isOnline': false, // We don't have online status yet
            'lastSeen': 'Recently',
            'followers': followersCount,
            'following': followingCount,
            'posts': (profile['posts'] is List) ? profile['posts'].length : 0,
          };
          _isLoading = false;
        });
      } else {
        // Fallback data if profile fetch fails
        setState(() {
          userProfile = {
            'id': widget.userId,
            'username': widget.username,
            'email': '',
            'fullName': '',
            'profileImage': null,
            'bio': 'No bio available',
            'joinDate': DateTime.now().subtract(const Duration(days: 30)),
            'isOnline': false,
            'lastSeen': 'Recently',
            'followers': 0,
            'following': 0,
            'posts': 0,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkFollowStatus() async {
    if (currentUserId == null) return;

    final result = await _userService.checkFollowStatus(currentUserId!, widget.userId);
    if (result['success']) {
      setState(() {
        isFollowing = result['isFollowing'];
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (currentUserId == null || _isFollowLoading) return;

    setState(() {
      _isFollowLoading = true;
    });

    try {
      Map<String, dynamic> result;

      if (isFollowing) {
        result = await _userService.unfollowUser(currentUserId!, widget.userId);
      } else {
        result = await _userService.followUser(currentUserId!, widget.userId);
      }

      if (result['success']) {
        // Refresh followers count from server
        final followersResult = await _userService.getFollowersCount(widget.userId);
        final newFollowersCount = followersResult['success'] ? followersResult['count'] : 0;

        setState(() {
          isFollowing = !isFollowing;
          // Update follower count with actual count from server
          if (userProfile != null) {
            userProfile!['followers'] = newFollowersCount;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isFollowing ? 'Following ${widget.username}' : 'Unfollowed ${widget.username}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Action failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error occurred'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isFollowLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isSelf ? 'You' : (userProfile?['fullName']?.isNotEmpty == true
              ? userProfile!['fullName']
              : widget.username),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!isSelf)
            IconButton(
              icon: Icon(
                Icons.more_vert,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () {
                _showOptionsMenu();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          color: Theme.of(context).colorScheme.onPrimary, size: 48),
                      const SizedBox(height: 16),
                      Text(_error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _loadUserProfile(),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : userProfile == null
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundImage: userProfile!['profileImage'] != null
                                  ? (userProfile!['profileImage'].startsWith('http')
                                      ? NetworkImage(userProfile!['profileImage']) as ImageProvider
                                      : AssetImage(userProfile!['profileImage']))
                                  : const AssetImage('assets/images/hehe.png'),
                            ),
                            if (userProfile!['isOnline'])
                              Positioned(
                                right: 5,
                                bottom: 5,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 3,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isSelf ? 'You' : (userProfile!['fullName']?.isNotEmpty == true
                              ? userProfile!['fullName']
                              : userProfile!['username']),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!isSelf && userProfile!['fullName']?.isNotEmpty == true)
                          Text(
                            '@${userProfile!['username']}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 16,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          userProfile!['isOnline'] ? 'Online' : userProfile!['lastSeen'],
                          style: TextStyle(
                            color: userProfile!['isOnline'] ? Colors.green : Theme.of(context).colorScheme.secondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (userProfile!['bio'] != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            userProfile!['bio'],
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          'Joined ${_formatJoinDate(userProfile!['joinDate'])}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Stats Row
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem('Posts', userProfile!['posts'].toString()),
                        Container(
                          height: 40,
                          width: 1,
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                        ),
                        _buildStatItem('Followers', userProfile!['followers'].toString()),
                        Container(
                          height: 40,
                          width: 1,
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                        ),
                        _buildStatItem('Following', userProfile!['following'].toString()),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons
                  if (!isSelf)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Message feature will open chat'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.message, size: 18),
                                SizedBox(width: 8),
                                Text('Message', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _isFollowLoading
                              ? ElevatedButton(
                                  onPressed: null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : OutlinedButton(
                                  onPressed: _toggleFollow,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isFollowing
                                        ? Colors.green
                                        : Theme.of(context).colorScheme.onPrimary,
                                    side: BorderSide(
                                        color: isFollowing
                                            ? Colors.green
                                            : Theme.of(context).colorScheme.onPrimary),
                                    backgroundColor: isFollowing
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isFollowing ? Icons.person_remove : Icons.person_add,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isFollowing ? 'Following' : 'Follow',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'This is your profile',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                ],
              ),
            ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }


  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.primary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionItem(
              icon: Icons.block,
              title: 'Block User',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _showBlockDialog();
              },
            ),
            const SizedBox(height: 8),
            _buildOptionItem(
              icon: Icons.report,
              title: 'Report User',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                _showReportDialog();
              },
            ),
            const SizedBox(height: 8),
            _buildOptionItem(
              icon: Icons.share,
              title: 'Share Profile',
              color: Theme.of(context).colorScheme.onPrimary,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Share feature coming soon!'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          'Block User',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        content: Text(
          'Are you sure you want to block ${widget.username}? You won\'t see their posts or receive messages from them.',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Block feature coming soon!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text(
              'Block',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          'Report User',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        content: Text(
          'Why are you reporting ${widget.username}?',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report feature coming soon!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text(
              'Report',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  String _formatJoinDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months} month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years} year${years > 1 ? 's' : ''} ago';
    }
  }
}