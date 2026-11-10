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
  const RingLoader({
    this.size = 40,
    this.ringColor,
    this.accentColor,
    this.semanticLabel,
    this.fadedRing = true,
    super.key,
  });

  final double size;
  final Color? ringColor;
  final Color? accentColor;
  final String? semanticLabel;

  /// Soft ring under the moving segment (inline loaders). The splash keeps
  /// the full ring so it continues the system launch screen without a jump.
  final bool fadedRing;

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
            // The amber light moves from one segment to the next, in order.
            final position = t * RingPainter.segments;
            return CustomPaint(
              painter: RingPainter(ring: widget.fadedRing ? ring.withValues(alpha: 0.28) : ring, accent: accent, position: position),
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
  // Geometry of the A2 mark (design/identity-v2/tool), relative to the radius.
  static const _outer = 0.94;
  static const _inner = 0.561;
  static const _soft = 0.0606; // corner softening
  static const _gap = 3.6 * math.pi / 180;

  final Color ring;
  final Color accent;

  /// Which segment is lit, counted from the top clockwise (0..8). Between two
  /// whole numbers the light hands over: the current segment stays lit for the
  /// first half of the step, then fades while the next one lights up.
  final double position;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final soft = radius * _soft;
    final paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;
    final edge = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = soft * 2
      ..strokeJoin = StrokeJoin.round;
    const step = 2 * math.pi / segments;
    final current = position.floor();
    final f = position - current;
    final handover = f < 0.5 ? 0.0 : Motion.easing.transform((f - 0.5) * 2);
    for (var i = 0; i < segments; i++) {
      final light = i == current % segments
          ? 1 - handover
          : i == (current + 1) % segments
          ? handover
          : 0.0;
      final color = Color.lerp(ring, accent, light)!;
      final path = _segment(center, radius, soft, -math.pi / 2 + i * step);
      canvas
        ..drawPath(path, paint..color = color)
        ..drawPath(path, edge..color = color);
    }
  }

  /// One segment, shrunk by [soft] so the round-joined stroke brings it back
  /// to full size with softened corners.
  Path _segment(Offset c, double r, double soft, double start) {
    const step = 2 * math.pi / segments;
    final outer = r * _outer - soft;
    final inner = r * _inner + soft;
    final da = math.asin(soft / outer);
    final db = math.asin(soft / inner);
    final from = start + _gap;
    final to = start + step - _gap;
    return Path()
      ..arcTo(Rect.fromCircle(center: c, radius: outer), from + da, (to - da) - (from + da), true)
      ..arcTo(Rect.fromCircle(center: c, radius: inner), to - db, (from + db) - (to - db), false)
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
