import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/app_colors_ext.dart';

/// Atmospheric page background: canvas color, two or three slow "stage
/// lights" (very soft radial washes that drift over ~20 s) and a fine film
/// grain. See DESIGN.md §9.
///
/// Cheap by construction: the grain is painted once per size into a cached
/// layer (`RepaintBoundary`), and the lights are plain radial gradients.
/// Honors reduce-motion (lights freeze in place).
class AppBackdrop extends StatefulWidget {
  const AppBackdrop({
    super.key,
    this.child,
    this.intensity = 1.0,
    this.grain = true,
    this.lights = true,
  });

  final Widget? child;

  /// 0..1 multiplier on the light alpha. Use ~0.6 behind dense content.
  final double intensity;
  final bool grain;
  final bool lights;

  /// Global switch for the light drift. Widget tests set this to false so
  /// `pumpAndSettle` can complete; the app leaves it on.
  static bool animationsEnabled = true;

  @override
  State<AppBackdrop> createState() => _AppBackdropState();
}

class _AppBackdropState extends State<AppBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 22),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!context.reduceMotion && widget.lights && AppBackdrop.animationsEnabled) {
        _ctrl.repeat();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = context.isDark;
    final k = widget.intensity * (dark ? 1.0 : 0.75);

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: c.background),
        if (widget.lights)
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) => CustomPaint(
              painter: _StageLightPainter(
                t: _ctrl.value,
                lights: [
                  _Light(c.accent, 0.11 * k, const Offset(0.15, -0.05), 0.55),
                  _Light(c.infoText, 0.06 * k, const Offset(0.95, 0.35), 0.45),
                  _Light(c.negativeText, 0.045 * k, const Offset(0.35, 1.05), 0.5),
                ],
              ),
            ),
          ),
        if (widget.grain)
          IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _GrainPainter(
                  color: dark ? Colors.white : Colors.black,
                  alpha: dark ? 0.045 : 0.035,
                ),
              ),
            ),
          ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _Light {
  const _Light(this.color, this.alpha, this.anchor, this.radius);
  final Color color;
  final double alpha;
  /// Anchor in unit coordinates (may be outside 0..1).
  final Offset anchor;
  /// Radius as a fraction of the longest side.
  final double radius;
}

class _StageLightPainter extends CustomPainter {
  _StageLightPainter({required this.t, required this.lights});
  final double t;
  final List<_Light> lights;

  @override
  void paint(Canvas canvas, Size size) {
    final longest = math.max(size.width, size.height);
    for (var i = 0; i < lights.length; i++) {
      final l = lights[i];
      // Each light drifts on its own slow Lissajous path.
      final phase = t * 2 * math.pi + i * 2.1;
      final dx = math.sin(phase) * 0.06 + math.cos(phase * 0.5) * 0.03;
      final dy = math.cos(phase * 0.8) * 0.05;
      final center = Offset(
        (l.anchor.dx + dx) * size.width,
        (l.anchor.dy + dy) * size.height,
      );
      final r = l.radius * longest;
      final paint = Paint()
        ..shader = ui.Gradient.radial(
          center,
          r,
          [l.color.withValues(alpha: l.alpha), l.color.withValues(alpha: 0)],
          const [0.0, 1.0],
        );
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(_StageLightPainter old) =>
      old.t != t || old.lights != lights;
}

class _GrainPainter extends CustomPainter {
  _GrainPainter({required this.color, required this.alpha});
  final Color color;
  final double alpha;

  static final Map<int, ui.Picture> _cache = {};

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final key = Object.hash(size.width.round(), size.height.round(), color.toARGB32(), (alpha * 1000).round());
    final pic = _cache.putIfAbsent(key, () => _build(size));
    canvas.drawPicture(pic);
  }

  ui.Picture _build(Size size) {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final rnd = math.Random(7);
    final count = (size.width * size.height / 28).clamp(400, 14000).toInt();
    final pts = List<Offset>.generate(
      count,
      (_) => Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
    );
    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.square;
    c.drawPoints(ui.PointMode.points, pts, paint);
    return rec.endRecording();
  }

  @override
  bool shouldRepaint(_GrainPainter old) => old.color != color || old.alpha != alpha;
}
