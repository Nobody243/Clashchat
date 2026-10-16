import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/responsive_layout.dart';
import '../models/debate_mode.dart';
import '../models/debate_record.dart';
import '../models/motions.dart';
import '../models/rank_model.dart';
import '../services/auth_service.dart';
import '../services/avatar_preferences.dart';
import '../services/usage_quota_service.dart';
import '../ui/ui.dart';
import '../widgets/user_avatar.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'results_screen.dart';
import 'settings_screen.dart';
import 'stance_screen.dart';
import 'topic_screen.dart';

/// Width (of the content column) under which the dashboard becomes a single
/// priority-ordered column.
const double _kCollapseBelow = 700;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  void _onNavTap(int i) {
    if (i == _navIndex) return;
    setState(() => _navIndex = i);
  }

  void _startCasualDebate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TopicScreen(mode: DebateMode.casual),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: _navIndex,
      onNavigationChanged: _onNavTap,
      onStartDebate: _startCasualDebate,
      pages: [
        (_) => _HomeBody(onNavigate: _onNavTap),
        (_) => const HistoryScreen(),
        (_) => const ProfileScreen(),
        (_) => const SettingsScreen(),
      ],
    );
  }
}

// ── Dashboard ────────────────────────────────────────────────────────────────

class _HomeBody extends StatefulWidget {
  const _HomeBody({required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Consecutive days (ending today or yesterday) with at least one debate.
  static int _streak(List<DebateRecord> records) {
    if (records.isEmpty) return 0;
    final days = records
        .map((r) => DateTime(r.date.year, r.date.month, r.date.day))
        .toSet();
    final now = DateTime.now();
    var day = DateTime(now.year, now.month, now.day);
    if (!days.contains(day)) {
      day = day.subtract(const Duration(days: 1));
      if (!days.contains(day)) return 0;
    }
    var n = 0;
    while (days.contains(day)) {
      n++;
      day = day.subtract(const Duration(days: 1));
    }
    return n;
  }

  /// Today's match: pick a side, then straight into a preset casual debate.
  void _startToday() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StanceScreen(
          topic: Motions.forDay(),
          mode: DebateMode.casual,
          quickMatch: true,
        ),
      ),
    );
  }

  void _open(DebateMode mode) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TopicScreen(mode: mode)),
    );
  }

  void _openRecord(DebateRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          topic: record.topic,
          stance: record.stance,
          messages: record.messages,
          score: record.score,
          strengths: record.strengths,
          weaknesses: record.weaknesses,
          summary: record.summary,
          difficulty: record.difficulty,
          pointsEarned: record.pointsEarned,
          mode: record.mode,
          isFromHistory: true,
          durationMinutes: record.durationMinutes > 0
              ? record.durationMinutes
              : null,
        ),
      ),
    );
  }

  /// Pull-to-refresh: force a server read of the user document. The live
  /// stream below picks up whatever changed.
  Future<void> _refresh() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.server));
    } catch (_) {
      // Offline: the cached stream value stays on screen.
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final uid = AuthService.currentUser?.uid;
    final compact = context.isCompact;
    final gutter = context.pageGutter;
    // With `extendBody` the shell reports the bottom bar height as bottom
    // padding; put it inside the scroll content so it slides under the blur.
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    Widget page = AppPage(
      width: compact ? AppPageWidth.form : AppPageWidth.wide,
      bottomSafe: false,
      padding: EdgeInsets.fromLTRB(
        gutter,
        compact ? AppSpacing.xl : AppSpacing.xxl,
        gutter,
        AppSpacing.xxxl + bottomInset,
      ),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          final loading =
              snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData;
          if (loading) {
            return compact
                ? const _PhoneSkeleton()
                : const _DashboardSkeleton();
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final displayName =
              data?['displayName'] as String? ??
              AuthService.currentUser?.displayName ??
              'Debater';
          final avatarSeed = data?['avatarSeed'] as String? ?? 'Felix';
          AvatarPreferences.saveAvatar(avatarSeed);
          final points = (data?['rankPoints'] as num?)?.toInt() ?? 0;
          final rank = RankModel.getRankFromPoints(points);
          final rankColor = Color(RankModel.rankData[rank]!['color'] as int);
          final quota = UsageQuotaService.fromData(data);

          return StreamBuilder<QuerySnapshot>(
            stream: uid == null
                ? null
                : FirebaseFirestore.instance
                      .collection('debates')
                      .doc(uid)
                      .collection('history')
                      .orderBy('date', descending: true)
                      .limit(30)
                      .snapshots(),
            builder: (context, recentSnap) {
              final recent = (recentSnap.data?.docs ?? const [])
                  .map(DebateRecord.fromFirestore)
                  .toList(growable: false);

              if (compact) {
                return _PhoneHome(
                  displayName: displayName,
                  avatarSeed: avatarSeed,
                  rank: rank,
                  rankColor: rankColor,
                  points: points,
                  quota: quota,
                  recent: recent,
                  streak: _streak(recent),
                  onStartToday: _startToday,
                  onOpenMode: _open,
                  onOpenRecord: _openRecord,
                  onTapAvatar: () => widget.onNavigate(2),
                  onSeeAll: () => widget.onNavigate(1),
                );
              }

              return StaggeredColumn(
                children: [
                  _Header(
                    greeting: _greeting(),
                    displayName: displayName,
                    avatarSeed: avatarSeed,
                    rankColor: rankColor,
                    onTapAvatar: () => widget.onNavigate(2),
                  ),
                  AppSpacing.vXxl,
                  _Dashboard(
                    points: points,
                    quota: quota,
                    recent: recent,
                    onOpenMode: _open,
                    onOpenRecord: _openRecord,
                    onSeeAll: () => widget.onNavigate(1),
                  ),
                ],
              );
            },
          );
        },
      ),
    );

    if (compact) {
      page = RefreshIndicator(
        color: c.accent,
        backgroundColor: c.surfaceRaised,
        edgeOffset: MediaQuery.paddingOf(context).top,
        onRefresh: _refresh,
        child: ScrollConfiguration(
          // Let the page over-scroll even when it is shorter than the
          // viewport so the indicator can always be pulled.
          behavior: ScrollConfiguration.of(context).copyWith(
            physics: AlwaysScrollableScrollPhysics(
              parent: ScrollConfiguration.of(context).getScrollPhysics(context),
            ),
          ),
          child: page,
        ),
      );
    }

    return page;
  }
}

