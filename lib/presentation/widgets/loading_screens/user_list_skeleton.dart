import 'package:flutter/material.dart';

/// Skeleton loading screen for user lists (followers/following)
class UserListSkeleton extends StatefulWidget {
  final String title;
  final int itemCount;

  const UserListSkeleton({
    Key? key,
    required this.title,
    this.itemCount = 10,
  }) : super(key: key);

  @override
  State<UserListSkeleton> createState() => _UserListSkeletonState();
}

class _UserListSkeletonState extends State<UserListSkeleton>
    with SingleTickerProviderStateMixin {
  static const Color skeletonBaseColor = Color(0xFF8E08EF);
  static const double skeletonOpacityFactor = 0.2;

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.7, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final Color skeletonColor = skeletonBaseColor
              .withOpacity(_animation.value * skeletonOpacityFactor);

          return ListView.builder(
            itemCount: widget.itemCount,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    // Avatar skeleton
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: skeletonColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // User info skeleton
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Username skeleton
                          Container(
                            width: double.infinity,
                            height: 16,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: skeletonColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Full name skeleton
                          Container(
                            width: 150,
                            height: 12,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: skeletonColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
