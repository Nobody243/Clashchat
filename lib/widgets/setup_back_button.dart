import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/debate_mode.dart';
import '../ui/ui.dart';

/// Chrome shared by the three-step debate setup flow (topic, stance, terms).
///
/// * [SetupBackButton]   back affordance (top-left of every step)
/// * [SetupStepDots]     "1 of 3" progress pills (wide layouts; phones use
///                       the kit's `AppStepBar`)
/// * [SetupScaffold]     the page skeleton: backdrop, header, staggered
///                       content, bottom-anchored CTA on phones, sticky
///                       summary panel on wide screens
/// * [SetupSummaryPanel] what has been chosen so far
/// * [SetupRadioMark] / [SetupDifficultyRow] single-choice rows
/// * [SetupChip]         38 px text chip for clock lengths (phones)
///
/// Everything here composes the kit in `lib/ui`; nothing invents a style.

/// Back affordance for the setup flow. Pops the route unless [onPressed]
/// is given. Filled by default now that it floats on the page rather than
/// sitting in an app bar.
class SetupBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool filled;

  /// Glyph size; phones use a plain 24 px arrow (DESIGN.md §10).
  final double iconSize;

  const SetupBackButton({
    super.key,
    this.onPressed,
    this.filled = true,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: AppIcons.back,
      tooltip: 'Back',
      filled: filled,
      iconSize: iconSize,
      onPressed: () {
        HapticFeedback.lightImpact();
        if (onPressed != null) {
          onPressed!();
        } else {
          Navigator.of(context).pop();
        }
      },
    );
  }
}

/// Step progress: the current step is a 24 px accent pill, the others are
/// 6 px dots. Animates when the step changes.
class SetupStepDots extends StatelessWidget {
  final int step;
  final int total;

  const SetupStepDots({super.key, required this.step, this.total = 3});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: 'Step $step of $total',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= total; i++)
            AnimatedContainer(
              duration: AppDurations.normal,
              curve: Curves.easeOutCubic,
              width: i == step ? 24 : 6,
              height: 6,
              margin: EdgeInsets.only(left: i == 1 ? 0 : AppSpacing.sm - 2),
              decoration: BoxDecoration(
                color: i == step ? c.accent : c.borderStrong,
                borderRadius: AppRadius.pillAll,
              ),
            ),
        ],
      ),
    );
  }
}

/// What the user has chosen so far. Null means "not yet".
class SetupSummary {
  final String? topic;
  final String? stance;
  final String? difficulty;

  /// Display string, e.g. "10 min", "10:00" or "Off".
  final String? timer;

  const SetupSummary({this.topic, this.stance, this.difficulty, this.timer});
}

/// Frosted side panel listing the choices made so far. Values that are not
/// chosen yet read as a hint-coloured dash. Updates live with the screen.
class SetupSummaryPanel extends StatelessWidget {
  final SetupSummary summary;

