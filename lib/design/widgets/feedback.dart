import 'package:flutter/material.dart';

import '../colors.dart';
import '../icons.dart';
import '../theme.dart';
import '../tokens.dart';
import 'buttons.dart';
import 'ring.dart';

/// Meaning of a status. Never uses the accent color.
enum Tone { success, pending, danger, info }

extension ToneColors on DairaColors {
  Color tone(Tone t) => switch (t) {
    Tone.success => success,
    Tone.pending => pending,
    Tone.danger => danger,
    Tone.info => info,
  };

  Color toneContainer(Tone t) => switch (t) {
    Tone.success => successContainer,
    Tone.pending => pendingContainer,
    Tone.danger => dangerContainer,
    Tone.info => infoContainer,
  };
}

/// Small pill with a status: «مؤكَّد», «بانتظار التأكيد», «متأخر»…
class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {this.tone = Tone.pending, this.icon, super.key});
  final String label;
  final Tone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fg = colors.tone(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: colors.toneContainer(tone), borderRadius: BorderRadius.circular(Radii.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: Space.xxs)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// A full-width message above content (announcements, optional update, notices).
class InlineBanner extends StatelessWidget {
  const InlineBanner({
    required this.title,
    this.body,
    this.tone = Tone.info,
    this.icon,
    this.action,
    this.onDismiss,
    super.key,
  });

  final String title;
  final String? body;
  final Tone tone;
  final IconData? icon;
  final Widget? action;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fg = colors.tone(tone);
    return Semantics(
      container: true,
      liveRegion: tone == Tone.danger,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(Space.md, Space.sm, Space.xs, Space.sm),
        decoration: BoxDecoration(color: colors.toneContainer(tone), borderRadius: BorderRadius.circular(Radii.md)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon ?? _icon, size: 20, color: fg),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.labelLarge?.copyWith(color: colors.text)),
                  if (body != null) ...[
                    const SizedBox(height: 2),
                    Text(body!, style: context.text.bodySmall?.copyWith(color: colors.textMuted)),
                  ],
                  if (action != null) ...[const SizedBox(height: Space.xs), action!],
                ],
              ),
            ),
            if (onDismiss != null)
              IconButton(
                onPressed: onDismiss,
                icon: Icon(AppIcons.close, size: 18, color: colors.textMuted),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                visualDensity: VisualDensity.compact,
              )
            else
              const SizedBox(width: Space.xs),
          ],
        ),
      ),
    );
  }

  IconData get _icon => switch (tone) {
    Tone.success => AppIcons.success,
    Tone.danger => AppIcons.warning,
    Tone.pending => AppIcons.waiting,
    Tone.info => AppIcons.info,
  };
}

/// Calm, centered message for an empty list or a blocked state: mark or icon,
/// one title, one sentence, then at most a primary and a secondary action.
class MessageView extends StatelessWidget {
  const MessageView({
    required this.title,
    this.body,
    this.icon,
    this.showMark = false,
    this.primary,
    this.secondary,
    this.extra,
    super.key,
  });

  final String title;
  final String? body;
  final IconData? icon;

  /// Use the Daira mark instead of an icon (first-run empty states).
  final bool showMark;
  final Widget? primary;
  final Widget? secondary;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showMark)
                const DairaMark(size: 64)
              else if (icon != null)
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: colors.primaryContainer, shape: BoxShape.circle),
                  child: Icon(icon, size: 30, color: colors.onPrimaryContainer),
                ),
              const SizedBox(height: Space.lg),
              Text(title, textAlign: TextAlign.center, style: context.text.titleLarge),
              if (body != null) ...[
                const SizedBox(height: Space.xs),
                Text(body!, textAlign: TextAlign.center, style: context.text.bodyMedium?.copyWith(color: colors.textMuted)),
              ],
              if (extra != null) ...[const SizedBox(height: Space.md), extra!],
              if (primary != null) ...[const SizedBox(height: Space.xl), primary!],
              if (secondary != null) ...[const SizedBox(height: Space.sm), secondary!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Failure state with a retry. [message] comes from `l10n.error(e)`.
class ErrorView extends StatelessWidget {
  const ErrorView({required this.title, required this.message, required this.retryLabel, this.onRetry, this.offline = false, super.key});

  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;
  final bool offline;

  @override
  Widget build(BuildContext context) => MessageView(
    icon: offline ? AppIcons.offline : AppIcons.warning,
    title: title,
    body: message,
    primary: onRetry == null ? null : AppButton.secondary(label: retryLabel, onPressed: onRetry, icon: AppIcons.refresh),
  );
}

/// Pulsing placeholder block shown while content loads (never a spinner in lists).
class Skeleton extends StatefulWidget {
  const Skeleton({this.width, this.height = 14, this.radius = Radii.xs, super.key});

  /// A rounded line of text.
  const Skeleton.line({this.width, super.key}) : height = 12, radius = Radii.xs;

  /// A whole card.
  const Skeleton.card({this.height = 96, super.key}) : width = double.infinity, radius = Radii.lg;

  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: Motion.skeletonPulse)
    ..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(colors.skeleton, colors.skeletonHighlight, context.reduceMotion ? 0 : _pulse.value),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}

/// Loading placeholder for a list of cards.
class SkeletonList extends StatelessWidget {
  const SkeletonList({this.count = 3, this.height = 96, super.key});
  final int count;
  final double height;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < count; i++) ...[
        if (i > 0) const SizedBox(height: Space.sm),
        Skeleton.card(height: height),
      ],
    ],
  );
}

/// Short confirmation at the bottom ("Saved", "Copied").
void showToast(BuildContext context, String message, {Tone tone = Tone.info}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (tone != Tone.info) ...[
              Icon(
                tone == Tone.success ? AppIcons.success : AppIcons.warning,
                size: 20,
                color: tone == Tone.success ? DairaColors.dark.success : DairaColors.dark.danger,
              ),
              const SizedBox(width: Space.sm),
            ],
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
