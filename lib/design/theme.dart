import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';
import 'tokens.dart';
import 'typography.dart';

/// Material theme built only from Daira tokens. Widgets read extra roles with
/// `context.colors` (see [DairaThemeX]).
abstract final class DairaTheme {
  static final light = _build(DairaColors.light, Brightness.light);
  static final dark = _build(DairaColors.dark, Brightness.dark);

  static ThemeData _build(DairaColors c, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.primaryContainer,
      onPrimaryContainer: c.onPrimaryContainer,
      secondary: c.accent,
      onSecondary: c.onAccent,
      secondaryContainer: c.accentContainer,
      onSecondaryContainer: c.text,
      tertiary: c.success,
      onTertiary: c.surface,
      error: c.danger,
      onError: c.surface,
      errorContainer: c.dangerContainer,
      onErrorContainer: c.danger,
      surface: c.surface,
      onSurface: c.text,
      onSurfaceVariant: c.textMuted,
      surfaceContainerLowest: c.surface,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surfaceSunken,
      surfaceContainerHighest: c.surfaceSunken,
      outline: c.lineStrong,
      outlineVariant: c.line,
      shadow: const Color(0xFF141A2B),
      scrim: c.scrim,
      inverseSurface: c.hero,
      onInverseSurface: c.onHero,
      inversePrimary: c.accent,
      surfaceTint: Colors.transparent,
    );
    final text = DairaType.textTheme(c.text, c.textMuted);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md));
    const buttonSize = Size(64, Sizes.button);
    final buttonText = DairaType.label.copyWith(fontSize: 15, fontWeight: FontWeight.w700);
    final overlay = brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: DairaType.family,
      textTheme: text,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      dividerColor: c.line,
      splashFactory: InkSparkle.splashFactory,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      extensions: [c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: Space.gutter,
        titleTextStyle: DairaType.heading.copyWith(fontSize: 18, color: c.text),
        iconTheme: IconThemeData(color: c.text, size: Sizes.icon),
        systemOverlayStyle: overlay.copyWith(statusBarColor: Colors.transparent),
      ),
      iconTheme: IconThemeData(color: c.text, size: Sizes.icon),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: BorderSide(color: c.line),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(buttonSize),
          shape: WidgetStatePropertyAll(shape),
          textStyle: WidgetStatePropertyAll(buttonText),
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled)
                ? c.surfaceSunken
                : s.contains(WidgetState.pressed)
                ? c.accentPressed
                : c.accent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? c.textDisabled : c.onAccent,
          ),
          overlayColor: WidgetStatePropertyAll(c.onAccent.withValues(alpha: 0.06)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(buttonSize),
          shape: WidgetStatePropertyAll(shape),
          textStyle: WidgetStatePropertyAll(buttonText),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? c.textDisabled : c.primary,
          ),
          side: WidgetStateProperty.resolveWith(
            (s) => BorderSide(color: s.contains(WidgetState.disabled) ? c.line : c.lineStrong),
          ),
          overlayColor: WidgetStatePropertyAll(c.primary.withValues(alpha: 0.06)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, Sizes.buttonSmall + 4)),
          shape: WidgetStatePropertyAll(shape),
          textStyle: WidgetStatePropertyAll(buttonText.copyWith(fontSize: 14)),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? c.textDisabled : c.primary,
          ),
          overlayColor: WidgetStatePropertyAll(c.primary.withValues(alpha: 0.06)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size.square(Sizes.touchTarget)),
          foregroundColor: WidgetStatePropertyAll(c.text),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 15),
        labelStyle: DairaType.body.copyWith(color: c.textMuted),
        floatingLabelStyle: DairaType.label.copyWith(color: c.text),
        hintStyle: DairaType.body.copyWith(color: c.textDisabled),
        helperStyle: DairaType.caption.copyWith(color: c.textMuted),
        errorStyle: DairaType.caption.copyWith(color: c.danger),
        prefixIconColor: c.textMuted,
        suffixIconColor: c.textMuted,
        border: _border(c.lineStrong),
        enabledBorder: _border(c.lineStrong),
        disabledBorder: _border(c.line),
        focusedBorder: _border(c.primary, 1.5),
        errorBorder: _border(c.danger),
        focusedErrorBorder: _border(c.danger, 1.5),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionColor: c.accent.withValues(alpha: 0.35),
        selectionHandleColor: c.accent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.track,
        circularTrackColor: c.track,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        selectedColor: c.primaryContainer,
        side: BorderSide(color: c.line),
        labelStyle: DairaType.label.copyWith(color: c.text),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.pill)),
        padding: const EdgeInsets.symmetric(horizontal: Space.xs),
        showCheckmark: false,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 44)),
          textStyle: WidgetStatePropertyAll(DairaType.label),
          side: WidgetStatePropertyAll(BorderSide(color: c.lineStrong)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? c.primaryContainer : c.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? c.onPrimaryContainer : c.textMuted,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.textMuted,
        textColor: c.text,
        titleTextStyle: DairaType.body.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: c.text),
        subtitleTextStyle: DairaType.caption.copyWith(color: c.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: Space.md),
        minVerticalPadding: Space.sm,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.onPrimary : c.lineStrong,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary : c.surfaceSunken,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary : c.lineStrong,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: Sizes.navBar,
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: c.primaryContainer,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.pill)),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => DairaType.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: s.contains(WidgetState.selected) ? c.text : c.textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: Sizes.icon,
            color: s.contains(WidgetState.selected) ? c.onPrimaryContainer : c.textMuted,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: c.scrim,
        showDragHandle: true,
        dragHandleColor: c.lineStrong,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        barrierColor: c.scrim,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.xl)),
        titleTextStyle: DairaType.heading.copyWith(fontSize: 18, color: c.text),
        contentTextStyle: DairaType.body.copyWith(color: c.textMuted),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.hero,
        contentTextStyle: DairaType.body.copyWith(color: c.onHero),
        actionTextColor: c.accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
        elevation: 0,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: c.hero, borderRadius: BorderRadius.circular(Radii.xs)),
        textStyle: DairaType.caption.copyWith(color: c.onHero),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static OutlineInputBorder _border(Color color, [double width = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(Radii.md),
    borderSide: BorderSide(color: color, width: width),
  );
}

extension DairaThemeX on BuildContext {
  DairaColors get colors => Theme.of(this).extension<DairaColors>() ?? DairaColors.light;
  TextTheme get text => Theme.of(this).textTheme;
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;

  /// Respect the system "reduce motion" setting: fade only, no movement.
  bool get reduceMotion => MediaQuery.maybeDisableAnimationsOf(this) ?? false;
}
