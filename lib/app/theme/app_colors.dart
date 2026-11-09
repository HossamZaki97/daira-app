import 'package:flutter/material.dart';

/// Raw brand palette. Presentation code consumes [DairaSemanticColors].
abstract final class AppColors {
  static const primary = Color(0xFF356DF3);
  static const primaryStrong = Color(0xFF285DD8);
  static const primaryContainer = Color(0xFFEBF1FF);
  static const primarySoft = Color(0xFFF2F5FF);
  static const violet = Color(0xFF7667F5);
  static const violetForeground = Color(0xFF5546D9);
  static const violetContainer = Color(0xFFF0EDFF);
  static const cyan = Color(0xFF27BED1);
  static const cyanForeground = Color(0xFF087F8C);
  static const cyanContainer = Color(0xFFE4F9FC);

  static const backgroundLight = Color(0xFFF5F7FB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlternative = Color(0xFFEDF3FF);
  static const border = Color(0xFFDDE3EF);
  static const textPrimary = Color(0xFF182943);
  static const textSecondary = Color(0xFF606F86);
  static const textDisabled = Color(0xFF8B95A9);

  static const success = Color(0xFF22A06B);
  static const successForeground = Color(0xFF13764A);
  static const warning = Color(0xFF9A6500);
  static const warningAccent = Color(0xFFE5A12B);
  static const error = Color(0xFFE5484D);
  static const errorForeground = Color(0xFFC52F37);
  static const information = Color(0xFF356DF3);

  static const backgroundDark = Color(0xFF101A2B);
  static const surfaceDark = Color(0xFF182943);
  static const elevatedSurfaceDark = Color(0xFF233759);
  static const borderDark = Color(0xFF30405E);
  static const primaryDarkMode = Color(0xFF9BBCFF);
  static const primaryContainerDark = Color(0xFF233759);
  static const violetDark = Color(0xFF9C91FF);
  static const violetContainerDark = Color(0xFF302B57);
  static const cyanDark = Color(0xFF50D2DF);
  static const cyanContainerDark = Color(0xFF173C4A);
  static const textPrimaryDark = Color(0xFFF4F7FF);
  static const textSecondaryDark = Color(0xFFAFBED2);
  static const successDark = Color(0xFF42C98B);
  static const warningDark = Color(0xFFF2BA55);
  static const errorDark = Color(0xFFFF7075);

  static const heroLight = Color(0xFF142C50);
  static const heroDark = Color(0xFF203D67);
  static const onHero = Color(0xFFFFFFFF);
  static const onHeroMuted = Color(0xFFDDE7FF);
  static const cycleTrackLight = Color(0xFFBFD0FF);
  static const cycleTrackDark = Color(0xFF3A568D);

  static const successContainer = Color(0xFFE5F6EE);
  static const warningContainer = Color(0xFFFFF3D8);
  static const errorContainer = Color(0xFFFFE8EA);
  static const informationContainer = Color(0xFFEBF1FF);
  static const neutralContainer = Color(0xFFEDF3FF);

  static const successContainerDark = Color(0xFF1D3D35);
  static const warningContainerDark = Color(0xFF46391F);
  static const errorContainerDark = Color(0xFF4B2933);
  static const informationContainerDark = Color(0xFF233759);
  static const neutralContainerDark = Color(0xFF27334A);
}

@immutable
class DairaSemanticColors extends ThemeExtension<DairaSemanticColors> {
  const DairaSemanticColors({
    required this.surfacePrimary,
    required this.surfaceSecondary,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textMuted,
    required this.textDisabled,
    required this.borderSubtle,
    required this.actionPrimary,
    required this.actionStrong,
    required this.accentViolet,
    required this.accentVioletContainer,
    required this.accentCyan,
    required this.accentCyanContainer,
    required this.statusSuccess,
    required this.statusSuccessContainer,
    required this.statusWarning,
    required this.statusWarningContainer,
    required this.statusOverdue,
    required this.statusOverdueContainer,
    required this.statusInfo,
    required this.statusInfoContainer,
    required this.statusNeutralContainer,
    required this.payoutHighlight,
    required this.demoBanner,
    required this.heroSurface,
    required this.onHero,
    required this.onHeroMuted,
    required this.cycleAccent,
    required this.cycleTrack,
    required this.selectedSurface,
    required this.pressedSurface,
    required this.timelineSurface,
  });

  final Color surfacePrimary;
  final Color surfaceSecondary;
  final Color surfaceElevated;
  final Color textPrimary;
  final Color textMuted;
  final Color textDisabled;
  final Color borderSubtle;
  final Color actionPrimary;
  final Color actionStrong;
  final Color accentViolet;
  final Color accentVioletContainer;
  final Color accentCyan;
  final Color accentCyanContainer;
  final Color statusSuccess;
  final Color statusSuccessContainer;
  final Color statusWarning;
  final Color statusWarningContainer;
  final Color statusOverdue;
  final Color statusOverdueContainer;
  final Color statusInfo;
  final Color statusInfoContainer;
  final Color statusNeutralContainer;
  final Color payoutHighlight;
  final Color demoBanner;
  final Color heroSurface;
  final Color onHero;
  final Color onHeroMuted;
  final Color cycleAccent;
  final Color cycleTrack;
  final Color selectedSurface;
  final Color pressedSurface;
  final Color timelineSurface;

