import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/debate_mode.dart';
import '../models/rank_model.dart';
import '../services/auth_service.dart';
import '../ui/ui.dart';
import '../widgets/setup_back_button.dart';
import 'chat_screen.dart';

class RankedSetupScreen extends StatelessWidget {
  final String topic;
  final String stance;

  const RankedSetupScreen({
    super.key,
    required this.topic,
    required this.stance,
  });

  void _start(BuildContext context, String difficulty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          topic: topic,
          stance: stance,
          difficulty: difficulty,
          timerMinutes: 10, // always 10 in ranked
          mode: DebateMode.ranked,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(AuthService.currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final waiting = snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;
        final points = snapshot.data?.data()?['rankPoints'] ?? 0;
        final rank = RankModel.getRankFromPoints(points);
        final rankData = RankModel.rankData[rank]!;
        final rankName = rankData['name'] as String;
        final rankColor = Color(rankData['color'] as int);
        final win = RankModel.calculatePointsEarned(100, true);
        final loss = RankModel.calculatePointsEarned(0, true);

        return SetupScaffold(
          step: 3,
          title: 'Ranked debate',
          subtitle: 'The terms are fixed. Your rank sets the opponent.',
          summary: SetupSummary(
            topic: topic,
            stance: stance,
            difficulty: waiting ? null : rankName,
            timer: '10:00',
          ),
          cta: AppButton.primary(
            label: 'Start ranked debate',
            icon: AppIcons.ranked,
            onPressed: waiting ? null : () => _start(context, rankName),
          ),
          children: [
            if (waiting)
              const _OpponentSkeleton()
            else
              _OpponentHero(
                rank: rank,
                rankName: rankName,
                rankColor: rankColor,
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppSectionHeader(title: 'Match rules'),
                AppListGroup(
                  children: [
                    _RuleRow(
                      icon: AppIcons.timer,
                      label: 'Timer',
                      trailing: Text('10:00', style: context.mono(size: 16)),
                    ),
                    _RuleRow(
                      icon: AppIcons.forDifficulty(rankName),
                      label: 'Difficulty',
                      trailing: waiting
                          ? const AppSkeleton(width: 88, height: 28)
                          : AppPill.difficulty(rankName),
                    ),
                    _RuleRow(
                      icon: AppIcons.topic,
                      label: 'Topic',
                      subtitle: topic,
                    ),
                    _RuleRow(
                      icon: AppIcons.forStance(stance),
                      label: 'Stance',
                      trailing: AppPill.stance(stance),
                    ),
                  ],
                ),
              ],
            ),
            _PointsCard(win: win, loss: loss),
          ],
        );
      },
    );
  }
}

/// "Opponent calibrated to {Rank}": rank tile, title, explainer, and a soft
/// rank-coloured wash in the top-right corner. The wash is the one place in
/// the setup flow a radial gradient is allowed (DESIGN.md §9).
class _OpponentHero extends StatelessWidget {
  final DebateRank rank;
  final String rankName;
  final Color rankColor;

  const _OpponentHero({
    required this.rank,
    required this.rankName,
    required this.rankColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      clip: true,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -90,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      rankColor.withValues(alpha: 0.14),
                      rankColor.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Row(
              children: [
                AppIconTile(
                  icon: AppIcons.forRank(rank),
                  color: rankColor,
                  background: rankColor.withValues(alpha: 0.12),
                  size: 56,
                  iconSize: 28,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Opponent calibrated to $rankName',
                        style: context.text.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'ClashBot debates at the level of your current rank. Climb, and it sharpens with you.',
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OpponentSkeleton extends StatelessWidget {
  const _OpponentSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Row(
        children: [
          AppSkeleton.block(width: 56, height: 56),
          SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton.line(width: 220, height: 16),
                SizedBox(height: AppSpacing.sm),
                AppSkeleton.line(height: 12),
                SizedBox(height: AppSpacing.xs),
                AppSkeleton.line(width: 160, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A fixed-rule row: small tile, label, and either a trailing value or a
/// wrapped subtitle (for long text such as the topic).
class _RuleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final String? subtitle;

  const _RuleRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppListRow(
      showChevron: false,
      title: label,
      subtitle: subtitle,
      leading: AppIconTile(
        icon: icon,
        size: 36,
        iconSize: 18,
        color: c.textSecondary,
        background: c.surfaceRaised,
      ),
      trailing: trailing,
    );
  }
}

/// Win / loss extremes side by side; the numbers count up on first appearance.
class _PointsCard extends StatelessWidget {
  final int win;
  final int loss;
  const _PointsCard({required this.win, required this.loss});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      level: AppCardLevel.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.points, size: 18, color: c.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Text('Points at stake', style: context.text.titleSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _PointsColumn(
                    caption: 'Win, up to',
                    child: AnimatedNumber(
                      value: win,
                      signed: true,
                      color: c.positiveText,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Container(width: 1, color: c.border),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _PointsColumn(
                    caption: 'Loss, down to',
                    child: AnimatedNumber(
                      value: loss,
                      color: c.negativeText,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Score 50 or more to win. Higher scores earn more.',
            style: context.text.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _PointsColumn extends StatelessWidget {
  final String caption;
  final Widget child;

  const _PointsColumn({required this.caption, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(caption, style: context.text.labelSmall),
        const SizedBox(height: AppSpacing.xs),
        child,
      ],
    );
  }
}
