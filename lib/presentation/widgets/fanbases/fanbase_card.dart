// Fanbase Card Widget
import 'package:flutter/material.dart';
import 'dart:convert'; // Add for JSON decoding
import 'package:shared_preferences/shared_preferences.dart'; // Add for user data access
import 'package:Noot/data/models/fanbase_model.dart';
import 'package:Noot/data/services/fanbase_service.dart';
import './fanbase_interations.dart';
// import './fanbase_profilebar.dart';

/// Widget that displays a fanbase card with join/owned functionality
/// Shows different buttons based on whether the current user owns the fanbase
class FanbaseCard extends StatefulWidget {
  final Fanbase initialFanbase;
  final VoidCallback onJoinStateChanged;

  const FanbaseCard({
    super.key,
    required this.initialFanbase,
    required this.onJoinStateChanged,
  });

  @override
  State<FanbaseCard> createState() => _FanbaseCardState();
}

class _FanbaseCardState extends State<FanbaseCard> {
  late Fanbase _fanbase;
  bool _isJoinLoading = false;
  bool _isLikeLoading = false;
  String? _currentUserId; // Current user's ID for ownership checking

  @override
  void initState() {
    super.initState();
    _fanbase = widget.initialFanbase;
    _loadCurrentUserId(); // Load current user ID when widget initializes
    print('Initial fanbase: ${_fanbase.toJson()}');
  }

  @override
  void didUpdateWidget(covariant FanbaseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFanbase != oldWidget.initialFanbase) {
      setState(() {
        _fanbase = widget.initialFanbase;
        print('Fanbase updated: ${_fanbase.toJson()}');
      });
    }
  }

  /// Loads the current user's ID from SharedPreferences
  /// This is used to determine if the user owns the fanbase
  Future<void> _loadCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        setState(() {
          _currentUserId = userData['id'];
        });
        print('Current user ID loaded: $_currentUserId');
        print('Fanbase creator ID: ${_fanbase.createdBy.id}');
      }
    } catch (e) {
      print('Error loading current user ID: $e');
    }
  }

  /// Checks if the current user is the owner of this fanbase
  /// Compares current user ID with the fanbase creator's ID
  bool get _isOwner {
    return _currentUserId != null && _currentUserId == _fanbase.createdBy.id;
  }

  /// Truncates text to a specified length with optional ellipsis
  String truncateText(String text, int maxLength, {bool addEllipsis = true}) {
    if (text.length <= maxLength) return text;
    return addEllipsis
        ? '${text.substring(0, maxLength)}...'
        : text.substring(0, maxLength);
  }

  /// Handles toggling the join status
  /// Only works for non-owners (owners cannot join/leave their own fanbase)
  Future<void> _handleJoin() async {
    if (_isJoinLoading || _isOwner) return;

    setState(() => _isJoinLoading = true);

    try {
      final updatedFanbase =
          await FanbaseService.joinFanbase(_fanbase.id, context);

      print('Updated fanbase: ${updatedFanbase.toJson()}');

      if (mounted) {
        setState(() {
          _fanbase = updatedFanbase;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
      widget.onJoinStateChanged();
    } finally {
      if (mounted) {
        setState(() => _isJoinLoading = false);
      }
    }
  }

  /// Handles toggling the like status
  /// Both owners and non-owners can like fanbases
  Future<void> _handleLike() async {
    if (_isLikeLoading) return;

    setState(() => _isLikeLoading = true);

    try {
      final updatedFanbase =
          await FanbaseService.likeFanbase(_fanbase.id, context);

      print('Updated fanbase (like): ${updatedFanbase.toJson()}');

      if (mounted) {
        setState(() {
          _fanbase = updatedFanbase;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error liking fanbase: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLikeLoading = false);
      }
    }
  }

  /// Builds the appropriate action button based on ownership
  /// Shows "Owned" for creators, "Join"/"Joined" for others
  Widget _buildActionButton() {
    if (_isOwner) {
      // Show "Owned" button for fanbase creators
      return OutlinedButton(
        onPressed: null, // Disabled since it's owned
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.purple[50],
          foregroundColor: Colors.purple[700],
          side: BorderSide(color: Colors.purple[300]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified,
              size: 16,
              color: Colors.purple,
            ),
            // const SizedBox(width: 4),
            // const Text('Owned'),
          ],
        ),
      );
    } else {
      // Show Join/Joined button for non-owners
      return OutlinedButton(
        onPressed: _handleJoin,
        style: OutlinedButton.styleFrom(
          backgroundColor: _fanbase.isJoined ? Colors.white : Colors.purple,
          foregroundColor: _fanbase.isJoined ? Colors.purple : Colors.white,
          side: const BorderSide(color: Colors.purple),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        child: _isJoinLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _fanbase.isJoined ? Colors.purple : Colors.white,
                  ),
                ),
              )
            : Text(_fanbase.isJoined ? 'Joined' : 'Join'),
      );
    }
  }

  /// Builds the profile section with ownership indicator
  Widget _buildProfileSection() {
    return Row(
      children: [
        // Profile image
        CircleAvatar(
          backgroundImage: NetworkImage(_fanbase.fanbasePhotoUrl ?? ''),
          radius: 14.0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          onBackgroundImageError: (exception, stackTrace) {
            // Handle image loading error silently
          },
        ),
        const SizedBox(width: 12.0),

        // Fanbase name with ownership indicator
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      truncateText(_fanbase.fanbaseName, 15),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 22.0,
                      ),
                    ),
                  ),
                ],
              ),
              // "Creator" label for owned fanbases
              if (_isOwner)
                Text(
                  'Creator',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withOpacity(0.7),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/fanbase/${_fanbase.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 16.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: theme.primary,
          border: const Border(
            top: BorderSide(
              color: Colors.grey,
              width: 1.2,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Top Row: Enhanced Profile + Action Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Enhanced profile section with ownership indicators
                Expanded(child: _buildProfileSection()),

                const SizedBox(width: 8),

                // Dynamic action button (Join/Joined/Owned)
                _buildActionButton(),
              ],
            ),

            const SizedBox(height: 14.0),

            /// Topic description
            Container(
              width: double.infinity,
              child: Text(
                truncateText(_fanbase.fanbaseTopic, 55),
                style: TextStyle(
                  color: theme.onPrimary,
                  fontSize: 14.5,
                ),
              ),
            ),

            const SizedBox(height: 14.0),

            /// Interaction stats (likes, posts, etc.)
            FanbaseInterations(
              numLikes: _fanbase.numLikes,
              numPosts: _fanbase.numPosts,
              isLiked: _fanbase.isLiked,
              isLikeLoading: _isLikeLoading,
              onLikeTap: _handleLike,
            ),
          ],
        ),
      ),
    );
  }
}
