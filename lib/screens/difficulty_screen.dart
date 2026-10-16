import 'package:flutter/material.dart';

import '../models/debate_mode.dart';
import '../ui/ui.dart';
import '../widgets/setup_back_button.dart';
import 'chat_screen.dart';

/// Standalone opponent-strength picker for a casual debate. Replaces itself
/// with the chat once a strength is confirmed.
class DifficultyScreen extends StatefulWidget {
  final String topic;
  final String stance;

  const DifficultyScreen({
    super.key,
    required this.topic,
    required this.stance,
  });

  @override
  State<DifficultyScreen> createState() => _DifficultyScreenState();
}

class _DifficultyScreenState extends State<DifficultyScreen> {
  static const List<({String value, String desc})> _difficulties = [
    (value: 'easy', desc: 'Gentle, everyday examples.'),
    (value: 'medium', desc: 'Evidence-driven, pushes back.'),
    (value: 'hard', desc: 'Dissects your premises. No mercy.'),
  ];

  String _difficulty = 'medium';

  void _select(String value) {
    if (_difficulty == value) return;
    setState(() => _difficulty = value);
  }

  void _selectDifficulty(String difficulty) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          topic: widget.topic,
          stance: widget.stance,
          difficulty: difficulty,
          mode: DebateMode.casual,
        ),
      ),
    );
  }

  List<Widget> get _rows => [
        for (final d in _difficulties)
          SetupDifficultyRow(
            name: d.value,
            description: d.desc,
            selected: _difficulty == d.value,
            onTap: () => _select(d.value),
          ),
      ];

  @override
  Widget build(BuildContext context) {
    return SetupScaffold(
      step: 3,
      title: 'Choose your opponent',
      subtitle: 'Pick the strength that matches your confidence today.',
      summary: SetupSummary(
        topic: widget.topic,
        stance: widget.stance,
        difficulty: _difficulty,
      ),
      cta: AppButton.primary(
        label: 'Start debate',
        icon: AppIcons.play,
        onPressed: () => _selectDifficulty(_difficulty),
      ),
      compactChildren: [
        AppSectionLabel(
          '${DebateMode.casual.setupLabel} · ${widget.stance}',
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        ),
        Text(
          widget.topic,
          style: context.text.titleLarge,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const AppSectionLabel('Opponent'),
        AppRows(children: _rows),
      ],
      children: [
        _SummaryCard(topic: widget.topic, stance: widget.stance),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppSectionHeader(title: 'Opponent strength'),
            AppListGroup(children: _rows),
          ],
        ),
      ],
    );
  }
}

/// Topic and stance recap (wide layouts).
class _SummaryCard extends StatelessWidget {
  final String topic;
  final String stance;
  const _SummaryCard({required this.topic, required this.stance});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      level: AppCardLevel.raised,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, thickness: 1, color: c.border),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text('Your stance', style: context.text.bodySmall),
              const Spacer(),
              AppPill.stance(stance),
            ],
          ),
        ],
      ),
    );
  }
}
