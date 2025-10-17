import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/router/route_names.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/services/profile_service.dart';

class BottomBar extends StatefulWidget {
  /// The currently selected index for highlighting the active tab
  final int currentIndex;

  /// Callback when a tab is tapped
  final Function(int)? onTap;

  /// Whether to hide the bottom bar
  final bool isHidden;

  const BottomBar({
    super.key,
    this.currentIndex = 0,
    this.onTap,
    this.isHidden = false,
  });

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  String? userId;
  String? profileImageUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initUserIdAndFetchProfile();
  }

  Future<void> _initUserIdAndFetchProfile() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      String? id = authProvider.user?.id;

      // If ID is null, try to get it from SharedPreferences directly
      if (id == null) {
        final prefs = await SharedPreferences.getInstance();
        final userDataString = prefs.getString('user_data');

        if (userDataString != null) {
          final userData = jsonDecode(userDataString);
          id = userData['id'] as String?;
        }
      }

      if (id != null) {
        final profileService = ProfileService();
        final profileResult = await profileService.getUserProfile(id);

        if (profileResult['success'] == true && profileResult['data'] != null) {
          final profileData = profileResult['data'];
          if (mounted) {
            setState(() {
              userId = id;
              profileImageUrl = profileData['profileImage'] as String?;
              isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              userId = id;
              isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching profile in BottomBar: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Return empty container if hidden
    if (widget.isHidden) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Home
          IconButton(
            icon: Icon(
              LucideIcons.home,
              size: 22,
              color: widget.currentIndex == 0
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).iconTheme.color,
            ),
            onPressed: () {
              if (widget.onTap != null) {
                widget.onTap!(0);
              } else {
                context.go(AppRoutes.home);
              }
            },
          ),

          // Search
          IconButton(
            icon: Icon(
              LucideIcons.search,
              size: 22,
              color: widget.currentIndex == 1
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).iconTheme.color,
            ),
            onPressed: () {
              if (widget.onTap != null) {
                widget.onTap!(1);
              } else {
                context.go(AppRoutes.search);
              }
            },
          ),

          // Create (e.g., Add or Post)
          IconButton(
            icon: Icon(
              LucideIcons.plusCircle,
              size: 22,
              color: widget.currentIndex == 2
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).iconTheme.color,
            ),
            onPressed: () {
              if (widget.onTap != null) {
                widget.onTap!(2);
              } else {
                // Navigate to create noot page
                context.go(AppRoutes.createNoot);
              }
            },
          ),
          // Fanbase (e.g., Group of people)
          IconButton(
            icon: Icon(
              LucideIcons.users,
              size: 22,
              color: widget.currentIndex == 3
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).iconTheme.color,
            ),
            onPressed: () {
              if (widget.onTap != null) {
                widget.onTap!(3);
              } else {
                context.go(AppRoutes.fanbaseList);
              }
            },
          ),

          // Profile
          GestureDetector(
            onTap: () {
              if (widget.onTap != null) {
                widget.onTap!(4);
              } else {
                context.go(AppRoutes.profile);
              }
            },
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundImage:
                      profileImageUrl != null && profileImageUrl!.isNotEmpty
                          ? NetworkImage(profileImageUrl!)
                          : const AssetImage('assets/images/hehe.png')
                              as ImageProvider,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
