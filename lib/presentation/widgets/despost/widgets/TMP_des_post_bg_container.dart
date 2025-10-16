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
    double origW = 471;
    double origH = 222;
    double scaleX = w / origW;
    double scaleY = h / origH;

    path.moveTo(345.653 * scaleX, 50.3865 * scaleY);
    path.cubicTo(351.176 * scaleX, 50.3865 * scaleY, 355.653 * scaleX,
        45.9094 * scaleY, 355.653 * scaleX, 40.3865 * scaleY);
    path.lineTo(355.653 * scaleX, 20 * scaleY);
    path.cubicTo(355.653 * scaleX, 8.95432 * scaleY, 364.607 * scaleX, 0,
        375.653 * scaleX, 0);
    path.lineTo(451 * scaleX, 0);
    path.cubicTo(462.046 * scaleX, 0, 471 * scaleX, 8.95431 * scaleY,
        471 * scaleX, 20 * scaleY);
    path.lineTo(471 * scaleX, 162.589 * scaleY);
    path.cubicTo(471 * scaleX, 173.634 * scaleY, 462.046 * scaleX,
        182.589 * scaleY, 451 * scaleX, 182.589 * scaleY);
    path.lineTo(365.653 * scaleX, 182.589 * scaleY);
    path.cubicTo(360.13 * scaleX, 182.589 * scaleY, 355.653 * scaleX,
        187.066 * scaleY, 355.653 * scaleX, 192.589 * scaleY);
    path.lineTo(355.653 * scaleX, 212 * scaleY);
    path.cubicTo(355.653 * scaleX, 217.523 * scaleY, 351.176 * scaleX,
        222 * scaleY, 345.653 * scaleX, 222 * scaleY);
    path.lineTo(20 * scaleX, 222 * scaleY);
    path.cubicTo(
        8.95429 * scaleX, 222 * scaleY, 0, 213.046 * scaleY, 0, 202 * scaleY);
    path.lineTo(0, 70.3865 * scaleY);
    path.cubicTo(0, 59.3408 * scaleY, 8.9543 * scaleX, 50.3865 * scaleY,
        20 * scaleX, 50.3865 * scaleY);
    path.lineTo(345.653 * scaleX, 50.3865 * scaleY);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant PostShape oldDelegate) {
    // Repaint if the background color changes
    return backgroundColor != oldDelegate.backgroundColor;
  }
}