import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';
import 'ring.dart';

enum ButtonKind {
  /// Amber. The one main action of a screen.
  primary,

  /// Outlined navy. Alternatives next to the primary action.
  secondary,

  /// Text only. Low-emphasis actions (Later, Forgot password?).
  text,

  /// Red outline. Destructive or negative answers («لم يصلني», delete).
  danger,
}

/// The app's button. Shows the ring loader while [loading] and ignores taps
/// then, so a money action can never be sent twice by double tapping.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.kind = ButtonKind.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
    super.key,
  });

  const AppButton.secondary({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
    super.key,
  }) : kind = ButtonKind.secondary;

  const AppButton.text({required this.label, required this.onPressed, this.icon, super.key})
    : kind = ButtonKind.text,
      loading = false,
      expand = false;

  final String label;
  final VoidCallback? onPressed;
  final ButtonKind kind;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final action = loading ? () {} : onPressed;
    final loaderRing = switch (kind) {
      ButtonKind.primary => colors.onAccent,
      ButtonKind.danger => colors.danger,
      _ => colors.primary,
    };
    final content = AnimatedSwitcher(
      duration: Motion.fast,
      child: loading
          ? RingLoader(
              key: const ValueKey('loading'),
              size: 22,
              ringColor: loaderRing,
              accentColor: kind == ButtonKind.primary ? colors.surface : colors.accent,
              semanticLabel: label,
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: Space.xs)],
                Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
    );
    final Widget button = switch (kind) {
      ButtonKind.primary => FilledButton(onPressed: action, child: content),
      ButtonKind.secondary => OutlinedButton(onPressed: action, child: content),
      ButtonKind.text => TextButton(onPressed: action, child: content),
      ButtonKind.danger => OutlinedButton(
        onPressed: action,
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.danger,
          side: BorderSide(color: colors.danger.withValues(alpha: 0.5)),
        ),
        child: content,
      ),
    };
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Two answers side by side, e.g. «وصلني» / «لم يصلني».
class ButtonPair extends StatelessWidget {
  const ButtonPair({required this.first, required this.second, super.key});
  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: first),
      const SizedBox(width: Space.sm),
      Expanded(child: second),
    ],
  );
}
