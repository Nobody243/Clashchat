import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/responsive_layout.dart';
import '../models/debate_mode.dart';
import '../models/rank_model.dart';
import '../services/auth_service.dart';
import '../services/usage_quota_service.dart';
import '../ui/ui.dart';
import '../widgets/user_avatar.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'topic_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > ResponsiveLayout.desktopBreakpoint) {
      return ResponsiveLayout(
        currentIndex: _navIndex,
        onNavigationChanged: _onNavTap,
        screens: const [
          _HomeBody(),
          HistoryScreen(),
          ProfileScreen(),
          SettingsScreen(),
        ],
      );
    }

    return Scaffold(
      body: switch (_navIndex) {
        1 => const HistoryScreen(),
        2 => const ProfileScreen(),
        3 => const SettingsScreen(),
        _ => const _HomeBody(),
      },
      bottomNavigationBar: AppBottomNav(
        currentIndex: _navIndex,
        onChanged: _onNavTap,
      ),
    );
  }
}

// ── Dashboard ────────────────────────────────────────────────────────────────

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _open(BuildContext context, DebateMode mode) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TopicScreen(mode: mode)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > ResponsiveLayout.desktopBreakpoint;

    return ColoredBox(
      color: c.background,
      child: SafeArea(
        top: !isDesktop,
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(AuthService.currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            final loading =
                snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData;

            final data = snapshot.data?.data() as Map<String, dynamic>?;
            final firestoreDisplayName = data?['displayName'] as String?;
            final authDisplayName = AuthService.currentUser?.displayName;
            final displayName =
                firestoreDisplayName ?? authDisplayName ?? 'Debater';
            final avatarSeed = data?['avatarSeed'] as String? ?? 'Felix';
            final points = (data?['rankPoints'] as num?)?.toInt() ?? 0;
            final rank = RankModel.getRankFromPoints(points);
            final rankColor = Color(RankModel.rankData[rank]!['color'] as int);
            final quota = UsageQuotaService.fromData(data);
            final locked = quota.isLocked;

            final header = _Header(
              greeting: _greeting(),
              displayName: displayName,
              avatarSeed: avatarSeed,
              rankColor: rankColor,
            );
            final rankCard = _RankCard(points: points);
            final usageCard = _UsageCard(quota: quota);
            final modes = _ModesGroup(
              locked: locked,
              onOpen: (mode) => _open(context, mode),
            );

            if (isDesktop) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxxl,
                  vertical: AppSpacing.xxxl,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: loading
                        ? const _DesktopSkeleton()
                        : StaggeredColumn(
                            children: [
                              header,
                              AppSpacing.vXxl,
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        rankCard,
                                        AppSpacing.vLg,
                                        usageCard,
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xxl),
                                  Expanded(
                                    flex: 6,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        const AppSectionHeader(
                                          title: 'Start a debate',
                                        ),
                                        modes,
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.xl,
                AppSpacing.gutter,
                AppSpacing.xxxl,
              ),
              child: loading
                  ? const _PhoneSkeleton()
                  : StaggeredColumn(
                      children: [
                        header,
                        AppSpacing.vXxl,
                        rankCard,
                        AppSpacing.vMd,
                        usageCard,
                        AppSpacing.vXxl,
                        const AppSectionHeader(title: 'Start a debate'),
                        modes,
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String greeting;
  final String displayName;
  final String avatarSeed;
  final Color rankColor;

  const _Header({
    required this.greeting,
    required this.displayName,
    required this.avatarSeed,
    required this.rankColor,
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
        UserAvatar(seed: avatarSeed, size: 44, ringColor: rankColor),
      ],
    );
  }
}

// ── Rank card ────────────────────────────────────────────────────────────────

class _RankCard extends StatelessWidget {
  final int points;

  const _RankCard({required this.points});

  String _nextRankLabel(DebateRank rank) {
    final ranks = DebateRank.values;
    final idx = ranks.indexOf(rank);
    if (idx >= ranks.length - 1) return 'Top rank';
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconTile(
                icon: AppIcons.forRank(rank),
                color: rankColor,
                background: rankColor.withValues(alpha: 0.12),
                size: 52,
                iconSize: 26,
              ),
              AppSpacing.hLg,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rankData['name'] as String,
                        style: context.text.titleSmall),
                    AppSpacing.vXs,
                    Text(
                      '$points pts',
                      style: context.mono(size: 22, color: c.textPrimary),
                    ),
                  ],
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
            style: context.text.labelSmall?.copyWith(color: c.textSecondary),
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
    final barColor = locked ? c.negativeText : c.accent;
    final numberStyle = context.mono(size: 14, color: c.textPrimary);
    final wordStyle = context.text.bodySmall;

    return AppCard(
      level: AppCardLevel.raised,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIconTile(icon: AppIcons.usage, size: 36, iconSize: 18),
              AppSpacing.hMd,
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${quota.usedToday}', style: numberStyle),
                      TextSpan(text: ' of ', style: wordStyle),
                      TextSpan(text: '${quota.dailyLimit}', style: numberStyle),
                      TextSpan(text: ' debates today', style: wordStyle),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (locked) ...[
                AppSpacing.hSm,
                const AppPill(
                  label: 'Daily limit reached',
                  tone: AppPillTone.warning,
                ),
              ],
            ],
          ),
          AppSpacing.vMd,
          AppProgressBar(value: quota.progress, color: barColor),
        ],
      ),
    );
  }
}

