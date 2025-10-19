import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../toggle_button.dart';
import '../../../data/services/notification_service.dart';
import '../../../core/router/route_names.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/router/route_names.dart';

class NootAppBar extends StatefulWidget implements PreferredSizeWidget {
  const NootAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  State<NootAppBar> createState() => _NootAppBarState();
}

class _NootAppBarState extends State<NootAppBar> {
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final result = await _notificationService.getUnreadCount();
      if (result['success'] && mounted) {
        setState(() {
          _unreadCount = result['data']['count'] ?? 0;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).colorScheme.primary,
      elevation: 0,
      titleSpacing: 0,
      title: Row(
        children: [
          // App Icon and Name
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 8.0),
            child: Row(
              children: [
                Image.asset(
                  isDark ? 'assets/images/logo.png' : 'assets/images/logo.png',
                  width: 100,
                  height: 40,
                ),
              ],
            ),
          ),
          const Spacer(),
          // temparary toggle button
          const ToggleButton(),
          // Notification Icon with badge
          Stack(
            children: [
              IconButton(
                icon: Icon(LucideIcons.heart,
                    color: Theme.of(context).colorScheme.onPrimary, size: 22),
                onPressed: () async {
                  await context.push(AppRoutes.notifications);
                  // Refresh unread count when returning from notifications
                  _loadUnreadCount();
                },
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Message Icon - Updated this section
          IconButton(
            icon: Icon(LucideIcons.messagesSquare,
                color: Theme.of(context).colorScheme.onPrimary, size: 22),
            onPressed: () {
              context.push(AppRoutes.chat);
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}
