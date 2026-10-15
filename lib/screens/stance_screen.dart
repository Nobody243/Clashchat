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

  const StanceScreen({super.key, required this.topic, required this.mode});

  @override
  State<StanceScreen> createState() => _StanceScreenState();
}

class _StanceScreenState extends State<StanceScreen> {
  bool _isFor = true;

  String get _stance => _isFor ? 'For' : 'Against';

  String get _ctaLabel => switch (widget.mode) {
        DebateMode.learning => 'Start learning session',
        DebateMode.ranked => 'Continue to ranked setup',
        DebateMode.casual => 'Continue',
      };

  void _select(bool isFor) {
    if (_isFor == isFor) return;
    setState(() => _isFor = isFor);
  }

  void _nextStep() {
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
    final sideBySide = !context.isCompact;

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
      children: [
        _TopicCard(topic: widget.topic),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sideBySide)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: forCard),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: againstCard),
                  ],
                ),
              )
            else ...[
              forCard,
              const SizedBox(height: AppSpacing.md),
              againstCard,
            ],
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
}

/// Quiet recap of the chosen topic.
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
