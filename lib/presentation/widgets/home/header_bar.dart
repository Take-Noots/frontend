import 'package:flutter/material.dart';
import '../../screens/chat/chat_list_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';

class NootAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NootAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

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
          IconButton(
            icon: Icon(LucideIcons.heart,
                color: Theme.of(context).colorScheme.onPrimary, size: 22),
            onPressed: () {
              Navigator.pushNamed(context, '/request');
            },
          ),
          // Message Icon - Updated this section
          IconButton(
            icon: Icon(LucideIcons.messagesSquare,
                color: Theme.of(context).colorScheme.onPrimary, size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatListScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}
