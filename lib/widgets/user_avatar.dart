import 'package:flutter/material.dart';

import '../models/avatar_option.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../ui/ui.dart';

/// Dicebear SVG avatar in a circle, optionally wrapped in a 2 px ring
/// (DESIGN.md §4: the ring takes the user's rank color). Shows a skeleton
/// while the picture loads. Pass [onTap] to make it tappable (press scale
/// and haptic on touch, pointer cursor on desktop).
class UserAvatar extends StatelessWidget {
  final String seed;
  final double size;

  /// When set, draws a ring of this color around the avatar.
  final Color? ringColor;
  final double ringWidth;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const UserAvatar({
    super.key,
    required this.seed,
    this.size = 40,
    this.ringColor,
    this.ringWidth = 2,
    this.onTap,
    this.semanticLabel,
  });

  String get url =>
      avatarUrlFor(seed);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasRing = ringColor != null;
    // Leave a hairline of canvas between the ring and the picture.
    final inner = hasRing ? size - (ringWidth + 2) * 2 : size;

    Widget picture = ClipOval(
      child: SvgPicture.network(
        url,
        width: inner,
        height: inner,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => AppSkeleton.circle(size: inner),
        errorBuilder: (_, _, _) => Container(
          width: inner,
          height: inner,
          color: c.surfaceRaised,
          alignment: Alignment.center,
          child: Icon(AppIcons.user, size: inner * 0.5, color: c.textHint),
        ),
      ),
    );

    Widget avatar = hasRing
        ? Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ringColor!, width: ringWidth),
            ),
            child: picture,
          )
        : SizedBox(width: size, height: size, child: picture);

    if (onTap == null) return avatar;

    return Pressable(
      onTap: onTap,
      pressedScale: 0.94,
      semanticLabel: semanticLabel ?? 'Avatar',
      child: avatar,
    );
  }
}
