import 'package:flutter/material.dart';

/// CustomPainter that draws vertical connecting lines between threaded replies
/// Creates a visual thread connection similar to Reddit or Twitter replies
class CommentThreadPainter extends CustomPainter {
  final bool drawTop;
  final bool drawBottom;
  final Color lineColor;
  final double strokeWidth;

  CommentThreadPainter({
    this.drawTop = false,
    this.drawBottom = false,
    this.lineColor = const Color(0xFF616161), // Grey[700]
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final centerX = 12.0; // Horizontal position of the vertical line
    final midY = size.height / 2;

    // Draw vertical line from top to middle (connects to previous reply)
    if (drawTop) {
      canvas.drawLine(
        Offset(centerX, 0),
        Offset(centerX, midY),
        paint,
      );
    }

    // Draw vertical line from middle to bottom (connects to next reply)
    if (drawBottom) {
      canvas.drawLine(
        Offset(centerX, midY),
        Offset(centerX, size.height),
        paint,
      );
    }

    // Draw horizontal connector line from vertical line to comment card
    canvas.drawLine(
      Offset(centerX, midY),
      Offset(centerX + 16, midY), // Extends 16px to the right
      paint,
    );
  }

  @override
  bool shouldRepaint(CommentThreadPainter oldDelegate) {
    return oldDelegate.drawTop != drawTop ||
        oldDelegate.drawBottom != drawBottom ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
