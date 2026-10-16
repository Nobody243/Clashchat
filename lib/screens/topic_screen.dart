import 'package:flutter/material.dart';

import '../models/debate_mode.dart';
import '../ui/ui.dart';
import '../widgets/setup_back_button.dart';
import 'stance_screen.dart';

class TopicScreen extends StatefulWidget {
  final DebateMode mode;
  const TopicScreen({super.key, required this.mode});

  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  static const List<({String label, IconData icon})> _categories = [
    (label: 'Technology', icon: AppIcons.technology),
    (label: 'Education', icon: AppIcons.education),
    (label: 'Society', icon: AppIcons.society),
    (label: 'Health', icon: AppIcons.health),
    (label: 'Politics', icon: AppIcons.politics),
    (label: 'Environment', icon: AppIcons.environment),
    (label: 'Economy', icon: AppIcons.economy),
    (label: 'Culture', icon: AppIcons.culture),
  ];

  String? _selectedCategory;
  final _customTopicCtrl = TextEditingController();

  bool get _canContinue =>
      _selectedCategory != null || _customTopicCtrl.text.trim().isNotEmpty;

  /// What will be carried forward if the user continues now.
  String? get _topicPreview {
    final custom = _customTopicCtrl.text.trim();
    if (custom.isNotEmpty) return custom;
    return _selectedCategory;
  }

  @override
  void dispose() {
    _customTopicCtrl.dispose();
    super.dispose();
  }

  void _toggleCategory(String label) {
    setState(() {
      final wasSelected = _selectedCategory == label;
      _selectedCategory = wasSelected ? null : label;
      if (!wasSelected) _customTopicCtrl.clear();
    });
  }

  void _nextStep() {
    final topic = _customTopicCtrl.text.trim().isNotEmpty
        ? _customTopicCtrl.text.trim()
        : _selectedCategory;

    if (topic == null || topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick a category or write your own topic.'),
        ),
      );
      return;
    }

    // Check if topic contains at least one letter
    if (!RegExp(r'[a-zA-Z]').hasMatch(topic)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A topic needs at least one letter.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StanceScreen(topic: topic, mode: widget.mode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final columns = context.isCompact
        ? 2
        : context.isMedium
            ? 3
            : 4;

    return SetupScaffold(
      step: 1,
      title: 'Pick a topic',
      subtitle: 'Choose a category or write the motion you want to argue.',
      summary: SetupSummary(topic: _topicPreview),
      cta: AppButton.primary(
        label: 'Continue',
        trailingIcon: AppIcons.forward,
        onPressed: _canContinue ? _nextStep : null,
      ),
      compactChildren: _phoneBlocks(context),
      children: [
        _buildGrid(columns),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader(title: 'Or write your own'),
            _customField(hint: 'e.g. Remote work makes teams more productive'),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: Text(
                'Short, debatable, specific',
                style: context.text.labelSmall,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Phone composition (DESIGN.md §10): eyebrow, question, hint, the eight
  /// categories as plain hairline rows with a trailing check, then the
  /// free-text field. No cards, no icon tiles.
  List<Widget> _phoneBlocks(BuildContext context) {
    final c = context.colors;
    return [
      AppSectionLabel(
        widget.mode.setupLabel,
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      ),
      Text("What's the motion?", style: context.text.headlineMedium),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'Pick a category or write your own.',
        style: context.text.bodyMedium?.copyWith(color: c.textSecondary),
      ),
      const SizedBox(height: AppSpacing.xxl),
      AppRows(
        children: [
          for (final cat in _categories)
            AppPlainRow(
              title: cat.label,
              titleColor: _selectedCategory == cat.label
                  ? c.textPrimary
                  : c.textSecondary,
              trailing: _selectedCategory == cat.label
                  ? Icon(AppIcons.check, size: 20, color: c.accent)
                  : null,
              onTap: () => _toggleCategory(cat.label),
            ),
        ],
      ),
      const AppSectionLabel('Or write your own'),
      _customField(hint: 'A short, debatable, specific claim'),
    ];
  }

  Widget _customField({required String hint}) {
    return AppTextField(
      controller: _customTopicCtrl,
      hint: hint,
      prefixIcon: context.isCompact ? null : AppIcons.topic,
      minLines: 1,
      maxLines: 2,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.done,
      onChanged: (_) => setState(() => _selectedCategory = null),
      onSubmitted: (_) {
        if (_canContinue) _nextStep();
      },
    );
  }

  Widget _buildGrid(int columns) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        mainAxisExtent: 116,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, i) {
        final cat = _categories[i];
        return _CategoryCard(
          label: cat.label,
          icon: cat.icon,
          selected: _selectedCategory == cat.label,
          onTap: () => _toggleCategory(cat.label),
        );
      },
    );
  }
}

/// One category (wide layouts): icon tile top-left, label bottom-left.
/// Selected cards get the accent hairline from [AppCard] and tint their tile.
class _CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      child: AppCard(
        onTap: onTap,
        selected: selected,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIconTile(
              icon: icon,
              size: 44,
              iconSize: 22,
              color: selected ? c.accent : c.textSecondary,
              background: selected ? c.accentSoft : c.surfaceRaised,
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: context.text.titleSmall,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
