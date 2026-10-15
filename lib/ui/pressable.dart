import 'package:flutter/material.dart';

import '../core/app_colors_ext.dart';

/// Tactile press feedback: scales the child to [pressedScale] while pressed.
///
/// Wraps any widget. Honors the system reduce-motion setting. Use this instead
/// of ad-hoc `GestureDetector`s so every interactive surface feels the same.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.98,
    this.duration = const Duration(milliseconds: 90),
    this.enabled = true,
    this.behavior = HitTestBehavior.opaque,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final Duration duration;
  final bool enabled;
  final HitTestBehavior behavior;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed == v || !mounted) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final interactive = widget.enabled &&
        (widget.onTap != null || widget.onLongPress != null);
    final scale = _pressed && interactive ? widget.pressedScale : 1.0;
    final reduce = context.reduceMotion;

    return Semantics(
      button: interactive,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: widget.behavior,
        onTapDown: interactive ? (_) => _set(true) : null,
        onTapUp: interactive ? (_) => _set(false) : null,
        onTapCancel: interactive ? () => _set(false) : null,
        onTap: interactive ? widget.onTap : null,
        onLongPress: interactive ? widget.onLongPress : null,
        child: AnimatedScale(
          scale: reduce ? 1.0 : scale,
          duration: widget.duration,
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}
