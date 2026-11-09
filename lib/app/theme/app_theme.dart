import 'package:daira/app/theme/app_colors.dart';
import 'package:daira/app/theme/app_tokens.dart';
import 'package:daira/app/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'app_system_ui.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(
    scheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.surface,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.textPrimary,
      secondary: AppColors.violet,
      onSecondary: AppColors.surface,
      secondaryContainer: AppColors.violetContainer,
      onSecondaryContainer: AppColors.textPrimary,
      tertiary: AppColors.cyan,
      onTertiary: AppColors.textPrimary,
      tertiaryContainer: AppColors.cyanContainer,
      onTertiaryContainer: AppColors.textPrimary,
      error: AppColors.errorForeground,
      onError: AppColors.surface,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.textPrimary,
      surface: AppColors.backgroundLight,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.textDisabled,
      outlineVariant: AppColors.border,
      shadow: Color(0x24172033),
      scrim: Color(0x99172033),
      inverseSurface: AppColors.surfaceDark,
      onInverseSurface: AppColors.textPrimaryDark,
      inversePrimary: AppColors.primaryDarkMode,
      surfaceTint: Colors.transparent,
    ),
    semantic: DairaSemanticColors.light,
  );

  static ThemeData get dark => _build(
    scheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryDarkMode,
      onPrimary: AppColors.backgroundDark,
      primaryContainer: AppColors.primaryContainerDark,
      onPrimaryContainer: AppColors.textPrimaryDark,
      secondary: AppColors.violetDark,
      onSecondary: AppColors.backgroundDark,
      secondaryContainer: AppColors.violetContainerDark,
      onSecondaryContainer: AppColors.textPrimaryDark,
      tertiary: AppColors.cyanDark,
      onTertiary: AppColors.backgroundDark,
      tertiaryContainer: AppColors.cyanContainerDark,
      onTertiaryContainer: AppColors.textPrimaryDark,
      error: AppColors.errorDark,
      onError: AppColors.backgroundDark,
      errorContainer: AppColors.errorContainerDark,
      onErrorContainer: AppColors.textPrimaryDark,
      surface: AppColors.backgroundDark,
      onSurface: AppColors.textPrimaryDark,
      onSurfaceVariant: AppColors.textSecondaryDark,
      outline: Color(0xFF758199),
      outlineVariant: AppColors.borderDark,
      shadow: Color(0xCC000000),
      scrim: Color(0xCC000000),
      inverseSurface: AppColors.textPrimaryDark,
      onInverseSurface: AppColors.backgroundDark,
      inversePrimary: AppColors.primary,
      surfaceTint: Colors.transparent,
    ),
    semantic: DairaSemanticColors.dark,
  );

  static ThemeData _build({
    required ColorScheme scheme,
    required DairaSemanticColors semantic,
  }) {
    final textTheme = AppTypography.textTheme(scheme.onSurface);
    final base = ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      fontFamily: AppTypography.cairoFamily,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      extensions: [semantic],
    );

    final controlShape = RoundedRectangleBorder(borderRadius: AppRadii.control);
    final cardShape = RoundedRectangleBorder(
      borderRadius: AppRadii.card,
      side: BorderSide(color: semantic.borderSubtle),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        systemOverlayStyle: DairaSystemUi.styleFor(scheme.brightness),
        elevation: AppElevation.none,
        scrolledUnderElevation: AppElevation.none,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: semantic.textPrimary,
        titleTextStyle: textTheme.titleLarge,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: AppElevation.none,
        color: semantic.surfacePrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: scheme.shadow,
        margin: EdgeInsets.zero,
        shape: cardShape,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              minimumSize: const Size(
                AppSizes.minimumTouchTarget,
                AppSizes.minimumTouchTarget,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              backgroundColor: semantic.actionStrong,
              foregroundColor: scheme.onPrimary,
              disabledBackgroundColor: semantic.statusNeutralContainer,
              disabledForegroundColor: semantic.textDisabled,
              elevation: AppElevation.none,
              shape: controlShape,
              textStyle: textTheme.labelLarge,
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.pressed)
                    ? semantic.pressedSurface.withValues(alpha: .28)
                    : null,
              ),
            ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            AppSizes.minimumTouchTarget,
            AppSizes.minimumTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          foregroundColor: semantic.actionPrimary,
          side: BorderSide(color: semantic.borderSubtle),
          shape: controlShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(
            AppSizes.minimumTouchTarget,
            AppSizes.minimumTouchTarget,
          ),
          foregroundColor: semantic.actionPrimary,
          shape: controlShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppSizes.minimumTouchTarget),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.control),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: semantic.surfacePrimary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: semantic.textMuted),
        hintStyle: textTheme.bodyMedium?.copyWith(color: semantic.textMuted),
        errorStyle: textTheme.bodySmall?.copyWith(
          color: semantic.statusOverdue,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadii.control,
          borderSide: BorderSide(color: semantic.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.control,
          borderSide: BorderSide(color: semantic.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.control,
          borderSide: BorderSide(color: semantic.actionPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.control,
          borderSide: BorderSide(color: semantic.statusOverdue),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.control,
          borderSide: BorderSide(color: semantic.borderSubtle),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: semantic.surfaceSecondary,
        selectedColor: semantic.selectedSurface,
        disabledColor: semantic.statusNeutralContainer,
        side: BorderSide(color: semantic.borderSubtle),
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: semantic.actionStrong,
        textColor: scheme.onPrimary,
        textStyle: textTheme.labelSmall,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      ),
      dialogTheme: DialogThemeData(
        elevation: AppElevation.overlay,
        backgroundColor: semantic.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: AppElevation.overlay,
        modalElevation: AppElevation.overlay,
        backgroundColor: semantic.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.xLarge),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.control),
      ),
      dividerTheme: DividerThemeData(
        color: semantic.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: semantic.accentCyan,
        linearTrackColor: semantic.surfaceSecondary,
        circularTrackColor: semantic.surfaceSecondary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : semantic.textDisabled,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? semantic.actionPrimary
              : semantic.statusNeutralContainer,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, AppSizes.minimumTouchTarget),
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : semantic.textMuted,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primaryContainer
                : semantic.surfacePrimary,
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: semantic.borderSubtle),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelMedium),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppSizes.navigationHeight,
        elevation: AppElevation.none,
        backgroundColor: semantic.surfacePrimary,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? semantic.actionPrimary
                : semantic.textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? semantic.actionPrimary
                : semantic.textMuted,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        labelColor: semantic.actionPrimary,
        unselectedLabelColor: semantic.textMuted,
        labelStyle: textTheme.labelMedium,
        unselectedLabelStyle: textTheme.labelMedium,
        indicatorColor: semantic.actionPrimary,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: semantic.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: scheme.primaryContainer,
        headerForegroundColor: scheme.onPrimaryContainer,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return semantic.textDisabled;
          }
          return states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : semantic.textPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              !states.contains(WidgetState.disabled) &&
                  states.contains(WidgetState.selected)
              ? semantic.actionStrong
              : null,
        ),
        todayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return semantic.textDisabled;
          }
          return states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : semantic.actionPrimary;
        }),
        todayBackgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              !states.contains(WidgetState.disabled) &&
                  states.contains(WidgetState.selected)
              ? semantic.actionStrong
              : null,
        ),
        todayBorder: BorderSide(color: semantic.actionPrimary),
        dayOverlayColor: WidgetStatePropertyAll(semantic.pressedSurface),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: semantic.actionPrimary,
        textColor: semantic.textPrimary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xxs,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.control),
      ),
    );
  }
}
