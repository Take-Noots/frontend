import 'package:flutter/material.dart';
import 'profile_grid_skeleton.dart';

class ProfileLoadingScreen extends StatefulWidget {
  final String? title;
  final String? subtitle;
  final bool showAppBar;
  final VoidCallback? onBackPressed;
  final bool isError;
  final VoidCallback? onRetry;
  final bool showSkeleton;
  final bool isMyProfile;

  const ProfileLoadingScreen({
    Key? key,
    this.title,
    this.subtitle,
    this.showAppBar = true,
    this.onBackPressed,
    this.isError = false,
    this.onRetry,
    this.showSkeleton = false,
    this.isMyProfile = false,
  }) : super(key: key);

  @override
  State<ProfileLoadingScreen> createState() => _ProfileLoadingScreenState();
}

class _ProfileLoadingScreenState extends State<ProfileLoadingScreen>
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
    if (widget.showSkeleton) {
      return _buildSkeletonLoading(context);
    }

    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title:
              Text(widget.title ?? (widget.isError ? 'Error' : 'Loading...')),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
              Theme.of(context).scaffoldBackgroundColor,
          centerTitle: true,
          leading: widget.onBackPressed != null
              ? IconButton(
                  icon: Icon(Icons.arrow_back,
                      color: Theme.of(context).colorScheme.onSurface),
                  onPressed: widget.onBackPressed,
                )
              : null,
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isError) ...[
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.subtitle ?? 'Failed to load profile',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.onRetry != null) ...[
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: widget.onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF8E08EF),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ] else ...[
                CircularProgressIndicator(
                  color: Color(0xFF8E08EF),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    widget.subtitle!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.isError) ...[
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                widget.subtitle ?? 'Failed to load profile',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.onRetry != null) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: widget.onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF8E08EF),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ] else ...[
              CircularProgressIndicator(
                color: Color(0xFF8E08EF),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 16),
                Text(
                  widget.subtitle!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(widget.title ?? 'Loading...'),
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
                  Theme.of(context).scaffoldBackgroundColor,
              centerTitle: true,
              leading: widget.onBackPressed != null
                  ? IconButton(
                      icon: Icon(Icons.arrow_back,
                          color: Theme.of(context).colorScheme.onSurface),
                      onPressed: widget.onBackPressed,
                    )
                  : null,
            )
          : null,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final Color skeletonColor = skeletonBaseColor
              .withOpacity(_animation.value * skeletonOpacityFactor);
          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header Section (matching AlbumArtPostsTab when showGrid=false)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 24.0, horizontal: 16.0),
                  child: Row(
                    children: [
                      // Profile picture skeleton (CircleAvatar radius 44 = 88 width/height)
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: skeletonColor,
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(
                            3,
                            (index) => Column(
                              children: [
                                // Stat number skeleton
                                Container(
                                  width: 40,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: skeletonColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Stat label skeleton
                                Container(
                                  width: 50,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: skeletonColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Name and Bio Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name skeleton
                        Container(
                          width: 200,
                          height: 18,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: skeletonColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Bio skeleton
                        Container(
                          width: 280,
                          height: 15,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: skeletonColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Follow/Message buttons skeleton
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: widget.isMyProfile
                      ? Center(
                          child: Container(
                            width: 80,
                            height: 36,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: skeletonColor,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 36,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: skeletonColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              width: 80,
                              height: 36,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: skeletonColor,
                              ),
                            ),
                          ],
                        ),
                ),
                // Tab bar skeleton
                Container(
                  color: Theme.of(context).colorScheme.surface,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      3,
                      (index) => Container(
                        width: 60,
                        height: 40,
                        decoration: BoxDecoration(
                          color: skeletonColor,
                        ),
                      ),
                    ),
                  ),
                ),
                // Content area skeleton (Grid view matching AlbumArtPostsTab)
                const ProfileGridSkeleton(),
              ],
            ),
          );
        },
      ),
    );
  }
}
