import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_colors_ext.dart';

/// One-shot celebratory burst (brass, sage, sky and ink flecks) that falls
/// under gravity and fades. Overlay it on a hero moment such as a strong
/// score or a rank-up. Fires once when [play] becomes true. Does nothing
/// under reduce-motion.
class ParticleBurst extends StatefulWidget {
  const ParticleBurst({
    super.key,
    required this.play,
    this.count = 90,
    this.origin = const Alignment(0, -0.35),
    this.duration = const Duration(milliseconds: 2200),
  });

  final bool play;
  final int count;
  final Alignment origin;
  final Duration duration;

  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

class _ParticleBurstState extends State<ParticleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: widget.duration);
  List<_Particle> _particles = const [];
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    if (widget.play) _fire();
  }

  @override
  void didUpdateWidget(ParticleBurst old) {
    super.didUpdateWidget(old);
    if (widget.play && !old.play) _fire();
  }

  void _fire() {
    if (_fired) return;
    _fired = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || context.reduceMotion) return;
      final c = context.colors;
      final rnd = math.Random();
      final palette = [c.accent, c.positiveText, c.infoText, c.textPrimary, c.negativeText];
      _particles = List.generate(widget.count, (i) {
        final angle = -math.pi / 2 + (rnd.nextDouble() - 0.5) * math.pi * 1.1;
        final speed = 0.55 + rnd.nextDouble() * 0.9;
        return _Particle(
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          color: palette[rnd.nextInt(palette.length)],
          size: 3 + rnd.nextDouble() * 5,
          spin: (rnd.nextDouble() - 0.5) * 8,
          rect: rnd.nextBool(),
        );
      });
      _ctrl.forward(from: 0);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_particles.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          if (_ctrl.isCompleted) return const SizedBox.shrink();
          return CustomPaint(
            painter: _BurstPainter(_particles, _ctrl.value, widget.origin),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.spin,
    required this.rect,
  });
  final double vx, vy, size, spin;
  final Color color;
  final bool rect;
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.particles, this.t, this.origin);
  final List<_Particle> particles;
  final double t;
  final Alignment origin;

  @override
  void paint(Canvas canvas, Size size) {
    final o = Offset(
      size.width * (origin.x + 1) / 2,
      size.height * (origin.y + 1) / 2,
    );
    final scale = size.shortestSide;
    final fade = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3);
    for (final p in particles) {
      final x = o.dx + p.vx * scale * t;
      final y = o.dy + p.vy * scale * t + 0.9 * scale * t * t;
      final paint = Paint()..color = p.color.withValues(alpha: fade.clamp(0, 1));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t);
      if (p.rect) {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size * 1.6, height: p.size * 0.8), paint);
      } else {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}
