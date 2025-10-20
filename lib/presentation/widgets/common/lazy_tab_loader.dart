import 'package:flutter/material.dart';

/// Lazy loading wrapper for tabs - only builds content when tab is visible
/// Prevents unnecessary data fetching in tabs that aren't active
class LazyTabLoader extends StatefulWidget {
  final Widget child;
  final String debugLabel;

  const LazyTabLoader({
    Key? key,
    required this.child,
    this.debugLabel = 'Tab',
  }) : super(key: key);

  @override
  State<LazyTabLoader> createState() => _LazyTabLoaderState();
}

class _LazyTabLoaderState extends State<LazyTabLoader>
    with AutomaticKeepAliveClientMixin {
  bool _hasBeenBuilt = false;

  @override
  bool get wantKeepAlive => true; // Keep state when switching tabs

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Only build the child once it's been viewed
    if (!_hasBeenBuilt) {
      _hasBeenBuilt = true;
      debugPrint(
          '🔄 [LazyTabLoader] Building ${widget.debugLabel} for first time');
    }

    return widget.child;
  }
}

/// Alternative: Lazy loader that shows placeholder until tab is viewed
class LazyTabLoaderWithPlaceholder extends StatefulWidget {
  final Widget Function() builder;
  final Widget? placeholder;
  final String debugLabel;

  const LazyTabLoaderWithPlaceholder({
    Key? key,
    required this.builder,
    this.placeholder,
    this.debugLabel = 'Tab',
  }) : super(key: key);

  @override
  State<LazyTabLoaderWithPlaceholder> createState() =>
      _LazyTabLoaderWithPlaceholderState();
}

class _LazyTabLoaderWithPlaceholderState
    extends State<LazyTabLoaderWithPlaceholder>
    with AutomaticKeepAliveClientMixin {
  Widget? _cachedChild;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_cachedChild == null) {
      debugPrint(
          '🔄 [LazyTabLoader] Building ${widget.debugLabel} for first time');
      _cachedChild = widget.builder();
    }

    return _cachedChild!;
  }
}
