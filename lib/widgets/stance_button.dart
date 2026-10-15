import 'package:flutter/material.dart';

import '../ui/ui.dart';

/// One side of the "For / Against" choice: a large selectable card.
///
/// Tone is derived from [label] ("For" -> positive/sage, anything else ->
/// negative/terracotta). [activeGradient] is accepted for source
/// compatibility with older call sites and is no longer used; the design
/// system has no gradients.
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
    final borderColor = isSelected ? toneText : c.border;
    final borderWidth = isSelected ? 1.5 : 1.0;

    // AppCard has no border-width parameter, so the (animated) border is
    // drawn here and the card itself is rendered borderless inside it.
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: AppCard(
          showBorder: false,
          radius: BorderRadius.circular(AppRadius.lg - 1.5),
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
                    background: toneBg,
                    size: 56,
                    iconSize: 28,
                  ),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    child: isSelected
                        ? Icon(
                            AppIcons.checkCircle,
                            key: const ValueKey('on'),
                            size: 22,
                            color: toneText,
                          )
                        : Container(
                            key: const ValueKey('off'),
                            width: 18,
                            height: 18,
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: c.borderStrong,
                                width: 1.5,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(label, style: context.text.titleMedium),
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
      ),
    );
  }
}
