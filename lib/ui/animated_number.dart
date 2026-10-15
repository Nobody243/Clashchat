import 'package:flutter/material.dart';

import '../core/app_colors_ext.dart';

/// A number that counts up (or down) to [value] in the mono face.
///
/// Re-animates whenever [value] changes. Honors reduce-motion (jumps).
class AnimatedNumber extends StatelessWidget {
  const AnimatedNumber({
    super.key,
    required this.value,
    this.size = 24,
    this.weight = FontWeight.w600,
    this.color,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 900),
    this.curve = Curves.easeOutCubic,
    this.signed = false,
    this.textAlign,
  });

  final num value;
  final double size;
  final FontWeight weight;
  final Color? color;
  final String prefix;
  final String suffix;
  final Duration duration;
  final Curve curve;
  /// Show an explicit "+" for positive values.
  final bool signed;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final reduce = context.reduceMotion;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value.toDouble()),
      duration: reduce ? Duration.zero : duration,
      curve: curve,
      builder: (context, v, _) {
        final n = v.round();
        final sign = signed && n > 0 ? '+' : '';
        return Text(
          '$prefix$sign$n$suffix',
          textAlign: textAlign,
          style: context.mono(size: size, weight: weight, color: color),
        );
      },
    );
  }
}
