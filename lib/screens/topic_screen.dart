import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/responsive_layout.dart';
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

  @override
  void dispose() {
    _customTopicCtrl.dispose();
    super.dispose();
  }

  void _toggleCategory(String label) {
    HapticFeedback.selectionClick();
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
    final isDesktop =
        MediaQuery.sizeOf(context).width > ResponsiveLayout.desktopBreakpoint;

    return Scaffold(
      appBar: AppBar(
        leading: const SetupBackButton(),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: isDesktop ? _buildDesktop() : _buildColumn(columns: 2),
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
                child: _buildColumn(columns: 4),
              ),
            ),
            const SizedBox(width: AppSpacing.xxxl),
            Flexible(
              flex: 3,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: const _HowItWorksPanel(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The single setup column: header, grid, custom field, bottom CTA.
  Widget _buildColumn({required int columns}) {
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
                const AppOverline('Step 1 of 3'),
                const SizedBox(height: AppSpacing.sm),
                Text('Pick a topic', style: context.text.headlineMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Choose a category or write the motion you want to argue.',
                  style: context.text.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                _buildGrid(columns),
                const SizedBox(height: AppSpacing.xxl),
                const AppSectionHeader(title: 'Or write your own'),
                AppTextField(
                  controller: _customTopicCtrl,
                  hint: 'e.g. Remote work makes teams more productive',
                  prefixIcon: AppIcons.topic,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() => _selectedCategory = null),
                  onSubmitted: (_) {
                    if (_canContinue) _nextStep();
                  },
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
            label: 'Continue',
            trailingIcon: AppIcons.forward,
            onPressed: _canContinue ? _nextStep : null,
          ),
        ),
      ],
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
        mainAxisExtent: 112,
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
        padding: const EdgeInsets.all(AppSpacing.lg),
        borderColor: selected ? c.accent : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIconTile(
              icon: icon,
              size: 40,
              iconSize: 20,
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

/// Desktop side panel: the three steps of the setup flow.
class _HowItWorksPanel extends StatelessWidget {
  const _HowItWorksPanel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.sm, AppSpacing.gutter, 0),
      child: AppReveal(
        index: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppOverline('How it works'),
            const SizedBox(height: AppSpacing.md),
            const AppListGroup(
              children: [
                _StepRow(
                  icon: AppIcons.topic,
                  title: 'Pick a topic',
                  description: 'Choose a category or write your own motion.',
                ),
                _StepRow(
                  icon: AppIcons.stanceFor,
                  title: 'Choose your side',
                  description: 'Argue for or against the motion.',
                ),
                _StepRow(
                  icon: AppIcons.ai,
                  title: 'Debate ClashBot',
                  description: 'Make your case, then see how you scored.',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _StepRow({
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
