import 'package:flutter/material.dart';

import '../ui/ui.dart';

/// The ClashChat mark: two speech bubbles meeting, one outlined in ink and
/// one filled in brass. Reads at 20 px and at 1024 px.
///
/// Colors come from the current theme so the mark sits correctly on both
/// canvases. [showBackground] draws the rounded app-icon tile behind it.
class AppLogoWidget extends StatelessWidget {
  const AppLogoWidget({
    super.key,
    this.size = 72.0,
    this.showBackground = false,
  });

  final double size;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: 'ClashChat',
      image: true,
      child: CustomPaint(
        size: Size(size, size),
        painter: AppLogoPainter(
          showBackground: showBackground,
          ink: c.textPrimary,
          accent: c.accent,
          background: c.background,
        ),
      ),
    );
  }
}

/// Paints the mark in a 160 x 160 coordinate space, scaled to the given size.
///
/// Colors default to the dark palette so the painter can be used headless
/// (for example when rasterising the launcher icon).
class AppLogoPainter extends CustomPainter {
  AppLogoPainter({
    this.showBackground = false,
    Color? ink,
    Color? accent,
    Color? background,
  })  : ink = ink ?? AppColorsExt.dark.textPrimary,
        accent = accent ?? AppColorsExt.dark.accent,
        background = background ?? AppColorsExt.dark.background;

  final bool showBackground;
  final Color ink;
  final Color accent;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 160.0;
    canvas.scale(scale, scale);

    if (showBackground) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 160, 160),
          const Radius.circular(36),
        ),
        Paint()..color = background,
      );
    }

    const radius = Radius.circular(18);

    final back = RRect.fromRectAndRadius(
      const Rect.fromLTWH(28, 36, 80, 60),
      radius,
    );
    final front = RRect.fromRectAndRadius(
      const Rect.fromLTWH(56, 68, 76, 56),
      radius,
    );

    // Without a tile the gap between the bubbles must be transparent, so the
    // mark is composed in its own layer and the gap is cleared there.
    if (!showBackground) {
      canvas.saveLayer(const Rect.fromLTWH(0, 0, 160, 160), Paint());
    }

    // Back bubble: ink outline.
    canvas.drawRRect(
      back,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeJoin = StrokeJoin.round,
    );

    // Gap so the front bubble reads as sitting in front of the outline.
    canvas.drawRRect(
      front.inflate(8),
      showBackground
          ? (Paint()..color = background)
          : (Paint()..blendMode = BlendMode.clear),
    );

    // Front bubble: brass fill.
    canvas.drawRRect(front, Paint()..color = accent);

    if (!showBackground) canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AppLogoPainter old) =>
      old.showBackground != showBackground ||
      old.ink != ink ||
      old.accent != accent ||
      old.background != background;
}
