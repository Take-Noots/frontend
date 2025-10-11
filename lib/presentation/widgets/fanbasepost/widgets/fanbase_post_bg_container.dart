import 'package:flutter/material.dart';

/// Custom painter that creates a post background shape with margin support
/// Draws a rounded rectangle shape with custom styling
class PostShape extends CustomPainter {
  final Color backgroundColor;
  final double margin;
  final double cornerRadius;
  final double widthScale;
  final double heightScale;

  const PostShape({
    this.backgroundColor = const Color(0xff423E4E),
    this.margin = 20.0,
    this.cornerRadius = 40.0,
    this.widthScale = 1.09,
    this.heightScale = 0.90,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final path = Path();

    // Make margin and corner radius relative to available size so the
    // shape looks consistent across screen sizes.
    final double relativeMargin = (margin <= 0)
        ? (size.height * 0.08)
        : margin.clamp(4.0, size.height * 0.25);
    // widthScale and heightScale remain as stylistic overrides
    double w = (size.width * widthScale).clamp(0, double.infinity);
    double h = ((size.height - (relativeMargin * 2)) * heightScale)
        .clamp(0, double.infinity);

    double offsetX = (size.width - w) / 2; // keep centered horizontally
    double offsetY = relativeMargin;

    // Base original SVG or reference dimensions
    const double origW = 492;
    const double origH = 172;

    double scaleX = w / origW;
    double scaleY = h / origH;

    // Scale corner radius relative to the smallest scale to keep consistent rounding
    final double effectiveCorner =
        (cornerRadius * (scaleX < scaleY ? scaleX : scaleY)).clamp(2.0, 40.0);

    final r = effectiveCorner;

    // Path definition (preserves your original design)
    path.moveTo((307.5 * scaleX) + offsetX, (1 * scaleY) + offsetY);
    path.lineTo((471 * scaleX) + offsetX - r, (1 * scaleY) + offsetY);

    // Top-right curve
    path.quadraticBezierTo(
      (471 * scaleX) + offsetX,
      (1 * scaleY) + offsetY,
      (471 * scaleX) + offsetX,
      (1 * scaleY) + offsetY + r,
    );

    path.lineTo((471 * scaleX) + offsetX, (151 * scaleY) + offsetY - r);

    // Bottom-right curve
    path.quadraticBezierTo(
      (471 * scaleX) + offsetX,
      (151 * scaleY) + offsetY,
      (471 * scaleX) + offsetX - r,
      (151 * scaleY) + offsetY,
    );

    path.lineTo((21 * scaleX) + offsetX + r, (151 * scaleY) + offsetY);

    // Bottom-left curve
    path.quadraticBezierTo(
      (21 * scaleX) + offsetX,
      (151 * scaleY) + offsetY,
      (21 * scaleX) + offsetX,
      (151 * scaleY) + offsetY - r,
    );

    path.lineTo((21 * scaleX) + offsetX, (1 * scaleY) + offsetY + r);

    // Top-left curve
    path.quadraticBezierTo(
      (21 * scaleX) + offsetX,
      (1 * scaleY) + offsetY,
      (21 * scaleX) + offsetX + r,
      (1 * scaleY) + offsetY,
    );

    path.lineTo((307.5 * scaleX) + offsetX, (1 * scaleY) + offsetY);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant PostShape oldDelegate) {
    return backgroundColor != oldDelegate.backgroundColor ||
        margin != oldDelegate.margin ||
        cornerRadius != oldDelegate.cornerRadius ||
        widthScale != oldDelegate.widthScale ||
        heightScale != oldDelegate.heightScale;
  }
}

// class PostShape extends CustomPainter {
//   final Color backgroundColor;
//   final double margin;

//   PostShape({
//     this.backgroundColor = const Color(0xff423E4E),
//     this.margin = 70.0, // Default margin set to 20.0px
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     Paint paint = Paint()
//       ..color = backgroundColor
//       ..style = PaintingStyle.fill;

//     Path path = Path();

//     // Apply margin to reduce the drawable area
//     double w = size.width; // Subtract margin from both sides
//     double h =
//         size.height - (margin * 2); // Subtract margin from top and bottom

//     // Offset starting position by margin
//     double offsetX = 0;
//     double offsetY = margin;

//     // The original SVG's width and height
//     double origW = 492;
//     double origH = 172;

//     double scaleX = w / origW;
//     double scaleY = h / origH;

//     // Apply margin offset to all coordinates
//     path.moveTo((307.5 * scaleX) + offsetX, (1 * scaleY) + offsetY);
//     path.lineTo((367.5 * scaleX) + offsetX, (1 * scaleY) + offsetY);
//     path.lineTo((471 * scaleX) + offsetX, (1 * scaleY) + offsetY);
//     path.cubicTo(
//         (482.046 * scaleX) + offsetX,
//         (1 * scaleY) + offsetY,
//         (491 * scaleX) + offsetX,
//         (9.95431 * scaleY) + offsetY,
//         (491 * scaleX) + offsetX,
//         (21 * scaleY) + offsetY);
//     path.lineTo((491 * scaleX) + offsetX, (131 * scaleY) + offsetY);
//     path.cubicTo(
//         (491 * scaleX) + offsetX,
//         (142.046 * scaleY) + offsetY,
//         (482.046 * scaleX) + offsetX,
//         (151 * scaleY) + offsetY,
//         (471 * scaleX) + offsetX,
//         (151 * scaleY) + offsetY);
//     path.lineTo((385 * scaleX) + offsetX, (151 * scaleY) + offsetY);
//     path.lineTo((337.5 * scaleX) + offsetX, (151 * scaleY) + offsetY);
//     path.lineTo((21 * scaleX) + offsetX, (151 * scaleY) + offsetY);
//     path.cubicTo(
//         (9.95431 * scaleX) + offsetX,
//         (151 * scaleY) + offsetY,
//         (1 * scaleX) + offsetX,
//         (142.046 * scaleY) + offsetY,
//         (1 * scaleX) + offsetX,
//         (131 * scaleY) + offsetY);
//     path.lineTo((1 * scaleX) + offsetX, (89.969 * scaleY) + offsetY);
//     path.lineTo((1 * scaleX) + offsetX, (21 * scaleY) + offsetY);
//     path.cubicTo(
//         (1 * scaleX) + offsetX,
//         (9.95431 * scaleY) + offsetY,
//         (9.95431 * scaleX) + offsetX,
//         (1 * scaleY) + offsetY,
//         (21 * scaleX) + offsetX,
//         (1 * scaleY) + offsetY);
//     path.lineTo((307.5 * scaleX) + offsetX, (1 * scaleY) + offsetY);
//     path.close();

//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(covariant PostShape oldDelegate) {
//     // Repaint if the background color or margin changes
//     return backgroundColor != oldDelegate.backgroundColor ||
//         margin != oldDelegate.margin;
//   }
// }
