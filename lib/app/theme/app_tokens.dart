import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 40.0;
  static const xxxl = 48.0;
}

abstract final class AppRadii {
  static const small = 10.0;
  static const medium = 14.0;
  static const large = 20.0;
  static const xLarge = 24.0;
  static const pill = 999.0;

  static const card = BorderRadius.all(Radius.circular(large));
  static const control = BorderRadius.all(Radius.circular(medium));
  static const banner = BorderRadius.all(Radius.circular(large));
}

abstract final class AppElevation {
  static const none = 0.0;
  static const raised = 1.0;
  static const overlay = 6.0;
}

abstract final class AppShadows {
  static const soft = [
    BoxShadow(color: Color(0x12073F3B), blurRadius: 18, offset: Offset(0, 6)),
  ];

  static const softDark = [
    BoxShadow(color: Color(0x38000000), blurRadius: 20, offset: Offset(0, 8)),
  ];
}

abstract final class AppDurations {
  static const quick = Duration(milliseconds: 120);
  static const standard = Duration(milliseconds: 220);
  static const emphasis = Duration(milliseconds: 320);
}

abstract final class AppSizes {
  static const minimumTouchTarget = 48.0;
  static const iconSmall = 18.0;
  static const iconMedium = 24.0;
  static const iconLarge = 32.0;
  static const avatarSmall = 36.0;
  static const avatarMedium = 48.0;
  static const avatarLarge = 64.0;
  static const progressThickness = 8.0;
  static const contentMaxWidth = 760.0;
  static const navigationHeight = 72.0;
  // Keeps Cairo navigation labels inside the bar at 320px / text scale 1.5.
  static const navigationHeightLargeText = 80.0;
}

abstract final class AppBreakpoints {
  static const compact = 360.0;
  static const medium = 700.0;
  static const expanded = 1024.0;
}
