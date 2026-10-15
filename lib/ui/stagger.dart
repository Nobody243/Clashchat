import 'package:flutter/material.dart';

import '../core/app_colors_ext.dart';

/// Default timing for reveals. See DESIGN.md §6.
const Duration kRevealStep = Duration(milliseconds: 40);
const Duration kRevealDuration = Duration(milliseconds: 260);

/// Builds the fade + rise for one child driven by [animation] (0..1).
Widget _reveal(Animation<double> animation, Widget child, double offset) {
  return FadeTransition(
    opacity: animation,
    alwaysIncludeSemantics: true,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, offset / 100),
        end: Offset.zero,
      ).animate(animation),
      transformHitTests: false,
      child: child,
    ),
  );
}

/// Fade + 8 px rise on first build, delayed by [index] × [step].
///
/// One controller, no timers: the delay is expressed as an [Interval] so the
/// reveal cannot be lost if a frame or timer is skipped. Honors reduce-motion
/// and never re-runs on rebuild.
class AppReveal extends StatefulWidget {
  const AppReveal({
    super.key,
    required this.child,
    this.index = 0,
    this.step = kRevealStep,
    this.duration = kRevealDuration,
    this.offset = 8,
  });

  final Widget child;
  final int index;
  final Duration step;
  final Duration duration;
  final double offset;

  @override
  State<AppReveal> createState() => _AppRevealState();
}

class _AppRevealState extends State<AppReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final delay = widget.step * widget.index;
    final total = delay + widget.duration;
    _ctrl = AnimationController(vsync: this, duration: total);
    final start = total.inMicroseconds == 0
        ? 0.0
        : delay.inMicroseconds / total.inMicroseconds;
    _anim = CurvedAnimation(
      parent: _ctrl,
      curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (context.reduceMotion) {
      _ctrl.value = 1;
    } else {
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _reveal(_anim, widget.child, widget.offset);
}

/// Column whose children reveal in sequence, driven by ONE controller.
class StaggeredColumn extends StatefulWidget {
  const StaggeredColumn({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.mainAxisSize = MainAxisSize.min,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.startIndex = 0,
    this.step = kRevealStep,
    this.duration = kRevealDuration,
    this.offset = 8,
  });

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final MainAxisAlignment mainAxisAlignment;
  final int startIndex;
  final Duration step;
  final Duration duration;
  final double offset;

  @override
  State<StaggeredColumn> createState() => _StaggeredColumnState();
}

class _StaggeredColumnState extends State<StaggeredColumn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _started = false;

  Duration get _total =>
      widget.step * (widget.startIndex + widget.children.length) +
      widget.duration;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _total);
  }

  @override
  void didUpdateWidget(StaggeredColumn old) {
    super.didUpdateWidget(old);
    // Children added later (e.g. a transcript toggled open) must not be
    // stuck invisible: extend the duration and make sure we are complete.
    if (old.children.length != widget.children.length) {
      _ctrl.duration = _total;
      if (_ctrl.status == AnimationStatus.completed ||
          _ctrl.status == AnimationStatus.dismissed) {
        _ctrl.value = 1;
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (context.reduceMotion) {
      _ctrl.value = 1;
    } else {
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Animation<double> _animFor(int i) {
    final totalUs = _total.inMicroseconds;
    if (totalUs == 0) return const AlwaysStoppedAnimation(1);
    final startUs = (widget.step * (widget.startIndex + i)).inMicroseconds;
    final endUs = startUs + widget.duration.inMicroseconds;
    return CurvedAnimation(
      parent: _ctrl,
      curve: Interval(
        (startUs / totalUs).clamp(0.0, 1.0),
        (endUs / totalUs).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: widget.crossAxisAlignment,
      mainAxisSize: widget.mainAxisSize,
      mainAxisAlignment: widget.mainAxisAlignment,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          _reveal(_animFor(i), widget.children[i], widget.offset),
      ],
    );
  }
}
