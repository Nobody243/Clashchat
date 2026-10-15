import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/timer_service.dart';
import '../ui/ui.dart';

/// Countdown pill: a 36 px ring (inset track, accent arc that depletes
/// clockwise with the remaining fraction) around the timer glyph, `mm:ss` in
/// the mono face to its right. Under 60 s the arc and digits turn terracotta
/// and pulse; while paused the glyph becomes a pause mark. Tap (when [onTap]
/// is given) toggles pause / resume.
class DebateTimerWidget extends StatelessWidget {
  final DebateTimerService timerService;
  final VoidCallback? onTap;

  /// Total length of the countdown in seconds. Defaults to the service's own
  /// total (`totalMinutes * 60`); pass it when the service was started
  /// elsewhere and only the remaining time is known.
  final int? totalSeconds;

  const DebateTimerWidget({
    super.key,
    required this.timerService,
    this.onTap,
    this.totalSeconds,
  });

  double get _remainingFraction {
    final total = totalSeconds ?? timerService.totalMinutes * 60;
    if (total <= 0) return 0;
    return (timerService.remainingSeconds / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: timerService,
      builder: (context, _) {
        final c = context.colors;
        final remaining = timerService.remainingSeconds;
        final isLow = remaining > 0 && remaining < 60;
        final isPaused = !timerService.isRunning && remaining > 0;
        final fg = isLow ? c.negativeText : c.textPrimary;
        final arc = isLow ? c.negativeText : c.accent;

        final ring = SizedBox(
          width: 36,
          height: 36,
          child: CustomPaint(
            painter: _TimerRingPainter(
              fraction: _remainingFraction,
              track: c.inset,
              arc: isPaused ? c.textHint : arc,
              stroke: 3,
            ),
            child: Center(
              child: Icon(
                isPaused ? AppIcons.pause : AppIcons.timer,
                size: 16,
                color: fg,
              ),
            ),
          ),
        );

        Widget content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ring,
            const SizedBox(width: AppSpacing.sm),
            Text(
              timerService.formattedTime,
              style: context.mono(size: 14, color: fg),
            ),
          ],
        );

        if (isLow && !isPaused && !context.reduceMotion) {
          content = content
              .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
              .fade(
                begin: 1.0,
                end: 0.55,
                duration: 900.ms,
                curve: Curves.easeInOut,
              );
        }

        final pill = Container(
          height: 44,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xs,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            borderRadius: AppRadius.pillAll,
            border: Border.all(color: c.border),
          ),
          alignment: Alignment.center,
          child: content,
        );

        if (onTap == null) return pill;
        return Pressable(
          onTap: onTap,
          pressedScale: 0.96,
          semanticLabel: isPaused ? 'Resume timer' : 'Pause timer',
          child: pill,
        );
      },
    );
  }
}

/// Inset track plus an arc covering the remaining fraction. The arc anchors
/// at 12 o'clock and the gap grows clockwise from there as time runs out.
class _TimerRingPainter extends CustomPainter {
  _TimerRingPainter({
    required this.fraction,
    required this.track,
    required this.arc,
    required this.stroke,
  });

  final double fraction;
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
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    if (fraction <= 0) return;
    final sweep = math.pi * 2 * fraction;
    final start = -math.pi / 2 + (math.pi * 2 - sweep);
    final arcPaint = Paint()
      ..color = arc
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep, false, arcPaint);
  }

  @override
  bool shouldRepaint(_TimerRingPainter old) =>
      old.fraction != fraction ||
      old.track != track ||
      old.arc != arc ||
      old.stroke != stroke;
}
