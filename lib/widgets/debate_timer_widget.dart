import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/timer_service.dart';
import '../ui/ui.dart';

/// Pill-shaped countdown. Under 60 s the digits turn terracotta and pulse
/// gently; while paused the clock becomes a pause glyph. Tap (when [onTap] is
/// given) toggles pause / resume.
class DebateTimerWidget extends StatelessWidget {
  final DebateTimerService timerService;
  final VoidCallback? onTap;

  const DebateTimerWidget({
    super.key,
    required this.timerService,
    this.onTap,
  });

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

        Widget content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPaused ? AppIcons.pause : AppIcons.timer,
              size: 16,
              color: fg,
            ),
            const SizedBox(width: AppSpacing.xs + 2),
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
                end: 0.6,
                duration: 900.ms,
                curve: Curves.easeInOut,
              );
        }

        final pill = Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
