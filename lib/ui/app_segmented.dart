import 'package:flutter/material.dart';

import '../core/app_colors_ext.dart';
import '../core/app_spacing.dart';
import 'pressable.dart';

/// Segmented control with a sliding thumb. Raised surface, pill thumb in
/// accent-soft, selected label in ink. Keyboard/semantics friendly.
class AppSegmented extends StatelessWidget {
  const AppSegmented({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.icons,
    this.enabled = true,
    this.height = 44,
  });

  final List<String> labels;
  final List<IconData>? icons;
  final int index;
  final ValueChanged<int> onChanged;
  final bool enabled;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final n = labels.length;
    assert(n >= 2);

    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: AppRadius.pillAll,
        border: Border.all(color: c.border),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final segW = box.maxWidth / n;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: AppDurations.normal,
                curve: Curves.easeOutCubic,
                left: segW * index,
                top: 0,
                bottom: 0,
                width: segW,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.accentSoft,
                    borderRadius: AppRadius.pillAll,
                    border: Border.all(color: c.accent.withValues(alpha: 0.35)),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < n; i++)
                    Expanded(
                      child: Pressable(
                        onTap: enabled && i != index ? () => onChanged(i) : null,
                        pressedScale: 0.97,
                        semanticLabel: labels[i],
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (icons != null) ...[
                                Icon(
                                  icons![i],
                                  size: 16,
                                  color: i == index ? c.textPrimary : c.textHint,
                                ),
                                const SizedBox(width: AppSpacing.xs + 2),
                              ],
                              AnimatedDefaultTextStyle(
                                duration: AppDurations.fast,
                                style: context.text.labelLarge!.copyWith(
                                  color: i == index ? c.textPrimary : c.textHint,
                                ),
                                child: Text(labels[i], maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
