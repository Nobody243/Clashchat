import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../ui/ui.dart';

/// Dicebear SVG avatar in a circle, optionally wrapped in a 2 px ring
/// (DESIGN.md §4: the ring takes the user's rank color).
class UserAvatar extends StatelessWidget {
  final String seed;
  final double size;

  /// When set, draws a ring of this color around the avatar.
  final Color? ringColor;
  final double ringWidth;

  const UserAvatar({
    super.key,
    required this.seed,
    this.size = 40,
    this.ringColor,
    this.ringWidth = 2,
  });

  String get _effectiveSeed {
    final trimmed = seed.trim();
    if (trimmed.isEmpty) return 'Debater';
    return Uri.encodeComponent(trimmed);
  }

  String get url =>
      'https://api.dicebear.com/9.x/thumbs/svg?seed=$_effectiveSeed'
      '&backgroundColor=2e2715,15302a,182637,3a1e1a,232025'
      '&shapeColor=d4a84b,6fc29b,86b0e3,ed8b72,a9b0ba'
      '&radius=50';

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

    if (!hasRing) return SizedBox(width: size, height: size, child: picture);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor!, width: ringWidth),
      ),
      child: picture,
    );
  }
}
