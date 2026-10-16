import 'package:flutter/material.dart';

import '../core/app_colors_ext.dart';

/// Score bands used everywhere a score is shown (DESIGN.md §10).
///   70–100  Sharp      positive
///   40–69   Solid      warning/gold
///   0–39    Needs work negative
enum ScoreBand { sharp, solid, needsWork }

extension ScoreBandX on ScoreBand {
  String get label => switch (this) {
        ScoreBand.sharp => 'Sharp',
        ScoreBand.solid => 'Solid',
        ScoreBand.needsWork => 'Needs work',
      };

  Color color(BuildContext context) {
    final c = context.colors;
    return switch (this) {
      ScoreBand.sharp => c.positiveText,
      ScoreBand.solid => c.warningText,
      ScoreBand.needsWork => c.negativeText,
    };
  }
}

ScoreBand scoreBand(num score) {
  if (score >= 70) return ScoreBand.sharp;
  if (score >= 40) return ScoreBand.solid;
  return ScoreBand.needsWork;
}

/// A score as a mono numeral coloured by band. Use in rows (size 15) and
/// stats (size 22).
class ScoreNumber extends StatelessWidget {
  const ScoreNumber(this.score, {super.key, this.size = 15, this.weight = FontWeight.w600});
  final int score;
  final double size;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$score',
      style: context.mono(size: size, weight: weight, color: scoreBand(score).color(context)),
    );
  }
}
