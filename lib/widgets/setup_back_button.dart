import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ui/ui.dart';

/// Chrome shared by the three-step debate setup flow (topic, stance, terms).
///
/// * [SetupBackButton]   back affordance (top-left of every step)
/// * [SetupStepDots]     "1 of 3" progress pills
/// * [SetupScaffold]     the page skeleton: backdrop, header, staggered
///                       content, bottom-anchored CTA on phones, sticky
///                       summary panel on wide screens
/// * [SetupSummaryPanel] what has been chosen so far
/// * [SetupRadioMark] / [SetupDifficultyRow] single-choice rows
///
/// Everything here composes the kit in `lib/ui`; nothing invents a style.

/// Back affordance for the setup flow. Pops the route unless [onPressed]
/// is given. Filled by default now that it floats on the page rather than
/// sitting in an app bar.
class SetupBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool filled;

  const SetupBackButton({super.key, this.onPressed, this.filled = true});

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: AppIcons.back,
      tooltip: 'Back',
      filled: filled,
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
/// * compact (< 600): single column, CTA bottom-anchored above the keyboard
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
      final blocks = _blocks(context, withCta: false);
      return Scaffold(
        body: AppPage(
          width: AppPageWidth.form,
          scroll: false,
          bottomSafe: false,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    gutter,
                    AppSpacing.lg,
                    gutter,
                    AppSpacing.sm,
                  ),
                  child: StaggeredColumn(children: blocks),
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
                  child: AppReveal(index: blocks.length, child: cta),
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

/// Radio-like trailing indicator: accent check when selected, an 18 px
/// outline circle otherwise.
class SetupRadioMark extends StatelessWidget {
  final bool selected;

  /// Colour of the check; defaults to the accent.
  final Color? color;

  const SetupRadioMark({super.key, required this.selected, this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: 22,
      height: 22,
      child: AnimatedSwitcher(
        duration: AppDurations.fast,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        child: selected
            ? Icon(
                AppIcons.checkCircle,
                key: const ValueKey('on'),
                size: 22,
                color: color ?? c.accent,
              )
            : Center(
                key: const ValueKey('off'),
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: c.borderStrong, width: 1.5),
                  ),
                ),
              ),
      ),
    );
  }
}

/// One selectable opponent-strength row for an [AppListGroup]: duotone
/// tile, title, one-line description, trailing radio.
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
