// Generated from design/identity-v2/design-tokens.json — edit the JSON, then regenerate.
import 'package:flutter/material.dart';

/// Color roles of the Daira identity (C1: night navy + amber).
/// Accent is only for the one primary action and round progress; status never uses accent.
@immutable
class DairaColors extends ThemeExtension<DairaColors> {
  const DairaColors({
    required this.primary,
    required this.primaryPressed,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.accent,
    required this.accentPressed,
    required this.onAccent,
    required this.accentContainer,
    required this.hero,
    required this.onHero,
    required this.onHeroMuted,
    required this.background,
    required this.surface,
    required this.surfaceSunken,
    required this.track,
    required this.text,
    required this.textMuted,
    required this.textDisabled,
    required this.line,
    required this.lineStrong,
    required this.focus,
    required this.scrim,
    required this.skeleton,
    required this.skeletonHighlight,
    required this.success,
    required this.successContainer,
    required this.pending,
    required this.pendingContainer,
    required this.danger,
    required this.dangerContainer,
    required this.info,
    required this.infoContainer,
  });

  final Color primary;
  final Color primaryPressed;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color accent;
  final Color accentPressed;
  final Color onAccent;
  final Color accentContainer;
  final Color hero;
  final Color onHero;
  final Color onHeroMuted;
  final Color background;
  final Color surface;
  final Color surfaceSunken;
  final Color track;
  final Color text;
  final Color textMuted;
  final Color textDisabled;
  final Color line;
  final Color lineStrong;
  final Color focus;
  final Color scrim;
  final Color skeleton;
  final Color skeletonHighlight;
  final Color success;
  final Color successContainer;
  final Color pending;
  final Color pendingContainer;
  final Color danger;
  final Color dangerContainer;
  final Color info;
  final Color infoContainer;

  static const light = DairaColors(
    primary: Color(0xFF1E2A4A),
    primaryPressed: Color(0xFF151E36),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE6E9F2),
    onPrimaryContainer: Color(0xFF1E2A4A),
    accent: Color(0xFFF0A202),
    accentPressed: Color(0xFFD68F00),
    onAccent: Color(0xFF1E2A4A),
    accentContainer: Color(0xFFFFF3D6),
    hero: Color(0xFF1E2A4A),
    onHero: Color(0xFFFFFFFF),
    onHeroMuted: Color(0xFFC3CADB),
    background: Color(0xFFF5F6F9),
    surface: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFECEEF3),
    track: Color(0xFFECEEF3),
    text: Color(0xFF141A2B),
    textMuted: Color(0xFF5F6779),
    textDisabled: Color(0xFF9AA1B0),
    line: Color(0xFFE3E6EE),
    lineStrong: Color(0xFFCDD2DE),
    focus: Color(0xFFF0A202),
    scrim: Color(0x990C111D),
    skeleton: Color(0xFFE9EBF1),
    skeletonHighlight: Color(0xFFF4F5F9),
    success: Color(0xFF1F7A47),
    successContainer: Color(0xFFE3F3EA),
    pending: Color(0xFF4A5876),
    pendingContainer: Color(0xFFE9ECF3),
    danger: Color(0xFFB4372F),
    dangerContainer: Color(0xFFFBE7E5),
    info: Color(0xFF4A5876),
    infoContainer: Color(0xFFE9ECF3),
  );

  static const dark = DairaColors(
    primary: Color(0xFFC9D3EC),
    primaryPressed: Color(0xFFAEBBDD),
    onPrimary: Color(0xFF0C111D),
    primaryContainer: Color(0xFF1E2840),
    onPrimaryContainer: Color(0xFFC9D3EC),
    accent: Color(0xFFF5B321),
    accentPressed: Color(0xFFE0A010),
    onAccent: Color(0xFF16141A),
    accentContainer: Color(0xFF3A2F12),
    hero: Color(0xFF1C2742),
    onHero: Color(0xFFFFFFFF),
    onHeroMuted: Color(0xFFAEB8D0),
    background: Color(0xFF0C111D),
    surface: Color(0xFF151C2C),
    surfaceSunken: Color(0xFF10172A),
    track: Color(0xFF222B3F),
    text: Color(0xFFEDF0F7),
    textMuted: Color(0xFF9AA4B8),
    textDisabled: Color(0xFF5E6880),
    line: Color(0xFF273047),
    lineStrong: Color(0xFF34405C),
    focus: Color(0xFFF5B321),
    scrim: Color(0xB3000000),
    skeleton: Color(0xFF1D2537),
    skeletonHighlight: Color(0xFF263049),
    success: Color(0xFF5FD08F),
    successContainer: Color(0xFF16302A),
    pending: Color(0xFFAEB8D0),
    pendingContainer: Color(0xFF232B3D),
    danger: Color(0xFFF38A80),
    dangerContainer: Color(0xFF3A1F22),
    info: Color(0xFFAEB8D0),
    infoContainer: Color(0xFF232B3D),
  );

  @override
  DairaColors copyWith() => this;

  @override
  DairaColors lerp(covariant ThemeExtension<DairaColors>? other, double t) {
    if (other is! DairaColors) return this;
    return DairaColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryPressed: Color.lerp(primaryPressed, other.primaryPressed, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      onPrimaryContainer: Color.lerp(onPrimaryContainer, other.onPrimaryContainer, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentPressed: Color.lerp(accentPressed, other.accentPressed, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentContainer: Color.lerp(accentContainer, other.accentContainer, t)!,
      hero: Color.lerp(hero, other.hero, t)!,
      onHero: Color.lerp(onHero, other.onHero, t)!,
      onHeroMuted: Color.lerp(onHeroMuted, other.onHeroMuted, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      track: Color.lerp(track, other.track, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      line: Color.lerp(line, other.line, t)!,
      lineStrong: Color.lerp(lineStrong, other.lineStrong, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      skeleton: Color.lerp(skeleton, other.skeleton, t)!,
      skeletonHighlight: Color.lerp(skeletonHighlight, other.skeletonHighlight, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      pending: Color.lerp(pending, other.pending, t)!,
      pendingContainer: Color.lerp(pendingContainer, other.pendingContainer, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
    );
  }
}
