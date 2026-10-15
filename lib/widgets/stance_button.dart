import 'package:flutter/material.dart';

import '../ui/ui.dart';
import 'setup_back_button.dart';

/// One side of the "For / Against" choice: a large selectable card.
///
/// Tone is derived from [label] ("For" -> positive/sage, anything else ->
/// negative/terracotta). The tile always carries its tone and deepens when
/// the card is chosen; the card itself takes the kit's selected hairline.
/// [activeGradient] is accepted for source compatibility with older call
/// sites and is no longer used; the design system has no gradients.
class StanceButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final List<Color> activeGradient;
  final VoidCallback onTap;
  final IconData? icon;

  /// One short line under the title, e.g. "You argue in favour".
  final String? description;

  const StanceButton({
    super.key,
    required this.label,
    required this.isSelected,
    this.activeGradient = const [],
    required this.onTap,
    this.icon,
    this.description,
  });

  bool get _isFor => label.trim().toLowerCase() == 'for';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final toneText = _isFor ? c.positiveText : c.negativeText;
    final toneBg = _isFor ? c.positiveBg : c.negativeBg;

    return Semantics(
      selected: isSelected,
      child: AppCard(
        onTap: onTap,
        selected: isSelected,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIconTile(
                  icon: icon ?? AppIcons.forStance(label, filled: true),
                  color: toneText,
                  background:
                      isSelected ? toneBg : toneBg.withValues(alpha: 0.55),
                  size: 56,
                  iconSize: 28,
                ),
                const Spacer(),
                SetupRadioMark(selected: isSelected),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(label, style: context.text.titleLarge),
            if (description != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                description!,
                style: context.text.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
