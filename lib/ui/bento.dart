import 'package:flutter/material.dart';

import '../core/app_spacing.dart';

/// A tile in a [Bento] layout.
class BentoTile {
  const BentoTile({required this.child, this.flex = 1, this.priority});

  final Widget child;

  /// Relative width within its row on wide layouts.
  final int flex;

  /// Order when the grid collapses to one column (lower first). Defaults to
  /// reading order.
  final int? priority;
}

/// Bento grid: rows of flexible tiles on wide layouts, one column ordered by
/// priority on narrow ones. See DESIGN.md §9.
///
/// Each wide row is wrapped in [IntrinsicHeight] so tiles stretch to the
/// tallest sibling without needing bounded height from the parent.
class Bento extends StatelessWidget {
  const Bento({
    super.key,
    required this.rows,
    this.gap = AppSpacing.lg,
    this.collapseBelow = 700,
    this.wide,
  });

  final List<List<BentoTile>> rows;
  final double gap;

  /// Width (px) under which the grid becomes a single column.
  final double collapseBelow;

  /// Force the wide (mosaic) or collapsed layout regardless of width.
  ///
  /// Set this when a Bento is nested inside another Bento tile (or any
  /// `IntrinsicHeight`): the width-measuring `LayoutBuilder` used otherwise
  /// cannot report an intrinsic height, which makes the parent row too short.
  final bool? wide;

  @override
  Widget build(BuildContext context) {
    final forced = wide ?? (collapseBelow <= 0 ? true : null);
    if (forced != null) return _layout(forced);
    return LayoutBuilder(
      builder: (context, constraints) =>
          _layout(constraints.maxWidth >= collapseBelow),
    );
  }

  Widget _layout(bool wide) {
    if (!wide) {
      final tiles = <(int, BentoTile)>[];
      var i = 0;
      for (final row in rows) {
        for (final t in row) {
          tiles.add((t.priority ?? i, t));
          i++;
        }
      }
      tiles.sort((a, b) => a.$1.compareTo(b.$1));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var j = 0; j < tiles.length; j++) ...[
            tiles[j].$2.child,
            if (j != tiles.length - 1) SizedBox(height: gap),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var k = 0; k < rows[r].length; k++) ...[
                  Expanded(flex: rows[r][k].flex, child: rows[r][k].child),
                  if (k != rows[r].length - 1) SizedBox(width: gap),
                ],
              ],
            ),
          ),
          if (r != rows.length - 1) SizedBox(height: gap),
        ],
      ],
    );
  }
}
