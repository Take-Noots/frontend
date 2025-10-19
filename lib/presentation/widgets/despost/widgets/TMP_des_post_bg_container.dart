import 'package:flutter/material.dart';

class PostShape extends CustomPainter {
  final Color backgroundColor;

  PostShape({this.backgroundColor = const Color(0xff423E4E)});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    Path path = Path();

    // New shape based on provided SVG path, scaled to widget size
    double w = size.width;
    double h = size.height;
    // The original SVG's width and height
    double origW = 372;
    double origH = 228;
    double scaleX = w / origW;
    double scaleY = h / origH;

    path.moveTo(0, 61 * scaleY);
    path.cubicTo(0, 49.9543 * scaleY, 8.95431 * scaleX, 41 * scaleY,
        20 * scaleX, 41 * scaleY);
    path.lineTo(270.384 * scaleX, 41 * scaleY);
    path.cubicTo(275.907 * scaleX, 41 * scaleY, 280.384 * scaleX,
        36.5228 * scaleY, 280.384 * scaleX, 31 * scaleY);
    path.lineTo(280.384 * scaleX, 20 * scaleY);
    path.cubicTo(280.384 * scaleX, 8.95431 * scaleY, 289.339 * scaleX,
        0, 300.384 * scaleX, 0);
    path.lineTo(352 * scaleX, 0);
    path.cubicTo(363.046 * scaleX, 0, 372 * scaleX,
        8.9543 * scaleY, 372 * scaleX, 20 * scaleY);
    path.lineTo(372 * scaleX, 23 * scaleY);
    path.lineTo(372 * scaleX, 167.5 * scaleY);
    path.cubicTo(372 * scaleX, 178.546 * scaleY, 363.046 * scaleX,
        187.5 * scaleY, 352 * scaleX, 187.5 * scaleY);
    path.lineTo(292.398 * scaleX, 187.5 * scaleY);
    path.cubicTo(286.875 * scaleX, 187.5 * scaleY, 282.398 * scaleX,
        191.977 * scaleY, 282.398 * scaleX, 197.5 * scaleY);
    path.lineTo(282.398 * scaleX, 218 * scaleY);
    path.cubicTo(282.398 * scaleX, 223.523 * scaleY, 277.921 * scaleX,
        228 * scaleY, 272.398 * scaleX, 228 * scaleY);
    path.lineTo(10 * scaleX, 228 * scaleY);
    path.cubicTo(4.47716 * scaleX, 228 * scaleY, 0, 223.523 * scaleY,
        0, 218 * scaleY);
    path.lineTo(0, 61 * scaleY);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant PostShape oldDelegate) {
    // Repaint if the background color changes
    return backgroundColor != oldDelegate.backgroundColor;
  }
}