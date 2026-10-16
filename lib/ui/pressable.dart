import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors_ext.dart';

/// Builds [builder] with the current hover state (mouse only). On touch the
/// value is always false, so phones are unaffected.
class HoverBuilder extends StatefulWidget {
  const HoverBuilder({super.key, required this.builder, this.enabled = true});

  final Widget Function(BuildContext context, bool hovered) builder;
  final bool enabled;

  @override
  State<HoverBuilder> createState() => _HoverBuilderState();
}

class _HoverBuilderState extends State<HoverBuilder> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: widget.enabled ? (_) => setState(() => _hovered = true) : null,
      onExit: widget.enabled ? (_) => setState(() => _hovered = false) : null,
      child: widget.builder(context, _hovered && widget.enabled),
    );
  }
}

/// Tactile press feedback for every interactive surface.
///
/// * Touch: scales to [pressedScale] while pressed and plays a light haptic
///   on tap ([haptic], on by default).
/// * Pointer: reports hover via [onHover] and optionally scales to
///   [hoverScale].
///
/// Honors the system reduce-motion setting.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onHover,
    this.pressedScale = 0.98,
    this.hoverScale = 1.0,
    this.duration = const Duration(milliseconds: 90),
    this.enabled = true,
    this.haptic = true,
    this.behavior = HitTestBehavior.opaque,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<bool>? onHover;
  final double pressedScale;
  final double hoverScale;
  final Duration duration;
  final bool enabled;
  final bool haptic;
  final HitTestBehavior behavior;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;
  bool _hovered = false;

  void _setPressed(bool v) {
    if (_pressed == v || !mounted) return;
    setState(() => _pressed = v);
  }

  void _setHovered(bool v) {
    if (_hovered == v || !mounted) return;
    setState(() => _hovered = v);
    widget.onHover?.call(v);
  }

  void _tap() {
    if (widget.haptic) HapticFeedback.selectionClick();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final interactive = widget.enabled &&
        (widget.onTap != null || widget.onLongPress != null);
    final reduce = context.reduceMotion;
    double scale = 1.0;
    if (interactive && _pressed) {
      scale = widget.pressedScale;
    } else if (interactive && _hovered) {
      scale = widget.hoverScale;
    }

    return Semantics(
      button: interactive,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      // One semantics node carrying both the label and the tap action, so
      // screen readers (and Flutter web's semantics overlay) activate it.
      onTap: interactive && widget.onTap != null ? _tap : null,
      onLongPress: interactive ? widget.onLongPress : null,
      child: MouseRegion(
        cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: interactive ? (_) => _setHovered(true) : null,
        onExit: interactive ? (_) => _setHovered(false) : null,
        child: GestureDetector(
          behavior: widget.behavior,
          excludeFromSemantics: true,
          onTapDown: interactive ? (_) => _setPressed(true) : null,
          onTapUp: interactive ? (_) => _setPressed(false) : null,
          onTapCancel: interactive ? () => _setPressed(false) : null,
          onTap: interactive && widget.onTap != null ? _tap : null,
          onLongPress: interactive ? widget.onLongPress : null,
          child: AnimatedScale(
            scale: reduce ? 1.0 : scale,
            duration: widget.duration,
            curve: Curves.easeOutCubic,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
