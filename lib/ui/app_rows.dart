import 'package:flutter/material.dart';

import '../core/app_colors_ext.dart';
import '../core/app_spacing.dart';
import 'app_icons.dart';
import 'pressable.dart';

/// Children separated by hairlines, with NO container: the phone composition
/// uses these instead of cards for lists (DESIGN.md §10). The first child has
/// a top rule when [topRule] is true.
class AppRows extends StatelessWidget {
  const AppRows({super.key, required this.children, this.topRule = true});

  final List<Widget> children;
  final bool topRule;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0 || topRule) Divider(height: 1, thickness: 1, color: c.border),
          children[i],
        ],
      ],
    );
  }
}

/// A plain row: optional leading (usually a mono number or nothing), title,
/// subtitle, trailing (mono date, a value, or a chevron). No tile, no card.
class AppPlainRow extends StatelessWidget {
  const AppPlainRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.leadingWidth = 38,
    this.trailing,
    this.onTap,
    this.titleColor,
    this.chevron = false,
    this.padding = const EdgeInsets.symmetric(vertical: AppSpacing.md),
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final double leadingWidth;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final bool chevron;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget row(bool hovered) => AnimatedContainer(
          duration: AppDurations.fast,
          color: hovered ? c.accent.withValues(alpha: 0.06) : Colors.transparent,
          padding: padding,
          child: Row(
            children: [
              if (leading != null) ...[
                SizedBox(width: leadingWidth, child: leading),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: context.text.titleSmall?.copyWith(color: titleColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: context.text.labelMedium?.copyWith(
                          color: c.textHint,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: AppSpacing.md), trailing!],
              if (chevron) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(AppIcons.forward, size: 18, color: c.textHint),
              ],
            ],
          ),
        );
    if (onTap == null) return row(false);
    return Pressable(
      onTap: onTap,
      pressedScale: 0.995,
      semanticLabel: title,
      child: HoverBuilder(builder: (context, hovered) => row(hovered)),
    );
  }
}

/// Small caps section label with an optional trailing text action.
class AppSectionLabel extends StatelessWidget {
  const AppSectionLabel(
    this.text, {
    super.key,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.only(top: AppSpacing.xxl, bottom: AppSpacing.sm),
  });

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: context.text.labelSmall?.copyWith(
                color: c.textHint,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (actionLabel != null)
            Pressable(
              onTap: onAction,
              pressedScale: 0.96,
              child: Text(
                actionLabel!,
                style: context.text.labelMedium?.copyWith(color: c.accent),
              ),
            ),
        ],
      ),
    );
  }
}

/// Underlined text tabs (no pill, no container): "Casual · Ranked · Learning".
class AppTextTabs extends StatelessWidget {
  const AppTextTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.gap = AppSpacing.xl,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            Pressable(
              onTap: i == index ? null : () => onChanged(i),
              pressedScale: 0.97,
              semanticLabel: labels[i],
              child: Container(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: i == index ? c.accent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: AnimatedDefaultTextStyle(
                  duration: AppDurations.fast,
                  style: context.text.labelLarge!.copyWith(
                    color: i == index ? c.textPrimary : c.textHint,
                  ),
                  child: Text(labels[i]),
                ),
              ),
            ),
            if (i != labels.length - 1) SizedBox(width: gap),
          ],
        ],
      ),
    );
  }
}

/// Thin segmented progress for multi-step flows (3 bars, current ones lit).
class AppStepBar extends StatelessWidget {
  const AppStepBar({super.key, required this.step, this.total = 3});
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        for (var i = 1; i <= total; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: AppDurations.normal,
              height: 3,
              decoration: BoxDecoration(
                color: i <= step ? c.accent : c.borderStrong,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          if (i != total) const SizedBox(width: AppSpacing.xs + 2),
        ],
      ],
    );
  }
}
