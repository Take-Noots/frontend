import 'package:flutter/material.dart';

/// Common loading widget for the entire app
/// Provides consistent loading indicators with purple theme
/// Supports optional back button for navigation during loading states
class CommonLoading extends StatelessWidget {
  final String? message;
  final Color? color;
  final double size;
  final bool showMessage;
  final EdgeInsetsGeometry padding;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const CommonLoading({
    Key? key,
    this.message,
    this.color,
    this.size = 40.0,
    this.showMessage = true,
    this.padding = const EdgeInsets.all(16.0),
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.showBackButton = false,
    this.onBackPressed,
  }) : super(key: key);

  /// Purple loading indicator (default app theme)
  factory CommonLoading.purple({
    String? message,
    double size = 40.0,
    bool showMessage = true,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16.0),
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.center,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    bool showBackButton = false,
    VoidCallback? onBackPressed,
  }) {
    return CommonLoading(
      message: message,
      color: const Color(0xFF8E08EF),
      size: size,
      showMessage: showMessage,
      padding: padding,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      showBackButton: showBackButton,
      onBackPressed: onBackPressed,
    );
  }

  /// White loading indicator (for dark backgrounds)
  factory CommonLoading.white({
    String? message,
    double size = 40.0,
    bool showMessage = true,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16.0),
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.center,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    bool showBackButton = false,
    VoidCallback? onBackPressed,
  }) {
    return CommonLoading(
      message: message,
      color: Colors.white,
      size: size,
      showMessage: showMessage,
      padding: padding,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      showBackButton: showBackButton,
      onBackPressed: onBackPressed,
    );
  }

  /// Black loading indicator (for light backgrounds)
  factory CommonLoading.black({
    String? message,
    double size = 40.0,
    bool showMessage = true,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16.0),
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.center,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    bool showBackButton = false,
    VoidCallback? onBackPressed,
  }) {
    return CommonLoading(
      message: message,
      color: Colors.black,
      size: size,
      showMessage: showMessage,
      padding: padding,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      showBackButton: showBackButton,
      onBackPressed: onBackPressed,
    );
  }

  /// Full screen loading overlay
  factory CommonLoading.fullScreen({
    String? message,
    Color? color,
    bool showMessage = true,
    bool showBackButton = false,
    VoidCallback? onBackPressed,
  }) {
    return CommonLoading(
      message: message,
      color: color ?? const Color(0xFF8E08EF),
      size: 50.0,
      showMessage: showMessage,
      padding: const EdgeInsets.all(24.0),
      showBackButton: showBackButton,
      onBackPressed: onBackPressed,
    );
  }

  /// Small loading indicator for inline use
  factory CommonLoading.small({
    Color? color,
    double size = 20.0,
    bool showBackButton = false,
    VoidCallback? onBackPressed,
  }) {
    return CommonLoading(
      color: color ?? const Color(0xFF8E08EF),
      size: size,
      showMessage: false,
      padding: EdgeInsets.zero,
      showBackButton: showBackButton,
      onBackPressed: onBackPressed,
    );
  }

  /// Medium loading indicator
  factory CommonLoading.medium({
    Color? color,
    double size = 30.0,
    bool showBackButton = false,
    VoidCallback? onBackPressed,
  }) {
    return CommonLoading(
      color: color ?? const Color(0xFF8E08EF),
      size: size,
      showMessage: false,
      padding: const EdgeInsets.all(8.0),
      showBackButton: showBackButton,
      onBackPressed: onBackPressed,
    );
  }

  /// Large loading indicator
  factory CommonLoading.large({
    Color? color,
    double size = 60.0,
    bool showBackButton = false,
    VoidCallback? onBackPressed,
  }) {
    return CommonLoading(
      color: color ?? const Color(0xFF8E08EF),
      size: size,
      showMessage: false,
      padding: const EdgeInsets.all(16.0),
      showBackButton: showBackButton,
      onBackPressed: onBackPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loadingColor = color ?? const Color(0xFF8E08EF);

    final loadingWidget = Padding(
      padding: padding,
      child: Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(loadingColor),
              strokeWidth: size * 0.1, // Proportional stroke width
            ),
          ),
          if (showMessage && message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );

    if (showBackButton) {
      return Stack(
        children: [
          loadingWidget,
          Positioned(
            top: 16,
            left: 16,
            child: IconButton(
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              tooltip: 'Back',
            ),
          ),
        ],
      );
    }

    return loadingWidget;
  }
}

/// Extension on BuildContext for easy loading widget access
extension LoadingExtensions on BuildContext {
  /// Show purple loading indicator
  Widget get purpleLoading => CommonLoading.purple();

  /// Show white loading indicator
  Widget get whiteLoading => CommonLoading.white();

  /// Show black loading indicator
  Widget get blackLoading => CommonLoading.black();

  /// Show small loading indicator
  Widget get smallLoading => CommonLoading.small();

  /// Show medium loading indicator
  Widget get mediumLoading => CommonLoading.medium();

  /// Show large loading indicator
  Widget get largeLoading => CommonLoading.large();
}
