import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';

/// The Daira mark: eight ring segments (the rounds of a circle); the amber one
/// is "your turn". Same geometry as design/identity-v2/logo/daira-mark-on-light.svg.
class DairaMark extends StatelessWidget {
  const DairaMark({this.size = 48, this.ringColor, this.accentColor, super.key});

  final double size;
  final Color? ringColor;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: RingPainter(
          ring: ringColor ?? context.colors.primary,
          accent: accentColor ?? context.colors.accent,
          position: 0,
        ),
      ),
    ),
  );
}

/// The loader: the amber segment orbits the ring, one segment at a time.
/// With "reduce motion" on, the mark only fades in and out.
class RingLoader extends StatefulWidget {
  const RingLoader({this.size = 40, this.ringColor, this.accentColor, this.semanticLabel, super.key});

  final double size;
  final Color? ringColor;
  final Color? accentColor;
  final String? semanticLabel;

  @override
  State<RingLoader> createState() => _RingLoaderState();
}

class _RingLoaderState extends State<RingLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: Motion.orbit)..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ring = widget.ringColor ?? colors.primary;
    final accent = widget.accentColor ?? colors.accent;
    final reduce = context.reduceMotion;
    return Semantics(
      label: widget.semanticLabel ?? MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
      liveRegion: true,
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            if (reduce) {
              return Opacity(
                opacity: 0.45 + 0.55 * (0.5 + 0.5 * math.cos(t * 2 * math.pi)),
                child: CustomPaint(painter: RingPainter(ring: ring, accent: accent, position: 0)),
              );
            }
            // Each step glides to the next segment with the standard easing.
            final steps = t * RingPainter.segments;
            final step = steps.floor();
            final position = step + Motion.easing.transform(steps - step);
            return CustomPaint(
              painter: RingPainter(ring: ring.withValues(alpha: 0.28), accent: accent, position: position),
            );
          },
        ),
      ),
    );
  }
}

class RingPainter extends CustomPainter {
  const RingPainter({required this.ring, required this.accent, required this.position});

  static const segments = 8;
  static const _outer = 240 / 256;
  static const _inner = 152 / 256;
  static const _gap = 3 * math.pi / 180;

  final Color ring;
  final Color accent;

  /// Where the accent segment sits, in segments from the top (0..8, fractional while moving).
  final double position;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final paint = Paint()..isAntiAlias = true;
    const step = 2 * math.pi / segments;
    final accentIndex = position == position.roundToDouble() ? position.round() % segments : -1;
    for (var i = 0; i < segments; i++) {
      if (i == accentIndex) continue;
      paint.color = ring;
      canvas.drawPath(_segment(center, radius, -math.pi / 2 + i * step), paint);
    }
    paint.color = accent;
    canvas.drawPath(_segment(center, radius, -math.pi / 2 + position * step), paint);
  }

  Path _segment(Offset c, double r, double start) {
    const step = 2 * math.pi / segments;
    final from = start + _gap;
    const sweep = step - 2 * _gap;
    final outer = Rect.fromCircle(center: c, radius: r * _outer);
    final inner = Rect.fromCircle(center: c, radius: r * _inner);
    return Path()
      ..arcTo(outer, from, sweep, true)
      ..arcTo(inner, from + sweep, -sweep, false)
      ..close();
  }

  @override
  bool shouldRepaint(RingPainter old) => old.position != position || old.ring != ring || old.accent != accent;
}

/// A full-screen calm loading state: the orbiting ring and an optional line.
class LoadingView extends StatelessWidget {
  const LoadingView({this.message, super.key});
  final String? message;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const RingLoader(size: 44),
        if (message != null) ...[
          const SizedBox(height: Space.md),
          Text(message!, style: context.text.bodyMedium?.copyWith(color: context.colors.textMuted)),
        ],
      ],
    ),
  );
}