  const SetupSummaryPanel({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = summary;

    final rows = <Widget>[
      _SummaryRow(
        icon: AppIcons.topic,
        label: 'Topic',
        subtitle: s.topic,
        valueKey: s.topic,
      ),
      _SummaryRow(
        icon: AppIcons.forStance(s.stance ?? 'for'),
        label: 'Stance',
        trailing: s.stance == null ? null : AppPill.stance(s.stance!),
        valueKey: s.stance,
      ),
      _SummaryRow(
        icon: AppIcons.forDifficulty(s.difficulty ?? ''),
        label: 'Difficulty',
        trailing:
            s.difficulty == null ? null : AppPill.difficulty(s.difficulty!),
        valueKey: s.difficulty,
      ),
      _SummaryRow(
        icon: AppIcons.timer,
        label: 'Timer',
        trailing: s.timer == null
            ? null
            : Text(s.timer!, style: context.mono(size: 14)),
        valueKey: s.timer,
      ),
    ];

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.lg, 0, AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: AppOverline('Your debate'),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: c.border,
                indent: AppSpacing.lg,
                endIndent: AppSpacing.lg,
              ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final String? valueKey;

  const _SummaryRow({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.valueKey,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final empty = subtitle == null && trailing == null;

    Widget? value = trailing;
    if (empty) {
      value = Text(
        '—',
        style: context.text.bodyMedium?.copyWith(color: c.textHint),
      );
    }

    return AppListRow(
      showChevron: false,
      title: label,
      subtitle: subtitle,
      leading: AppIconTile(
        icon: icon,
        size: 36,
        iconSize: 18,
        color: empty ? c.textHint : c.textSecondary,
        background: c.surfaceRaised,
      ),
      trailing: value == null
          ? null
          : AnimatedSwitcher(
              duration: AppDurations.fast,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              child: KeyedSubtree(
                key: ValueKey<String?>(valueKey),
                child: value,
              ),
            ),
    );
  }
}

/// Page skeleton for one setup step.
///
/// * compact (< 600): plain back arrow + [AppStepBar], then [compactChildren]
///   (the phone composition, DESIGN.md §10: eyebrow, motion, rows, chips) in a
///   scroll view, CTA bottom-anchored above the keyboard. No summary panel,
///   no header block; each screen owns its phone content. Falls back to the
///   header + [children] when [compactChildren] is null.
/// * medium (600–899): single 560 px column, CTA inline after the content
/// * expanded (≥ 900): content column (max 620) left, sticky [SetupSummaryPanel]
///   (300 px glass) right; CTA inline
///
/// Header blocks and [children] enter as one stagger. Each child is one
/// section; the scaffold inserts the section gap between them.
class SetupScaffold extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String title;
  final String subtitle;
  final List<Widget> children;

  /// Phone-only content (< 600). Blocks are laid out as given, with no gap
  /// inserted between them; put spacing inside the blocks.
  final List<Widget>? compactChildren;
  final Widget cta;
  final SetupSummary summary;
  final VoidCallback? onBack;

  const SetupScaffold({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
    required this.children,
    required this.cta,
    required this.summary,
    this.compactChildren,
    this.totalSteps = 3,
    this.onBack,
  });

  static const double _contentMax = 620;
  static const double _panelWidth = 300;

  List<Widget> _blocks(BuildContext context, {required bool withCta}) {
    final c = context.colors;
    final header = <Widget>[
      Row(
        children: [
          SetupBackButton(onPressed: onBack),
          const Spacer(),
          SetupStepDots(step: step, total: totalSteps),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppOverline('Step $step of $totalSteps'),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: context.text.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: context.text.bodyMedium?.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    ];

    return [
      for (final block in [...header, ...children])
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          child: block,
        ),
      if (withCta) cta,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final gutter = context.pageGutter;

    if (context.isCompact) {
      final phone = compactChildren;
      final blocks = phone ?? _blocks(context, withCta: false);
      return Scaffold(
        body: AppPage(
          width: AppPageWidth.form,
          scroll: false,
          bottomSafe: false,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (phone != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    gutter - AppSpacing.md,
                    AppSpacing.sm,
                    gutter,
                    AppSpacing.sm,
                  ),
                  child: AppReveal(
                    child: Row(
                      children: [
                        SetupBackButton(
                          onPressed: onBack,
                          filled: false,
                          iconSize: 24,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Semantics(
                            label: 'Step $step of $totalSteps',
                            child: AppStepBar(step: step, total: totalSteps),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    gutter,
                    phone != null ? AppSpacing.xl : AppSpacing.lg,
                    gutter,
                    AppSpacing.sm,
                  ),
                  child: StaggeredColumn(
                    startIndex: phone != null ? 1 : 0,
                    children: blocks,
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    gutter,
                    AppSpacing.md,
                    gutter,
                    AppSpacing.lg,
                  ),
                  child: AppReveal(index: blocks.length + 1, child: cta),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (context.isMedium) {
      return Scaffold(
        body: AppPage(
          width: AppPageWidth.form,
          child: StaggeredColumn(children: _blocks(context, withCta: true)),
        ),
      );
    }

    // Expanded / large: two columns, the summary stays put while the
    // content scrolls.
    return Scaffold(
      body: AppPage(
        width: AppPageWidth.content,
        scroll: false,
        padding: EdgeInsets.symmetric(horizontal: gutter),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  top: AppSpacing.xxl,
                  bottom: AppSpacing.xxxl,
                ),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _contentMax),
                    child: StaggeredColumn(
                      children: _blocks(context, withCta: true),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xxxl),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxl),
              child: SizedBox(
                width: _panelWidth,
                child: AppReveal(
                  index: 3,
                  child: SetupSummaryPanel(summary: summary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Radio mark: a 20 px ring in `borderStrong` that fills with the accent
/// (and shows an `onAccent` dot) when selected.
class SetupRadioMark extends StatelessWidget {
  final bool selected;

  /// Fill colour when selected; defaults to the accent.
  final Color? color;

  const SetupRadioMark({super.key, required this.selected, this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fill = color ?? c.accent;
    return AnimatedContainer(
      duration: AppDurations.fast,
      curve: Curves.easeOutCubic,
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? fill : fill.withValues(alpha: 0),
        border: Border.all(
          color: selected ? fill : c.borderStrong,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: Curves.easeOutCubic,
        width: selected ? 7 : 0,
        height: selected ? 7 : 0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.onAccent,
        ),
      ),
    );
  }
}

/// One selectable opponent-strength row.
///
/// * phones: a plain hairline row for [AppRows] (title w800, one-line
///   description, trailing [SetupRadioMark]); no tile
/// * wide: an [AppListGroup] row with the duotone tile
class SetupDifficultyRow extends StatelessWidget {
  /// 'easy' | 'medium' | 'hard' (any case).
  final String name;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const SetupDifficultyRow({
    super.key,
    required this.name,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (Color fg, Color bg) = switch (name.trim().toLowerCase()) {
      'easy' => (c.positiveText, c.positiveBg),
      'hard' => (c.negativeText, c.negativeBg),
      _ => (c.warningText, c.warningBg),
    };
    final title = name.isEmpty
        ? name
        : name[0].toUpperCase() + name.substring(1).toLowerCase();

    if (context.isCompact) {
      return Semantics(
        selected: selected,
        child: Pressable(
          onTap: onTap,
          pressedScale: 0.995,
          semanticLabel: title,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: AppDurations.fast,
                        style: context.text.titleSmall!.copyWith(
                          fontWeight: FontWeight.w800,
                          color: selected ? c.textPrimary : c.textSecondary,
                        ),
                        child: Text(title, maxLines: 1),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        description,
                        style: context.text.bodySmall?.copyWith(
                          color: c.textHint,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                SetupRadioMark(selected: selected),
              ],
            ),
          ),
        ),
      );
    }

    return Semantics(
      selected: selected,
      child: AppListRow(
        title: title,
        subtitle: description,
        onTap: onTap,
        showChevron: false,
        padding: const EdgeInsets.all(AppSpacing.lg),
        leading: AppIconTile(
          icon: AppIcons.forDifficulty(name, duotone: true),
          color: fg,
          background: bg,
        ),
        trailing: SetupRadioMark(selected: selected),
      ),
    );
  }
}

/// A 38 px text chip for the phone setup flow (clock lengths, formats):
/// 1 px `borderStrong` hairline, radius 10, `labelLarge` muted; selected
/// gets the accent hairline, `accentSoft` fill and `textPrimary` label.
/// Put it in an `Expanded` so a row of chips shares the width evenly.
class SetupChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Render the label in the mono face (numbers).
  final bool mono;

  const SetupChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = selected ? c.textPrimary : c.textSecondary;
    final style = mono
        ? context.mono(size: 14, color: fg)
        : context.text.labelLarge!.copyWith(color: fg);
    return Semantics(
      selected: selected,
      button: true,
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.97,
        semanticLabel: label,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: Curves.easeOutCubic,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? c.accentSoft : c.accentSoft.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? c.accent : c.borderStrong,
              width: 1,
            ),
          ),
          child: AnimatedDefaultTextStyle(
            duration: AppDurations.fast,
            style: style,
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ),
    );
  }
}

/// Display name of a mode for the phone eyebrow ("Casual", "Ranked",
/// "Learning").
extension SetupModeLabel on DebateMode {
  String get setupLabel => switch (this) {
        DebateMode.casual => 'Casual',
        DebateMode.ranked => 'Ranked',
        DebateMode.learning => 'Learning',
      };
}
