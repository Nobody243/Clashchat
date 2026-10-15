import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/responsive_layout.dart';
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
    (value: 'easy', desc: 'Simple language, makes logical slips'),
    (value: 'medium', desc: 'Clear logic and fair arguments'),
    (value: 'hard', desc: 'Advanced reasoning, sharp rebuttals'),
  ];

  String _difficulty = 'medium';

  void _select(String value) {
    if (_difficulty == value) return;
    HapticFeedback.selectionClick();
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

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width > ResponsiveLayout.desktopBreakpoint;

    final column = _buildColumn();
    return Scaffold(
      appBar: AppBar(
        leading: const SetupBackButton(),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: isDesktop
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: column,
                ),
              )
            : column,
      ),
    );
  }

  Widget _buildColumn() {
    final c = context.colors;
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
                Text('Choose your opponent',
                    style: context.text.headlineMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Pick the strength that matches your confidence today.',
                  style: context.text.bodyMedium?.copyWith(
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                AppCard(
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
                            child: Icon(
                              AppIcons.topic,
                              size: 20,
                              color: c.textSecondary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              widget.topic,
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
                          AppPill.stance(widget.stance),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                const AppSectionHeader(title: 'Opponent strength'),
                AppListGroup(
                  children: [
                    for (final d in _difficulties)
                      _DifficultyRow(
                        name: d.value,
                        description: d.desc,
                        selected: _difficulty == d.value,
                        onTap: () => _select(d.value),
                      ),
                  ],
                ),
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
            label: 'Start debate',
            icon: AppIcons.play,
            onPressed: () => _selectDifficulty(_difficulty),
          ),
        ),
      ],
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
