import 'package:flutter/material.dart';

import '../models/debate_mode.dart';
import '../ui/ui.dart';
import '../widgets/setup_back_button.dart';
import '../widgets/stance_button.dart';
import 'chat_screen.dart';
import 'debate_setup_screen.dart';
import 'ranked_setup_screen.dart';

class StanceScreen extends StatefulWidget {
  final String topic;
  final DebateMode mode;

  /// Home's "Start today's debate": after the side is picked, go straight
  /// into a preset casual match (Medium opponent, 5-minute clock) instead of
  /// the setup screen.
  final bool quickMatch;

  const StanceScreen({
    super.key,
    required this.topic,
    required this.mode,
    this.quickMatch = false,
  });

  @override
  State<StanceScreen> createState() => _StanceScreenState();
}

class _StanceScreenState extends State<StanceScreen> {
  bool _isFor = true;

  String get _stance => _isFor ? 'For' : 'Against';

  String get _ctaLabel => widget.quickMatch
      ? 'Start debate'
      : switch (widget.mode) {
          DebateMode.learning => 'Start learning session',
          DebateMode.ranked => 'Continue to ranked setup',
          DebateMode.casual => 'Continue',
        };

  void _select(bool isFor) {
    if (_isFor == isFor) return;
    setState(() => _isFor = isFor);
  }

  void _nextStep() {
    if (widget.quickMatch) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            topic: widget.topic,
            stance: _isFor ? 'For' : 'Against',
            difficulty: 'Medium',
            timerMinutes: 5,
            mode: DebateMode.casual,
          ),
        ),
      );
      return;
    }
    if (widget.mode == DebateMode.learning) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            topic: widget.topic,
            stance: _isFor ? 'For' : 'Against',
            difficulty: 'Adaptable', // Default for Learning Mode
            timerMinutes: null, // No timer for learning
            mode: widget.mode,
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => widget.mode == DebateMode.ranked
            ? RankedSetupScreen(
                topic: widget.topic,
                stance: _isFor ? 'For' : 'Against',
              )
            : DebateSetupScreen(
                topic: widget.topic,
                stance: _isFor ? 'For' : 'Against',
                mode: widget.mode,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final forCard = StanceButton(
      label: 'For',
      description: 'You argue in favour',
      isSelected: _isFor,
      onTap: () => _select(true),
    );
    final againstCard = StanceButton(
      label: 'Against',
      description: 'You argue against',
      isSelected: !_isFor,
      onTap: () => _select(false),
    );

    return SetupScaffold(
      step: 2,
      title: 'Choose your side',
      subtitle: 'You hold this position for the whole debate.',
      summary: SetupSummary(topic: widget.topic, stance: _stance),
      cta: AppButton.primary(
        label: _ctaLabel,
        trailingIcon: AppIcons.forward,
        onPressed: _nextStep,
      ),
      compactChildren: _phoneBlocks(context),
      children: [
        _TopicCard(topic: widget.topic),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: forCard),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: againstCard),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: Text(
                'ClashBot takes the other side.',
                style: context.text.labelSmall,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Phone composition (DESIGN.md §10): eyebrow, the motion as the headline,
  /// one line of guidance, and the split For / Against choice.
  List<Widget> _phoneBlocks(BuildContext context) {
    final c = context.colors;
    return [
      AppSectionLabel(
        widget.mode.setupLabel,
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      ),
      Text(widget.topic, style: context.text.headlineMedium),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'Which side will you argue? ClashBot argues the opposite.',
        style: context.text.bodyMedium?.copyWith(color: c.textSecondary),
      ),
      const SizedBox(height: AppSpacing.xxl),
      Row(
        children: [
          Expanded(
            child: _SideButton(
              label: 'For',
              caption: 'I agree with it',
              positive: true,
              selected: _isFor,
              onTap: () => _select(true),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _SideButton(
              label: 'Against',
              caption: 'I disagree with it',
              positive: false,
              selected: !_isFor,
              onTap: () => _select(false),
            ),
          ),
        ],
      ),
    ];
  }
}

/// One side of the phone's For / Against choice: 72 px, surface fill with a
/// `borderStrong` hairline, radius 16; the selected side takes a 1.5 px
/// border in its tone and the tone's soft fill. Same design as Home.
class _SideButton extends StatelessWidget {
  final String label;
  final String caption;
  final bool positive;
  final bool selected;
  final VoidCallback onTap;

  const _SideButton({
    required this.label,
    required this.caption,
    required this.positive,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tone = positive ? c.positiveText : c.negativeText;
    final toneBg = positive ? c.positiveBg : c.negativeBg;
    return Semantics(
      selected: selected,
      button: true,
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.98,
        semanticLabel: '$label: $caption',
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: Curves.easeOutCubic,
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: selected ? toneBg : c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? tone : c.borderStrong,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: tone,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                caption,
                style: context.text.labelSmall?.copyWith(
                  color: selected ? c.textPrimary : c.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quiet recap of the chosen topic (wide layouts).
class _TopicCard extends StatelessWidget {
  final String topic;
  const _TopicCard({required this.topic});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      level: AppCardLevel.raised,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          AppIconTile(
            icon: AppIcons.topic,
            size: 36,
            iconSize: 18,
            color: c.textSecondary,
            background: c.surface,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              topic,
              style: context.text.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
