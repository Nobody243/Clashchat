import 'package:flutter/material.dart';

import '../models/rank_model.dart';
import '../ui/ui.dart';

/// Flat rank emblem: a disc in the rank color at 12 % alpha, a 1.5 px ring
/// and the rank's Phosphor glyph (DESIGN.md §2, "Rank colors").
class RankBadgeWidget extends StatelessWidget {
  final DebateRank rank;
  final double size;

  const RankBadgeWidget({super.key, required this.rank, this.size = 60.0});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: RankBadgePainter(rank: rank),
    );
  }
}

class RankBadgePainter extends CustomPainter {
  final DebateRank rank;

  RankBadgePainter({required this.rank});

  Color get _rankColor => Color(RankModel.rankData[rank]!['color'] as int);

  @override
  void paint(Canvas canvas, Size size) {
    final color = _rankColor;
    final center = size.center(Offset.zero);
    final ringWidth = (size.shortestSide * 0.03).clamp(1.0, 1.5);
    final radius = size.shortestSide / 2 - ringWidth / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()..color = color.withValues(alpha: 0.12),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth,
    );

    final icon = AppIcons.forRank(rank);
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size.shortestSide * 0.5,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant RankBadgePainter oldDelegate) =>
      rank != oldDelegate.rank;
}
