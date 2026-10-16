import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/avatar_option.dart';
import '../ui/ui.dart';

/// Selectable avatar tile for the picker grid. The selected card draws its
/// accent hairline, a 2 px accent ring around the avatar and a small check.
class AvatarCard extends StatelessWidget {
  /// Test hook: replaces the network SVG so widget tests need no HTTP.
  @visibleForTesting
  static Widget Function(String url, double size)? imageOverride;

  final AvatarOption avatar;
  final bool isSelected;
  final VoidCallback onTap;

  const AvatarCard({
    super.key,
    required this.avatar,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      onTap: onTap,
      selected: isSelected,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final side = box.biggest.shortestSide;
                      final inner = side - 8;
                      return AnimatedContainer(
                        duration: AppDurations.fast,
                        curve: Curves.easeOutCubic,
                        width: side,
                        height: side,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? c.accent
                                : c.accent.withValues(alpha: 0),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child:
                              imageOverride?.call(avatar.url, inner) ??
                              SvgPicture.network(
                                avatar.url,
                                width: inner,
                                height: inner,
                                fit: BoxFit.cover,
                                placeholderBuilder: (_) =>
                                    AppSkeleton.circle(size: inner),
                                errorBuilder: (_, _, _) => Container(
                                  width: inner,
                                  height: inner,
                                  color: c.surfaceRaised,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    AppIcons.user,
                                    size: inner * 0.42,
                                    color: c.textHint,
                                  ),
                                ),
                              ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              AppSpacing.vSm,
              Text(
                avatar.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelMedium?.copyWith(
                  color: isSelected ? c.textPrimary : c.textSecondary,
                ),
              ),
            ],
          ),
          if (isSelected)
            Positioned(
              top: 0,
              right: 0,
              child: Icon(AppIcons.checkCircle, size: 18, color: c.accent),
            ),
        ],
      ),
    );
  }
}
