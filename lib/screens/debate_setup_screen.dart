import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/responsive_layout.dart';
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
    HapticFeedback.selectionClick();
    setState(() => _difficulty = name);
  }

  void _toggleTimer(bool on) {
    HapticFeedback.selectionClick();
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
        child: isDesktop ? _buildDesktop() : _buildColumn(),
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
                child: _buildColumn(),
              ),
            ),
            const SizedBox(width: AppSpacing.xxxl),
            Flexible(
              flex: 3,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: const _RulesPanel(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumn() {
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
                const AppOverline('Step 3 of 3'),
                const SizedBox(height: AppSpacing.sm),
                Text('Set the terms', style: context.text.headlineMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _isLearning
                      ? 'Choose how hard your coach pushes back.'
                      : 'Choose how hard the opponent pushes and whether the clock runs.',
                  style: context.text.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                _SummaryCard(topic: widget.topic, stance: widget.stance),
                const SizedBox(height: AppSpacing.xxl),
                const AppSectionHeader(title: 'Opponent strength'),
                AppListGroup(
                  children: [
                    for (final d in _difficulties)
                      _DifficultyRow(
                        name: d.name,
                        description: d.desc,
                        selected: _difficulty == d.name,
                        onTap: () => _selectDifficulty(d.name),
                      ),
                  ],
                ),
                if (!_isLearning) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  const AppSectionHeader(title: 'Timer'),
                  _TimerCard(
                    enabled: _timerEnabled,
                    minutes: _timerMinutes ?? 10,
                    onToggle: _toggleTimer,
                    onChanged: (m) => setState(() => _timerMinutes = m),
                  ),
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
            label: _isLearning ? 'Start learning session' : 'Start debate',
            icon: _isLearning ? AppIcons.learning : AppIcons.play,
            onPressed: _startDebate,
          ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(AppIcons.topic, size: 20, color: c.textSecondary),
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

/// One selectable difficulty row inside an [AppListGroup].
class _DifficultyRow extends StatelessWidget {
  final String name;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _DifficultyRow({
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
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.99,
        semanticLabel: title,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              AppIconTile(
                icon: AppIcons.forDifficulty(name, duotone: true),
                color: fg,
                background: bg,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.titleSmall),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      description,
                      style: context.text.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _RadioMark(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

/// Radio-like trailing indicator: filled check when selected, outline otherwise.
class _RadioMark extends StatelessWidget {
  final bool selected;
  const _RadioMark({required this.selected});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: 22,
      height: 22,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        child: selected
            ? Icon(
                AppIcons.checkCircle,
                key: const ValueKey('on'),
                size: 22,
                color: c.accent,
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

/// Switch row plus, when on, a slider with the minutes in the mono face.
class _TimerCard extends StatelessWidget {
  final bool enabled;
  final int minutes;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onChanged;

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
        duration: const Duration(milliseconds: 180),
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
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('$minutes', style: context.mono(size: 28)),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    minutes == 1 ? 'minute' : 'minutes',
                    style: context.text.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Slider(
                value: minutes.toDouble(),
                min: 1,
                max: 60,
                divisions: 59,
                label: '$minutes min',
                onChanged: (v) => onChanged(v.round()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Desktop side panel: ground rules.
class _RulesPanel extends StatelessWidget {
  const _RulesPanel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.sm, AppSpacing.gutter, 0),
      child: AppReveal(
        index: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppOverline('Ground rules'),
            const SizedBox(height: AppSpacing.md),
            const AppListGroup(
              children: [
                _RuleRow(
                  icon: AppIcons.shield,
                  title: 'Stay civil',
                  description: 'Argue the facts, not the person.',
                ),
                _RuleRow(
                  icon: AppIcons.timer,
                  title: 'Use your time',
                  description: 'Think before you type; the clock keeps going.',
                ),
                _RuleRow(
                  icon: AppIcons.ai,
                  title: 'The opponent adapts',
                  description: 'ClashBot matches the strength you pick and challenges your stance.',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _RuleRow({
    required this.icon,
    required this.title,
    required this.description,
  });

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
                Text(description, style: context.text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
