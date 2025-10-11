// lib/utils/size_config.dart
import 'package:flutter/widgets.dart';

class SizeConfig {
  // Design width chosen from your Figma/Sketch (e.g. 375 or 412)
  static double _designWidth = 375;
  static double _designHeight = 812;

  static late double screenWidth;
  static late double screenHeight;
  static late double scaleWidth;
  static late double scaleHeight;
  static late double textScale;

  static void init(BuildContext context,
      {double designWidth = 375, double designHeight = 812}) {
    final mq = MediaQuery.of(context);
    _designWidth = designWidth;
    _designHeight = designHeight;
    screenWidth = mq.size.width;
    screenHeight = mq.size.height;
    scaleWidth = screenWidth / _designWidth;
    scaleHeight = screenHeight / _designHeight;
    // prefer width scale for text so typography scales predictably
    textScale = scaleWidth;
  }

  // width percentage of design (wp)
  static double wp(double px) => px * scaleWidth;

  // height percentage of design (hp)
  static double hp(double px) => px * scaleHeight;

  // scaled text px
  static double sp(double px) => px * textScale;
}
