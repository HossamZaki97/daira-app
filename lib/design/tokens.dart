import 'package:flutter/animation.dart';

/// Spacing, radius, size and motion tokens (design/identity-v2/design-tokens.json).
abstract final class Space {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double gutter = 16;
}

abstract final class Radii {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double sheet = 24;
  static const double pill = 999;
}

abstract final class Sizes {
  static const double touchTarget = 48;
  static const double button = 48;
  static const double buttonSmall = 36;
  static const double input = 52;
  static const double icon = 24;
  static const double iconSmall = 18;
  static const double avatar = 36;
  static const double navBar = 72;

  /// Content never grows wider than this on tablets.
  static const double maxContent = 600;
}

abstract final class Motion {
  static const fast = Duration(milliseconds: 120);
  static const standard = Duration(milliseconds: 200);
  static const emphasis = Duration(milliseconds: 320);
  static const skeletonPulse = Duration(milliseconds: 1200);

  /// One turn of the ring loader.
  static const orbit = Duration(milliseconds: 1400);
  static const Curve easing = Cubic(0.2, 0, 0, 1);
}