// ── Modes ────────────────────────────────────────────────────────────────────

class _ModesGroup extends StatelessWidget {
  final bool locked;
  final ValueChanged<DebateMode> onOpen;

  const _ModesGroup({required this.locked, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppListGroup(
      children: [
        _ModeRow(
          mode: DebateMode.casual,
          title: 'Casual',
          subtitle: 'Custom timers and difficulty, no points at risk',
          color: c.positiveText,
          background: c.positiveBg,
          locked: locked,
          onTap: () => onOpen(DebateMode.casual),
        ),
        _ModeRow(
          mode: DebateMode.ranked,
          title: 'Ranked',
          subtitle: '10 minutes, difficulty matched to your rank',
          color: c.rankText,
          background: c.rankBg,
          locked: locked,
          onTap: () => onOpen(DebateMode.ranked),
        ),
        _ModeRow(
          mode: DebateMode.learning,
          title: 'Learning',
          subtitle: 'Real-time coaching, tips and feedback',
          color: c.infoText,
          background: c.infoBg,
          locked: locked,
          onTap: () => onOpen(DebateMode.learning),
        ),
      ],
    );
  }
}

class _ModeRow extends StatelessWidget {
  final DebateMode mode;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;
  final bool locked;
  final VoidCallback onTap;

  const _ModeRow({
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.background,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: locked ? null : onTap,
      enabled: !locked,
      semanticLabel: '$title mode',
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            AppIconTile(
              icon: AppIcons.forMode(mode, duotone: true),
              color: locked ? c.textHint : color,
              background: locked ? c.surfaceRaised : background,
              size: 44,
              iconSize: 24,
            ),
            AppSpacing.hMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.text.titleSmall?.copyWith(
                      color: locked ? c.textHint : c.textPrimary,
                    ),
                  ),
                  AppSpacing.vXs,
                  Text(
                    subtitle,
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
      ),
    );
  }
}

// ── Skeletons ────────────────────────────────────────────────────────────────

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}

class _PhoneSkeleton extends StatelessWidget {
  const _PhoneSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _HeaderSkeleton(),
        AppSpacing.vXxl,
        AppSkeleton.block(height: 148, radius: AppRadius.lgAll),
        AppSpacing.vMd,
        AppSkeleton.block(height: 92, radius: AppRadius.lgAll),
        AppSpacing.vXxl,
        const AppSkeleton.line(width: 120, height: 16),
        AppSpacing.vMd,
        AppSkeleton.block(height: 232, radius: AppRadius.lgAll),
      ],
    );
  }
}

class _DesktopSkeleton extends StatelessWidget {
  const _DesktopSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _HeaderSkeleton(),
        AppSpacing.vXxl,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  AppSkeleton.block(height: 148, radius: AppRadius.lgAll),
                  AppSpacing.vLg,
                  AppSkeleton.block(height: 92, radius: AppRadius.lgAll),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xxl),
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSkeleton.line(width: 120, height: 16),
                  AppSpacing.vMd,
                  AppSkeleton.block(height: 232, radius: AppRadius.lgAll),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
