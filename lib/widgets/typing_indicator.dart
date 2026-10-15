import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../ui/ui.dart';

/// Three hint-coloured dots bouncing in sequence inside an AI-style bubble.
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduce = context.reduceMotion;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(
          top: AppSpacing.md,
          bottom: AppSpacing.xxs,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + 2,
        ),
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(6),
          ),
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final dot = Container(
              width: 6,
              height: 6,
              margin: EdgeInsets.only(right: i == 2 ? 0 : AppSpacing.xs + 1),
              decoration: BoxDecoration(
                color: c.textHint,
                shape: BoxShape.circle,
              ),
            );
            if (reduce) return dot;
            return dot
                .animate(
                  onPlay: (ctrl) => ctrl.repeat(reverse: true),
                  delay: (i * 160).ms,
                )
                .moveY(
                  begin: 0,
                  end: -4,
                  duration: 420.ms,
                  curve: Curves.easeInOut,
                )
                .fade(begin: 0.5, end: 1.0, duration: 420.ms);
          }),
        ),
      ),
    );
  }
}
