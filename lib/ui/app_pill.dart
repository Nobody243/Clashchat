import 'package:flutter/material.dart';

import '../core/app_colors_ext.dart';
import '../core/app_spacing.dart';
import '../models/debate_mode.dart';
import 'app_icons.dart';

enum AppPillTone { neutral, accent, positive, negative, warning, info, rank }

/// 28 px semantic pill. See DESIGN.md §4.
class AppPill extends StatelessWidget {
  const AppPill({
    super.key,
    required this.label,
    this.icon,
    this.tone = AppPillTone.neutral,
    this.outlined = false,
    this.mono = false,
  });

  /// Pill for a debate stance ('For' / 'Against').
  factory AppPill.stance(String stance, {Key? key, bool withIcon = true}) {
    final isFor = stance.trim().toLowerCase() == 'for';
    return AppPill(
      key: key,
      label: isFor ? 'For' : 'Against',
      icon: withIcon ? AppIcons.forStance(stance) : null,
      tone: isFor ? AppPillTone.positive : AppPillTone.negative,
    );
  }

  /// Pill for a difficulty ('Easy' / 'Medium' / 'Hard' or rank names).
  factory AppPill.difficulty(String difficulty, {Key? key, bool withIcon = true}) {
    final d = difficulty.trim().toLowerCase();
    final tone = switch (d) {
      'easy' || 'newcomer' => AppPillTone.positive,
      'hard' || 'orator' || 'grandmaster' => AppPillTone.negative,
      _ => AppPillTone.warning,
    };
    final label = difficulty.isEmpty
        ? 'Medium'
        : difficulty[0].toUpperCase() + difficulty.substring(1).toLowerCase();
    return AppPill(
      key: key,
      label: label,
      icon: withIcon ? AppIcons.forDifficulty(difficulty) : null,
      tone: tone,
    );
  }

  /// Pill for a debate mode.
  factory AppPill.mode(DebateMode mode, {Key? key, bool withIcon = true}) {
    final (label, tone) = switch (mode) {
      DebateMode.casual => ('Casual', AppPillTone.positive),
      DebateMode.ranked => ('Ranked', AppPillTone.rank),
      DebateMode.learning => ('Learning', AppPillTone.info),
    };
    return AppPill(
      key: key,
      label: label,
      icon: withIcon ? AppIcons.forMode(mode) : null,
      tone: tone,
    );
  }

  final String label;
  final IconData? icon;
  final AppPillTone tone;
  final bool outlined;
  /// Use the monospace numeric face (scores, points).
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (Color bg, Color fg) = switch (tone) {
      AppPillTone.neutral => (c.surfaceRaised, c.textSecondary),
      AppPillTone.accent => (c.accentSoft, c.accent),
      AppPillTone.positive => (c.positiveBg, c.positiveText),
      AppPillTone.negative => (c.negativeBg, c.negativeText),
      AppPillTone.warning => (c.warningBg, c.warningText),
      AppPillTone.info => (c.infoBg, c.infoText),
      AppPillTone.rank => (c.rankBg, c.rankText),
    };

    final style = mono
        ? context.mono(size: 12, color: fg)
        : context.text.labelMedium?.copyWith(color: fg);

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : bg,
        borderRadius: AppRadius.pillAll,
        border: outlined ? Border.all(color: fg.withValues(alpha: 0.5)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: AppSpacing.xs + 2),
          ],
          Text(label, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
