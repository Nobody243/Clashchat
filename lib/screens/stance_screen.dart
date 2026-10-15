import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/responsive_layout.dart';
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

  String get _ctaLabel => switch (widget.mode) {
        DebateMode.learning => 'Start learning session',
        DebateMode.ranked => 'Continue to ranked setup',
        DebateMode.casual => 'Continue',
      };

  void _select(bool isFor) {
    if (_isFor == isFor) return;
    HapticFeedback.selectionClick();
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
    final isDesktop =
        MediaQuery.sizeOf(context).width > ResponsiveLayout.desktopBreakpoint;

    return Scaffold(
      appBar: AppBar(
        leading: const SetupBackButton(),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: isDesktop ? _buildDesktop() : _buildColumn(sideBySide: false),
      ),
    );
  }

  Widget _buildDesktop() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              flex: 5,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: _buildColumn(sideBySide: true),
              ),
            ),
            const SizedBox(width: AppSpacing.xxxl),
            Flexible(
              flex: 3,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: _TipsPanel(isFor: _isFor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumn({required bool sideBySide}) {
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

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.sm,
              AppSpacing.gutter,
              AppSpacing.xxl,
            ),
            child: StaggeredColumn(
              children: [
                const AppOverline('Step 2 of 3'),
                const SizedBox(height: AppSpacing.sm),
                Text('Choose your side', style: context.text.headlineMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'You hold this position for the whole debate.',
                  style: context.text.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                _TopicCard(topic: widget.topic),
                const SizedBox(height: AppSpacing.lg),
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
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.md,
            AppSpacing.gutter,
            AppSpacing.gutter,
          ),
          child: AppButton.primary(
            label: _ctaLabel,
            trailingIcon: AppIcons.forward,
            onPressed: _nextStep,
          ),
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
          Icon(AppIcons.topic, size: 20, color: c.textSecondary),
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

/// Desktop side panel with three short tips, the first following the stance.
class _TipsPanel extends StatelessWidget {
  final bool isFor;
  const _TipsPanel({required this.isFor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.sm, AppSpacing.gutter, 0),
      child: AppReveal(
        index: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppOverline('Debate tips'),
            const SizedBox(height: AppSpacing.md),
            AppListGroup(
              children: [
                _TipRow(
                  icon: AppIcons.coachTip,
                  title: isFor ? 'Arguing for' : 'Arguing against',
                  tip: isFor
                      ? 'Lead with benefits, back claims with evidence and offer solutions.'
                      : 'Question assumptions, raise counterpoints and name the risks.',
                ),
                const _TipRow(
                  icon: AppIcons.document,
                  title: 'Structure',
                  tip: 'A clear thesis, two or three supported points, a strong close.',
                ),
                const _TipRow(
                  icon: AppIcons.timer,
                  title: 'Pace',
                  tip: 'Think before you type. Quality beats volume.',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String tip;

  const _TipRow({required this.icon, required this.title, required this.tip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconTile(icon: icon, size: 40, iconSize: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(tip, style: context.text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
