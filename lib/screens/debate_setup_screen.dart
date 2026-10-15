import 'package:flutter/material.dart';

import '../models/debate_mode.dart';
import '../ui/ui.dart';
import '../widgets/setup_back_button.dart';
import 'chat_screen.dart';

class DebateSetupScreen extends StatefulWidget {
  final String topic;
  final String stance;
  final DebateMode mode;

  const DebateSetupScreen({
    super.key,
    required this.topic,
    required this.stance,
    required this.mode,
  });

  @override
  State<DebateSetupScreen> createState() => _DebateSetupScreenState();
}

class _DebateSetupScreenState extends State<DebateSetupScreen> {
  String _difficulty = 'Medium';
  int? _timerMinutes; // null = no timer
  bool _timerEnabled = false;

  static const List<({String name, String desc})> _difficulties = [
    (name: 'Easy', desc: 'Gentle and encouraging'),
    (name: 'Medium', desc: 'Pushes back moderately'),
    (name: 'Hard', desc: 'Aggressive and sharp'),
  ];

  bool get _isLearning => widget.mode == DebateMode.learning;

  void _selectDifficulty(String name) {
    if (_difficulty == name) return;
    setState(() => _difficulty = name);
  }

  void _toggleTimer(bool on) {
    setState(() {
      _timerEnabled = on;
      if (on) _timerMinutes = 10; // default
    });
  }

  void _startDebate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          topic: widget.topic,
          stance: widget.stance,
          difficulty: _difficulty,
          timerMinutes: _timerEnabled ? _timerMinutes : null,
          mode: widget.mode,
        ),
      ),
    );
  }

  String? get _timerSummary {
    if (_isLearning) return null;
    if (!_timerEnabled) return 'Off';
    return '${_timerMinutes ?? 10} min';
  }

  @override
  Widget build(BuildContext context) {
    return SetupScaffold(
      step: 3,
      title: 'Set the terms',
      subtitle: _isLearning
          ? 'Choose how hard your coach pushes back.'
          : 'Choose how hard the opponent pushes and whether the clock runs.',
      summary: SetupSummary(
        topic: widget.topic,
        stance: widget.stance,
        difficulty: _difficulty,
        timer: _timerSummary,
      ),
      cta: AppButton.primary(
        label: _isLearning ? 'Start learning session' : 'Start debate',
        icon: _isLearning ? AppIcons.learning : AppIcons.play,
        onPressed: _startDebate,
      ),
      children: [
        _SummaryCard(topic: widget.topic, stance: widget.stance),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppSectionHeader(title: 'Opponent strength'),
            AppListGroup(
              children: [
                for (final d in _difficulties)
                  SetupDifficultyRow(
                    name: d.name,
                    description: d.desc,
                    selected: _difficulty == d.name,
                    onTap: () => _selectDifficulty(d.name),
                  ),
              ],
            ),
          ],
        ),
        if (!_isLearning)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppSectionHeader(title: 'Timer'),
              _TimerCard(
                enabled: _timerEnabled,
                minutes: _timerMinutes ?? 10,
                onToggle: _toggleTimer,
                onChanged: (m) => setState(() => _timerMinutes = m),
              ),
            ],
          ),
      ],
    );
  }
}

/// Topic and stance recap.
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

/// Switch row plus, when on, the minutes in the mono face, a 1–60 slider
/// and three quick picks.
class _TimerCard extends StatelessWidget {
  final bool enabled;
  final int minutes;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onChanged;

  static const List<int> _quickPicks = [5, 10, 15];

  const _TimerCard({
    required this.enabled,
    required this.minutes,
    required this.onToggle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: AnimatedSize(
        duration: AppDurations.normal,
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIconTile(
                  icon: AppIcons.timer,
                  color: enabled ? c.accent : c.textSecondary,
                  background: enabled ? c.accentSoft : c.surfaceRaised,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Time limit', style: context.text.titleSmall),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        enabled
                            ? 'The debate ends when the clock runs out'
                            : 'No time limit',
                        style: context.text.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Switch(value: enabled, onChanged: onToggle),
              ],
            ),
            if (enabled) ...[
              const SizedBox(height: AppSpacing.lg),
              Divider(height: 1, thickness: 1, color: c.border),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('$minutes', style: context.mono(size: 32)),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'min',
                    style: context.text.bodyMedium?.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  for (final m in _quickPicks) ...[
                    Pressable(
                      onTap: () => onChanged(m),
                      pressedScale: 0.95,
                      semanticLabel: '$m minutes',
                      child: AppPill(
                        label: '$m',
                        mono: true,
                        tone: minutes == m
                            ? AppPillTone.accent
                            : AppPillTone.neutral,
                      ),
                    ),
                    if (m != _quickPicks.last)
                      const SizedBox(width: AppSpacing.sm),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                ),
                child: Slider(
                  value: minutes.toDouble(),
                  min: 1,
                  max: 60,
                  divisions: 59,
                  label: '$minutes min',
                  onChanged: (v) => onChanged(v.round()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
