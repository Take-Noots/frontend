import 'package:flutter/material.dart';

class PostShape extends CustomPainter {
  final Color backgroundColor;

  PostShape({this.backgroundColor = const Color(0xff423E4E)});

  @override
  void paint(Canvas canvas, Size size) {
    // Configure paint with the background color provided
    Paint paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    // paint.color = const Color(0xFF423E4E);

    final w = size.width;
    final h = size.height;

    final minX = 3.0, maxX = 493.0;
    final minY = 3.0, maxY = 452.0;
    final pathW = maxX - minX;
    final pathH = maxY - minY;

    double nx(double x) => (x - minX) / pathW * w;
    double ny(double y) => (y - minY) / pathH * h;

    final path = Path()
      ..moveTo(nx(341.5), ny(57))
      ..cubicTo(nx(352.546), ny(57), nx(361.5), ny(48.0457), nx(361.5), ny(37))
      ..lineTo(nx(361.5), ny(23))
      ..cubicTo(nx(361.5), ny(11.9543), nx(370.454), ny(3), nx(381.5), ny(3))
      ..lineTo(nx(473), ny(3))
      ..cubicTo(nx(484.046), ny(3), nx(493), ny(11.9543), nx(493), ny(23))
      ..lineTo(nx(493), ny(375.5))
      ..cubicTo(nx(493), ny(386.546), nx(484.046), ny(395.5), nx(473), ny(395.5))
      ..lineTo(nx(427), ny(395.5))
      ..lineTo(nx(381.5), ny(395.5))
      ..cubicTo(nx(370.454), ny(395.5), nx(361.5), ny(404.454), nx(361.5), ny(415.5))
      ..lineTo(nx(361.5), ny(432))
      ..cubicTo(nx(361.5), ny(443.046), nx(352.546), ny(452), nx(341.5), ny(452))
      ..lineTo(nx(23), ny(452))
      ..cubicTo(nx(11.9543), ny(452), nx(3), ny(443.046), nx(3), ny(432))
      ..lineTo(nx(3), ny(247.979))
      ..lineTo(nx(3), ny(145.969))
      ..lineTo(nx(3), ny(77))
      ..cubicTo(nx(3), ny(65.9543), nx(11.9543), ny(57), nx(23), ny(57))
      ..lineTo(nx(341.5), ny(57))
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
