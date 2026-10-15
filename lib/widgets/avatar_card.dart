import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/avatar_option.dart';
import '../ui/ui.dart';

/// Selectable avatar tile for the picker grid. The selected card gets an
/// accent border and a small check in the top-right corner.
class AvatarCard extends StatelessWidget {
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
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: isSelected ? c.accent : null,
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final side = box.biggest.shortestSide;
                      return ClipOval(
                        child: SvgPicture.network(
                          avatar.url,
                          width: side,
                          height: side,
                          fit: BoxFit.cover,
                          placeholderBuilder: (_) =>
                              AppSkeleton.circle(size: side),
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