  static const light = DairaSemanticColors(
    surfacePrimary: AppColors.surface,
    surfaceSecondary: AppColors.surfaceAlternative,
    surfaceElevated: AppColors.surface,
    textPrimary: AppColors.textPrimary,
    textMuted: AppColors.textSecondary,
    textDisabled: AppColors.textDisabled,
    borderSubtle: AppColors.border,
    actionPrimary: AppColors.primaryStrong,
    actionStrong: AppColors.primaryStrong,
    accentViolet: AppColors.violetForeground,
    accentVioletContainer: AppColors.violetContainer,
    accentCyan: AppColors.cyanForeground,
    accentCyanContainer: AppColors.cyanContainer,
    statusSuccess: AppColors.successForeground,
    statusSuccessContainer: AppColors.successContainer,
    statusWarning: AppColors.warning,
    statusWarningContainer: AppColors.warningContainer,
    statusOverdue: AppColors.errorForeground,
    statusOverdueContainer: AppColors.errorContainer,
    statusInfo: AppColors.primaryStrong,
    statusInfoContainer: AppColors.informationContainer,
    statusNeutralContainer: AppColors.neutralContainer,
    payoutHighlight: AppColors.warningContainer,
    demoBanner: AppColors.primarySoft,
    heroSurface: AppColors.heroLight,
    onHero: AppColors.onHero,
    onHeroMuted: AppColors.onHeroMuted,
    cycleAccent: AppColors.cyan,
    cycleTrack: AppColors.cycleTrackLight,
    selectedSurface: AppColors.primaryContainer,
    pressedSurface: AppColors.primarySoft,
    timelineSurface: AppColors.surface,
  );

  static const dark = DairaSemanticColors(
    surfacePrimary: AppColors.surfaceDark,
    surfaceSecondary: AppColors.elevatedSurfaceDark,
    surfaceElevated: AppColors.elevatedSurfaceDark,
    textPrimary: AppColors.textPrimaryDark,
    textMuted: AppColors.textSecondaryDark,
    textDisabled: Color(0xFF758199),
    borderSubtle: AppColors.borderDark,
    actionPrimary: AppColors.primaryDarkMode,
    actionStrong: AppColors.primaryDarkMode,
    accentViolet: AppColors.violetDark,
    accentVioletContainer: AppColors.violetContainerDark,
    accentCyan: AppColors.cyanDark,
    accentCyanContainer: AppColors.cyanContainerDark,
    statusSuccess: AppColors.successDark,
    statusSuccessContainer: AppColors.successContainerDark,
    statusWarning: AppColors.warningDark,
    statusWarningContainer: AppColors.warningContainerDark,
    statusOverdue: AppColors.errorDark,
    statusOverdueContainer: AppColors.errorContainerDark,
    statusInfo: AppColors.primaryDarkMode,
    statusInfoContainer: AppColors.informationContainerDark,
    statusNeutralContainer: AppColors.neutralContainerDark,
    payoutHighlight: AppColors.warningContainerDark,
    demoBanner: AppColors.primaryContainerDark,
    heroSurface: AppColors.heroDark,
    onHero: AppColors.onHero,
    onHeroMuted: AppColors.onHeroMuted,
    cycleAccent: AppColors.cyanDark,
    cycleTrack: AppColors.cycleTrackDark,
    selectedSurface: AppColors.primaryContainerDark,
    pressedSurface: AppColors.elevatedSurfaceDark,
    timelineSurface: AppColors.surfaceDark,
  );

