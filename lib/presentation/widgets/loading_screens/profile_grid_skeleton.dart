import 'package:flutter/material.dart';

class ProfileGridSkeleton extends StatefulWidget {
  const ProfileGridSkeleton({Key? key}) : super(key: key);

  @override
  State<ProfileGridSkeleton> createState() => _ProfileGridSkeletonState();
}

class _ProfileGridSkeletonState extends State<ProfileGridSkeleton>
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final Color skeletonColor = skeletonBaseColor
            .withOpacity(_animation.value * skeletonOpacityFactor);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 9, // 3x3 grid like the actual grid
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: skeletonColor,
              ),
            );
          },
        );
      },
    );
  }
}
