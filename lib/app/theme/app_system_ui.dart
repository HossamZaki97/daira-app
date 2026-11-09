import 'package:daira/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keeps Android system chrome synchronized with the resolved app theme.
class DairaSystemUi extends StatelessWidget {
  const DairaSystemUi({required this.child, super.key});

  final Widget child;

  static SystemUiOverlayStyle styleFor(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarColor: dark
          ? AppColors.surfaceDark
          : AppColors.surface,
      systemNavigationBarDividerColor: dark
          ? AppColors.borderDark
          : AppColors.border,
      systemNavigationBarIconBrightness: dark
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    key: const Key('daira-system-ui'),
    value: styleFor(Theme.of(context).brightness),
    child: child,
  );
}
