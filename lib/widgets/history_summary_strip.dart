import 'package:flutter/material.dart';

import '../models/debate_record.dart';
import '../ui/ui.dart';

/// Three small stat cards: Debates / Avg score / Wins.
///
/// Hidden when there are no records (the list's empty state takes over).
class HistorySummaryStrip extends StatelessWidget {
  final List<DebateRecord> records;
  const HistorySummaryStrip({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();
    final avg =
        (records.map((r) => r.score).reduce((a, b) => a + b) / records.length)
            .round();
    final wins = records.where((r) => r.score >= 70).length;

    return Row(
      children: [
        _StatCard(value: '${records.length}', label: 'Debates'),
        AppSpacing.hMd,
        _StatCard(value: '$avg', label: 'Avg score'),
        AppSpacing.hMd,
        _StatCard(value: '$wins', label: 'Wins'),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: context.mono(size: 20)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
