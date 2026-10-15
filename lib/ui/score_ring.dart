import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_colors_ext.dart';

/// Circular score indicator: inset track, accent arc, mono number.
/// See DESIGN.md §4. Animates from 0 to [value] on first build.
class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.value,
    this.max = 100,
    this.size = 160,
    this.stroke = 8,
    this.color,
    this.label,
    this.animate = true,
  });

  /// 0..[max]
  final double value;
  final double max;
  final double size;
  final double stroke;
  final Color? color;
  /// Small caption under the number, e.g. "out of 100".
  final String? label;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final target = (value / max).clamp(0.0, 1.0);
    final arcColor = color ?? c.accent;
    final numberSize = size * 0.28;

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: animate && !context.reduceMotion ? 0 : target, end: target),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) {
          return CustomPaint(
            painter: _RingPainter(
              progress: t,
              track: c.inset,
              arc: arcColor,
              stroke: stroke,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (t * max).round().toString(),
                    style: context.mono(
                      size: numberSize,
                      weight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                  if (label != null)
                    Text(
                      label!,
                      style: context.text.labelSmall?.copyWith(color: c.textHint),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.track,
    required this.arc,
    required this.stroke,
  });

  final double progress;
  final Color track;
  final Color arc;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    if (progress <= 0) return;
    final arcPaint = Paint()
      ..color = arc
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, arcPaint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.track != track ||
      old.arc != arc ||
      old.stroke != stroke;
}

/// Thin horizontal progress with an inset track.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.height = 6,
    this.color,
  });

  final double value;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => LinearProgressIndicator(
          value: t,
          minHeight: height,
          backgroundColor: c.inset,
          color: color ?? c.accent,
        ),
      ),
    );
  }
}