// ── Phone composition (DESIGN.md §10) ────────────────────────────────────────

/// Phones: a quiet top line, today's motion as the hero with a split
/// For / Against choice, text tabs for the mode, and recent debates as plain
/// rows. No cards, no icon tiles, one action.
class _PhoneHome extends StatelessWidget {
  final String displayName;
  final String avatarSeed;
  final DebateRank rank;
  final Color rankColor;
  final int points;
  final UsageQuotaState quota;
  final List<DebateRecord> recent;
  final int streak;
  final VoidCallback onStartToday;
  final ValueChanged<DebateMode> onOpenMode;
  final ValueChanged<DebateRecord> onOpenRecord;
  final VoidCallback onTapAvatar;
  final VoidCallback onSeeAll;

  const _PhoneHome({
    required this.displayName,
    required this.avatarSeed,
    required this.rank,
    required this.rankColor,
    required this.points,
    required this.quota,
    required this.recent,
    required this.streak,
    required this.onStartToday,
    required this.onOpenMode,
    required this.onOpenRecord,
    required this.onTapAvatar,
    required this.onSeeAll,
  });

  static String _modeName(DebateMode mode) => switch (mode) {
    DebateMode.casual => 'Casual',
    DebateMode.ranked => 'Ranked',
    DebateMode.learning => 'Learning',
  };

  static String _recentSubtitle(DebateRecord r) {
    final base = '${r.stance} · ${_modeName(r.mode)}';
    if (r.mode == DebateMode.ranked && r.pointsEarned > 0) {
      return '$base +${r.pointsEarned}';
    }
    return base;
  }

