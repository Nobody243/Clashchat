import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/responsive_layout.dart';
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
    final isDesktop =
        MediaQuery.sizeOf(context).width > ResponsiveLayout.desktopBreakpoint;

    return Scaffold(
      appBar: AppBar(
        leading: const SetupBackButton(),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(AuthService.currentUser!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            final waiting =
                snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData;
            final points = snapshot.data?.data()?['rankPoints'] ?? 0;
            final rank = RankModel.getRankFromPoints(points);
            final rankData = RankModel.rankData[rank]!;
            final rankName = rankData['name'] as String;
            final rankColor = Color(rankData['color'] as int);

            final column = _buildColumn(
              context,
              waiting: waiting,
              rank: rank,
              rankName: rankName,
              rankColor: rankColor,
            );

            if (!isDesktop) return column;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Flexible(
                      flex: 5,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: column,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xxxl),
                    Flexible(
                      flex: 3,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: const _HowRankedWorksPanel(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildColumn(
    BuildContext context, {
    required bool waiting,
    required DebateRank rank,
    required String rankName,
    required Color rankColor,
  }) {
    final c = context.colors;
    final win = RankModel.calculatePointsEarned(100, true);
    final loss = RankModel.calculatePointsEarned(0, true);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.sm,
              AppSpacing.gutter,
              AppSpacing.xxl,
            ),
            child: StaggeredColumn(
              children: [
                const AppOverline('Step 3 of 3'),
                const SizedBox(height: AppSpacing.sm),
                Text('Ranked debate', style: context.text.headlineMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'The terms are fixed. Your rank sets the opponent.',
                  style: context.text.bodyMedium?.copyWith(
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                if (waiting)
                  const _OpponentSkeleton()
                else
                  _OpponentCard(
                    rank: rank,
                    rankName: rankName,
                    rankColor: rankColor,
                  ),
                const SizedBox(height: AppSpacing.xxl),
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
                      trailing: Text(
                        topic,
                        style: context.text.bodyMedium,
                        textAlign: TextAlign.end,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailingFlex: true,
                    ),
                    _RuleRow(
                      icon: AppIcons.forStance(stance),
                      label: 'Stance',
                      trailing: AppPill.stance(stance),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                _PointsCard(win: win, loss: loss),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.md,
            AppSpacing.gutter,
            AppSpacing.gutter,
          ),
          child: AppButton.primary(
            label: 'Start ranked debate',
            icon: AppIcons.ranked,
            onPressed: waiting ? null : () => _start(context, rankName),
          ),
        ),
      ],
    );
  }
}

/// "Opponent calibrated to {Rank}" with the rank's icon and colour.
class _OpponentCard extends StatelessWidget {
  final DebateRank rank;
  final String rankName;
  final Color rankColor;

  const _OpponentCard({
    required this.rank,
    required this.rankName,
    required this.rankColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          AppIconTile(
            icon: AppIcons.forRank(rank),
            color: rankColor,
            background: rankColor.withValues(alpha: 0.12),
            size: 52,
            iconSize: 26,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Opponent calibrated to $rankName',
                  style: context.text.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'ClashBot debates at the level of your current rank. Climb, and it sharpens with you.',
                  style: context.text.bodySmall,
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
          AppSkeleton.block(width: 52, height: 52),
          SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton.line(width: 200, height: 14),
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

/// A fixed-rule row: leading icon, label, trailing value.
class _RuleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;

  /// When true the trailing widget takes the remaining width (long text).
  final bool trailingFlex;

  const _RuleRow({
    required this.icon,
    required this.label,
    required this.trailing,
    this.trailingFlex = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: c.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Text(label, style: context.text.bodyMedium),
          const SizedBox(width: AppSpacing.lg),
          if (trailingFlex)
            Expanded(child: trailing)
          else ...[
            const Spacer(),
            trailing,
          ],
        ],
      ),
    );
  }
}

/// Win / loss extremes side by side.
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
          Row(
            children: [
              Expanded(
                child: _PointsColumn(
                  caption: 'Win, up to',
                  value: '+$win',
                  color: c.positiveText,
                ),
              ),
              Container(width: 1, height: 44, color: c.border),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _PointsColumn(
                  caption: 'Loss, down to',
                  value: '$loss',
                  color: c.negativeText,
                ),
              ),
            ],
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
  final String value;
  final Color color;

  const _PointsColumn({
    required this.caption,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(caption, style: context.text.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: context.mono(size: 24, color: color)),
      ],
    );
  }
}

/// Desktop side panel: what makes ranked different.
class _HowRankedWorksPanel extends StatelessWidget {
  const _HowRankedWorksPanel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.sm, AppSpacing.gutter, 0),
      child: AppReveal(
        index: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppOverline('How ranked works'),
            const SizedBox(height: AppSpacing.md),
            const AppListGroup(
              children: [
                _InfoRow(
                  icon: AppIcons.timer,
                  title: 'Ten minutes, always',
                  description: 'Every ranked debate runs on the same clock.',
                ),
                _InfoRow(
                  icon: AppIcons.ranked,
                  title: 'Your rank sets the bar',
                  description: 'Higher ranks face a sharper opponent.',
                ),
                _InfoRow(
                  icon: AppIcons.points,
                  title: 'Points follow your score',
                  description: 'Win big to climb fast; a weak showing costs points.',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconTile(icon: icon, size: 40, iconSize: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(description, style: context.text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