  @override
  DairaSemanticColors copyWith({
    Color? surfacePrimary,
    Color? surfaceSecondary,
    Color? surfaceElevated,
    Color? textPrimary,
    Color? textMuted,
    Color? textDisabled,
    Color? borderSubtle,
    Color? actionPrimary,
    Color? actionStrong,
    Color? accentViolet,
    Color? accentVioletContainer,
    Color? accentCyan,
    Color? accentCyanContainer,
    Color? statusSuccess,
    Color? statusSuccessContainer,
    Color? statusWarning,
    Color? statusWarningContainer,
    Color? statusOverdue,
    Color? statusOverdueContainer,
    Color? statusInfo,
    Color? statusInfoContainer,
    Color? statusNeutralContainer,
    Color? payoutHighlight,
    Color? demoBanner,
    Color? heroSurface,
    Color? onHero,
    Color? onHeroMuted,
    Color? cycleAccent,
    Color? cycleTrack,
    Color? selectedSurface,
    Color? pressedSurface,
    Color? timelineSurface,
  }) => DairaSemanticColors(
    surfacePrimary: surfacePrimary ?? this.surfacePrimary,
    surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
    surfaceElevated: surfaceElevated ?? this.surfaceElevated,
    textPrimary: textPrimary ?? this.textPrimary,
    textMuted: textMuted ?? this.textMuted,
    textDisabled: textDisabled ?? this.textDisabled,
    borderSubtle: borderSubtle ?? this.borderSubtle,
    actionPrimary: actionPrimary ?? this.actionPrimary,
    actionStrong: actionStrong ?? this.actionStrong,
    accentViolet: accentViolet ?? this.accentViolet,
    accentVioletContainer: accentVioletContainer ?? this.accentVioletContainer,
    accentCyan: accentCyan ?? this.accentCyan,
    accentCyanContainer: accentCyanContainer ?? this.accentCyanContainer,
    statusSuccess: statusSuccess ?? this.statusSuccess,
    statusSuccessContainer:
        statusSuccessContainer ?? this.statusSuccessContainer,
    statusWarning: statusWarning ?? this.statusWarning,
    statusWarningContainer:
        statusWarningContainer ?? this.statusWarningContainer,
    statusOverdue: statusOverdue ?? this.statusOverdue,
    statusOverdueContainer:
        statusOverdueContainer ?? this.statusOverdueContainer,
    statusInfo: statusInfo ?? this.statusInfo,
    statusInfoContainer: statusInfoContainer ?? this.statusInfoContainer,
    statusNeutralContainer:
        statusNeutralContainer ?? this.statusNeutralContainer,
    payoutHighlight: payoutHighlight ?? this.payoutHighlight,
    demoBanner: demoBanner ?? this.demoBanner,
    heroSurface: heroSurface ?? this.heroSurface,
    onHero: onHero ?? this.onHero,
    onHeroMuted: onHeroMuted ?? this.onHeroMuted,
    cycleAccent: cycleAccent ?? this.cycleAccent,
    cycleTrack: cycleTrack ?? this.cycleTrack,
    selectedSurface: selectedSurface ?? this.selectedSurface,
    pressedSurface: pressedSurface ?? this.pressedSurface,
    timelineSurface: timelineSurface ?? this.timelineSurface,
  );

  @override
  DairaSemanticColors lerp(covariant DairaSemanticColors? other, double t) {
    if (other == null) return this;
    return DairaSemanticColors(
      surfacePrimary: Color.lerp(surfacePrimary, other.surfacePrimary, t)!,
      surfaceSecondary: Color.lerp(
        surfaceSecondary,
        other.surfaceSecondary,
        t,
      )!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      actionPrimary: Color.lerp(actionPrimary, other.actionPrimary, t)!,
      actionStrong: Color.lerp(actionStrong, other.actionStrong, t)!,
      accentViolet: Color.lerp(accentViolet, other.accentViolet, t)!,
      accentVioletContainer: Color.lerp(
        accentVioletContainer,
        other.accentVioletContainer,
        t,
      )!,
      accentCyan: Color.lerp(accentCyan, other.accentCyan, t)!,
      accentCyanContainer: Color.lerp(
        accentCyanContainer,
        other.accentCyanContainer,
        t,
      )!,
      statusSuccess: Color.lerp(statusSuccess, other.statusSuccess, t)!,
      statusSuccessContainer: Color.lerp(
        statusSuccessContainer,
        other.statusSuccessContainer,
        t,
      )!,
      statusWarning: Color.lerp(statusWarning, other.statusWarning, t)!,
      statusWarningContainer: Color.lerp(
        statusWarningContainer,
        other.statusWarningContainer,
        t,
      )!,
      statusOverdue: Color.lerp(statusOverdue, other.statusOverdue, t)!,
      statusOverdueContainer: Color.lerp(
        statusOverdueContainer,
        other.statusOverdueContainer,
        t,
      )!,
      statusInfo: Color.lerp(statusInfo, other.statusInfo, t)!,
      statusInfoContainer: Color.lerp(
        statusInfoContainer,
        other.statusInfoContainer,
        t,
      )!,
      statusNeutralContainer: Color.lerp(
        statusNeutralContainer,
        other.statusNeutralContainer,
        t,
      )!,
      payoutHighlight: Color.lerp(payoutHighlight, other.payoutHighlight, t)!,
      demoBanner: Color.lerp(demoBanner, other.demoBanner, t)!,
      heroSurface: Color.lerp(heroSurface, other.heroSurface, t)!,
      onHero: Color.lerp(onHero, other.onHero, t)!,
      onHeroMuted: Color.lerp(onHeroMuted, other.onHeroMuted, t)!,
      cycleAccent: Color.lerp(cycleAccent, other.cycleAccent, t)!,
      cycleTrack: Color.lerp(cycleTrack, other.cycleTrack, t)!,
      selectedSurface: Color.lerp(selectedSurface, other.selectedSurface, t)!,
      pressedSurface: Color.lerp(pressedSurface, other.pressedSurface, t)!,
      timelineSurface: Color.lerp(timelineSurface, other.timelineSurface, t)!,
    );
  }
}

extension DairaThemeContext on BuildContext {
  DairaSemanticColors get dairaColors {
    final theme = Theme.of(this);
    return theme.extension<DairaSemanticColors>() ??
        (theme.brightness == Brightness.dark
            ? DairaSemanticColors.dark
            : DairaSemanticColors.light);
  }
}