  /// "Today 9:52" / "Yesterday" / "Mon" (older than a week: "Mar 4").
  static String _when(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final days = today.difference(day).inDays;
    if (days <= 0) return 'Today ${DateFormat('H:mm').format(date)}';
    if (days == 1) return 'Yesterday';
    if (days < 7) return DateFormat.E().format(date);
    return DateFormat('MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final locked = quota.isLocked;
    final rankName = RankModel.rankData[rank]!['name'] as String;
    final nextIndex = DebateRank.values.indexOf(rank) + 1;
    final DebateRank? next = nextIndex < DebateRank.values.length
        ? DebateRank.values[nextIndex]
        : null;
    final toNext = next == null
        ? null
        : (RankModel.rankData[next]!['minPoints'] as int) - points;

    return StaggeredColumn(
      children: [
        _ArenaTop(
          displayName: displayName,
          avatarSeed: avatarSeed,
          rankName: rankName,
          rankColor: rankColor,
          points: points,
          streak: streak,
          quota: quota,
          onTapAvatar: onTapAvatar,
        ),
        AppSpacing.vXl,
        _MatchCard(
          motion: Motions.forDay(),
          locked: locked,
          onStart: onStartToday,
        ),
        AppSpacing.vMd,
        Row(
          children: [
            Expanded(
              child: _ArenaDoor(
                title: 'Casual',
                subtitle: 'Your topic, your rules.',
                color: c.textPrimary,
                enabled: !locked,
                onTap: () => onOpenMode(DebateMode.casual),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ArenaDoor(
                title: 'Ranked',
                subtitle: '+50 on the line.',
                color: c.rankText,
                enabled: !locked,
                onTap: () => onOpenMode(DebateMode.ranked),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ArenaDoor(
                title: 'Learning',
                subtitle: 'Coach tips every turn.',
                color: c.infoText,
                enabled: !locked,
                onTap: () => onOpenMode(DebateMode.learning),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ArenaDoor(
                title: 'Own topic',
                subtitle: 'Write a motion.',
                color: c.textPrimary,
                enabled: !locked,
                onTap: () => onOpenMode(DebateMode.casual),
              ),
            ),
          ],
        ),
        AppSpacing.vXl,
        _RankLine(
          rankName: rankName,
          rankColor: rankColor,
          points: points,
          toNext: toNext,
          nextName: next == null
              ? null
              : RankModel.rankData[next]!['name'] as String,
          progress: RankModel.getRankProgress(points),
        ),
        if (recent.isNotEmpty) ...[
          AppSectionLabel('Recent', actionLabel: 'See all', onAction: onSeeAll),
          AppRows(
            children: [
              for (final r in recent.take(3))
                AppPlainRow(
                  title: r.topic,
                  subtitle: _recentSubtitle(r),
                  leading: ScoreNumber(r.score),
                  trailing: Text(
                    _when(r.date),
                    style: context.mono(size: 11, color: c.textHint),
                  ),
                  onTap: () => onOpenRecord(r),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Avatar + name + rank on the left; streak (or today's quota) on the right.
class _ArenaTop extends StatelessWidget {
  final String displayName;
  final String avatarSeed;
  final String rankName;
  final Color rankColor;
  final int points;
  final int streak;
  final UsageQuotaState quota;
  final VoidCallback onTapAvatar;

  const _ArenaTop({
    required this.displayName,
    required this.avatarSeed,
    required this.rankName,
    required this.rankColor,
    required this.points,
    required this.streak,
    required this.quota,
    required this.onTapAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        UserAvatar(
          seed: avatarSeed,
          size: 34,
          ringColor: rankColor,
          ringWidth: 2,
          onTap: onTapAvatar,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelLarge,
              ),
              Text(
                '${rankName.toUpperCase()} · $points pts',
                style: context.text.labelSmall?.copyWith(
                  color: c.rankText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (streak > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.hard, size: 16, color: c.accent),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '$streak day streak',
                style: context.text.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          )
        else
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${quota.usedToday}',
                  style: context.mono(size: 11, color: c.textSecondary),
                ),
                TextSpan(
                  text: '/${quota.dailyLimit} today',
                  style: context.text.labelSmall?.copyWith(color: c.textHint),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The hero: today's preset match with one Start button.
class _MatchCard extends StatelessWidget {
  final String motion;
  final bool locked;
  final VoidCallback onStart;

  const _MatchCard({
    required this.motion,
    required this.locked,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      clip: true,
      padding: const EdgeInsets.all(AppSpacing.lg + 2),
      radius: BorderRadius.circular(22),
      child: Stack(
        children: [
          // Soft flame wash in the top-right corner (the one allowed gradient).
          Positioned(
            top: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      c.accent.withValues(alpha: 0.16),
                      c.accent.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionLabel("Today's match", padding: EdgeInsets.zero),
              const SizedBox(height: AppSpacing.sm),
              Text(
                motion,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'ClashBot is ready on the other side. Pick a side in the next step.',
                style: context.text.bodySmall?.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.xs,
                children: [
                  _Meta(label: 'Opponent', value: 'Medium'),
                  _Meta(label: 'Clock', value: '5:00'),
                  _Meta(label: 'Mode', value: 'Casual'),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton.primary(
                label: locked ? 'Daily limit reached' : "Start today's debate",
                icon: locked ? null : AppIcons.play,
                onPressed: locked ? null : onStart,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final String label;
  final String value;
  const _Meta({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: context.text.labelSmall?.copyWith(color: c.textHint),
          ),
          TextSpan(
            text: value,
            style: context.mono(size: 11, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// One of the four doors under the hero.
class _ArenaDoor extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _ArenaDoor({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      onTap: enabled ? onTap : null,
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      radius: AppRadius.mdAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.text.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: enabled ? color : c.textHint,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelSmall?.copyWith(color: c.textHint),
          ),
        ],
      ),
    );
  }
}

/// "Newcomer · 80 pts to Challenger" with a thin bar and the points.
class _RankLine extends StatelessWidget {
  final String rankName;
  final Color rankColor;
  final int points;
  final int? toNext;
  final String? nextName;
  final double progress;

  const _RankLine({
    required this.rankName,
    required this.rankColor,
    required this.points,
    required this.toNext,
    required this.nextName,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final caption = toNext == null || nextName == null
        ? 'Top rank reached'
        : '$toNext pts to $nextName';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: rankName,
                      style: context.text.labelMedium?.copyWith(
                        color: c.rankText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: ' · $caption',
                      style: context.text.labelMedium?.copyWith(
                        color: c.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppProgressBar(value: progress, height: 5, color: rankColor),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        AnimatedNumber(value: points, size: 16, color: c.textSecondary),
      ],
    );
  }
}

/// Loading placeholder shaped like the phone composition: top line, hero,
/// two side buttons and three rows.
class _PhoneSkeleton extends StatelessWidget {
  const _PhoneSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget row() => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Row(
        children: [
          const AppSkeleton.line(width: 28, height: 14),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                AppSkeleton.line(width: 200, height: 14),
                SizedBox(height: AppSpacing.sm),
                AppSkeleton.line(width: 110, height: 11),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const AppSkeleton.line(width: 52, height: 11),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const AppSkeleton.circle(size: 34),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AppSkeleton.line(width: 120, height: 14),
                  SizedBox(height: AppSpacing.xs),
                  AppSkeleton.line(width: 90, height: 11),
                ],
              ),
            ),
            const AppSkeleton.line(width: 64, height: 11),
          ],
        ),
        AppSpacing.vXxxl,
        const AppSkeleton.line(width: 96, height: 11),
        AppSpacing.vMd,
        const AppSkeleton.line(height: 28),
        AppSpacing.vSm,
        const AppSkeleton.line(width: 220, height: 28),
        AppSpacing.vMd,
        const AppSkeleton.line(width: 200, height: 14),
        AppSpacing.vXl,
        Row(
          children: [
            Expanded(
              child: AppSkeleton.block(
                height: 64,
                radius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppSkeleton.block(
                height: 64,
                radius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
        AppSpacing.vXxxl,
        const AppSkeleton.line(width: 220, height: 14),
        AppSpacing.vXxl,
        row(),
        row(),
        row(),
      ],
    );
  }
}

// ── Bento ────────────────────────────────────────────────────────────────────

class _Dashboard extends StatelessWidget {
  final int points;
  final UsageQuotaState quota;
  final List<DebateRecord> recent;
  final ValueChanged<DebateMode> onOpenMode;
  final ValueChanged<DebateRecord> onOpenRecord;
  final VoidCallback onSeeAll;

  const _Dashboard({
    required this.points,
    required this.quota,
    required this.recent,
    required this.onOpenMode,
    required this.onOpenRecord,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final locked = quota.isLocked;
    return LayoutBuilder(
      builder: (context, box) {
        final collapsed = box.maxWidth < _kCollapseBelow;
        return Bento(
          collapseBelow: _kCollapseBelow,
          rows: [
            [
              BentoTile(flex: 2, priority: 0, child: _RankHero(points: points)),
              BentoTile(flex: 1, priority: 1, child: _UsageCard(quota: quota)),
            ],
            if (collapsed)
              [
                BentoTile(
                  priority: 2,
                  child: _ModesGroup(locked: locked, onOpen: onOpenMode),
                ),
              ]
            else
              [
                for (final (i, mode) in DebateMode.values.indexed)
                  BentoTile(
                    priority: 2 + i,
                    child: _ModeTile(
                      mode: mode,
                      locked: locked,
                      onTap: () => onOpenMode(mode),
                    ),
                  ),
              ],
            [
              if (recent.isNotEmpty)
                BentoTile(
                  flex: 2,
                  priority: 5,
                  child: _RecentDebates(
                    records: recent,
                    onOpen: onOpenRecord,
                    onSeeAll: onSeeAll,
                  ),
                ),
              const BentoTile(flex: 1, priority: 6, child: _TipCard()),
            ],
          ],
        );
      },
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String greeting;
  final String displayName;
  final String avatarSeed;
  final Color rankColor;
  final VoidCallback onTapAvatar;

  const _Header({
    required this.greeting,
    required this.displayName,
    required this.avatarSeed,
    required this.rankColor,
    required this.onTapAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppOverline(greeting),
              AppSpacing.vXs,
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.headlineSmall,
              ),
            ],
          ),
        ),
        AppSpacing.hLg,
        UserAvatar(
          seed: avatarSeed,
          size: 44,
          ringColor: rankColor,
          onTap: onTapAvatar,
        ),
      ],
    );
  }
}

// ── Rank hero ────────────────────────────────────────────────────────────────

class _RankHero extends StatelessWidget {
  final int points;

  const _RankHero({required this.points});

  String _nextRankLabel(DebateRank rank) {
    final ranks = DebateRank.values;
    final idx = ranks.indexOf(rank);
    if (idx >= ranks.length - 1) return 'Top rank reached';
    final next = RankModel.rankData[ranks[idx + 1]]!;
    final remaining = (next['minPoints'] as int) - points;
    return '$remaining pts to ${next['name']}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final rank = RankModel.getRankFromPoints(points);
    final rankData = RankModel.rankData[rank]!;
    final rankColor = Color(rankData['color'] as int);

    return AppCard(
      clip: true,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          // The hero's soft accent wash (DESIGN.md §9): the one place a
          // radial gradient is allowed inside a card.
          Positioned(
            top: -90,
            right: -70,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [c.accentSoft, c.accentSoft.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppIconTile(
                      icon: AppIcons.forRank(rank),
                      color: rankColor,
                      background: rankColor.withValues(alpha: 0.14),
                      size: 56,
                      iconSize: 28,
                    ),
                    AppSpacing.hLg,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppOverline('Current rank'),
                          AppSpacing.vXs,
                          Text(
                            rankData['name'] as String,
                            style: context.text.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                AppSpacing.vXl,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    AnimatedNumber(value: points, size: 36),
                    AppSpacing.hSm,
                    Text(
                      'pts',
                      style: context.text.labelLarge?.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
                AppSpacing.vLg,
                AppProgressBar(
                  value: RankModel.getRankProgress(points),
                  color: rankColor,
                ),
                AppSpacing.vSm,
                Text(
                  _nextRankLabel(rank),
                  style: context.text.labelSmall?.copyWith(
                    color: c.textSecondary,
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

// ── Usage card ───────────────────────────────────────────────────────────────

class _UsageCard extends StatelessWidget {
  final UsageQuotaState quota;

  const _UsageCard({required this.quota});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final locked = quota.isLocked;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const AppIconTile(icon: AppIcons.usage, size: 44, iconSize: 22),
              AppSpacing.hMd,
              Expanded(
                child: Text(
                  'Today',
                  style: context.text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          AppSpacing.vXl,
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedNumber(value: quota.usedToday, size: 28),
              AppSpacing.hSm,
              Text(
                'of ${quota.dailyLimit} debates',
                style: context.text.labelMedium?.copyWith(
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
          AppSpacing.vMd,
          AppProgressBar(
            value: quota.progress,
            height: 4,
            color: locked ? c.negativeText : c.accent,
          ),
          if (locked) ...[
            AppSpacing.vMd,
            const AppPill(
              label: 'Daily limit reached',
              icon: AppIcons.warning,
              tone: AppPillTone.warning,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Modes ────────────────────────────────────────────────────────────────────

({String title, String subtitle}) _modeCopy(DebateMode mode) => switch (mode) {
  DebateMode.casual => (
    title: 'Casual',
    subtitle: 'Custom timers and difficulty, no points at risk',
  ),
  DebateMode.ranked => (
    title: 'Ranked',
    subtitle: 'Quick 5 min or a full match, difficulty set by your rank',
  ),
  DebateMode.learning => (
    title: 'Learning',
    subtitle: 'Real-time coaching, tips and feedback',
  ),
};

(Color fg, Color bg) _modeTint(BuildContext context, DebateMode mode) {
  final c = context.colors;
  return switch (mode) {
    DebateMode.casual => (c.positiveText, c.positiveBg),
    DebateMode.ranked => (c.rankText, c.rankBg),
    DebateMode.learning => (c.infoText, c.infoBg),
  };
}

/// Wide layouts: one card per mode.
class _ModeTile extends StatelessWidget {
  final DebateMode mode;
  final bool locked;
  final VoidCallback onTap;

  const _ModeTile({
    required this.mode,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final copy = _modeCopy(mode);
    final (fg, bg) = _modeTint(context, mode);

    return AppCard(
      onTap: locked ? null : onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppIconTile(
            icon: AppIcons.forMode(mode, duotone: true),
            color: locked ? c.textHint : fg,
            background: locked ? c.surfaceRaised : bg,
            size: 48,
            iconSize: 24,
          ),
          AppSpacing.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy.title,
                  style: context.text.titleSmall?.copyWith(
                    color: locked ? c.textHint : c.textPrimary,
                  ),
                ),
                AppSpacing.vXs,
                Text(
                  copy.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: locked ? c.textHint : c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.hSm,
          if (locked)
            const AppPill(label: 'Locked')
          else
            Icon(AppIcons.forward, size: 18, color: c.textHint),
        ],
      ),
    );
  }
}

/// Phones: the three modes as one list group.
class _ModesGroup extends StatelessWidget {
  final bool locked;
  final ValueChanged<DebateMode> onOpen;

  const _ModesGroup({required this.locked, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSectionHeader(title: 'Start a debate'),
        AppListGroup(
          children: [
            for (final mode in DebateMode.values)
              Builder(
                builder: (context) {
                  final copy = _modeCopy(mode);
                  final (fg, bg) = _modeTint(context, mode);
                  return AppListRow(
                    title: copy.title,
                    subtitle: copy.subtitle,
                    titleColor: locked ? c.textHint : null,
                    leading: AppIconTile(
                      icon: AppIcons.forMode(mode, duotone: true),
                      color: locked ? c.textHint : fg,
                      background: locked ? c.surfaceRaised : bg,
                      size: 44,
                      iconSize: 22,
                    ),
                    trailing: locked ? const AppPill(label: 'Locked') : null,
                    onTap: locked ? null : () => onOpen(mode),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}

// ── Recent debates ───────────────────────────────────────────────────────────

class _RecentDebates extends StatelessWidget {
  final List<DebateRecord> records;
  final ValueChanged<DebateRecord> onOpen;
  final VoidCallback onSeeAll;

  const _RecentDebates({
    required this.records,
    required this.onOpen,
    required this.onSeeAll,
  });

  static String _when(DateTime date) {
    final now = DateTime.now();
    final sameDay =
        now.year == date.year && now.month == date.month && now.day == date.day;
    if (sameDay) return 'Today, ${DateFormat.jm().format(date)}';
    final yesterday = now.subtract(const Duration(days: 1));
    if (yesterday.year == date.year &&
        yesterday.month == date.month &&
        yesterday.day == date.day) {
      return 'Yesterday';
    }
    return DateFormat('MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: 'Recent',
          actionLabel: 'See all',
          onAction: onSeeAll,
        ),
        AppListGroup(
          children: [
            for (final r in records)
              AppListRow(
                title: r.topic,
                subtitle: '${_when(r.date)} · ${r.stance}',
                leading: ScoreRing(
                  value: r.score.toDouble(),
                  size: 36,
                  stroke: 3,
                  animate: false,
                  color: r.score >= 50 ? c.positiveText : c.negativeText,
                ),
                onTap: () => onOpen(r),
              ),
          ],
        ),
      ],
    );
  }
}

// ── Tip of the day ───────────────────────────────────────────────────────────

const List<String> _kTips = [
  'Lead with your strongest point. Judges remember openings and closings most.',
  'Concede the small things. Giving up a minor point buys credibility for the big one.',
  'Ask one sharp question instead of three vague ones. Let the silence do the work.',
  'Steelman before you strike: restate their best case, then take it apart.',
  'Numbers persuade, stories stick. Use one of each per argument.',
  'End on the clash, not the summary. Name exactly where you disagree and why you win it.',
];

class _TipCard extends StatelessWidget {
  const _TipCard();

  static int _dayOfYear(DateTime d) =>
      d.difference(DateTime(d.year, 1, 1)).inDays;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tip = _kTips[_dayOfYear(DateTime.now()) % _kTips.length];

    return AppCard(
      level: AppCardLevel.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIconTile(
                icon: AppIcons.coachTip,
                size: 40,
                iconSize: 20,
              ),
              AppSpacing.hMd,
              Expanded(
                child: Text('Tip of the day', style: context.text.titleSmall),
              ),
            ],
          ),
          AppSpacing.vMd,
          Text(
            tip,
            style: context.text.bodyMedium?.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton ─────────────────────────────────────────────────────────────────

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget block(double h) =>
        AppSkeleton.block(height: h, radius: AppRadius.lgAll);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AppSkeleton.line(width: 96, height: 11),
                  SizedBox(height: AppSpacing.sm),
                  AppSkeleton.line(width: 180, height: 24),
                ],
              ),
            ),
            const AppSkeleton.circle(size: 44),
          ],
        ),
        AppSpacing.vXxl,
        Bento(
          collapseBelow: _kCollapseBelow,
          rows: [
            [
              BentoTile(flex: 2, child: block(196)),
              BentoTile(flex: 1, child: block(196)),
            ],
            [for (var i = 0; i < 3; i++) BentoTile(child: block(96))],
            [
              BentoTile(flex: 2, child: block(200)),
              BentoTile(flex: 1, child: block(200)),
            ],
          ],
        ),
      ],
    );
  }
}
