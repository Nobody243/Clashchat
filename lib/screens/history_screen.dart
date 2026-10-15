import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/responsive_layout.dart';
import '../models/debate_mode.dart';
import '../models/debate_record.dart';
import '../services/auth_service.dart';
import '../ui/ui.dart';
import '../widgets/desktop_page_shell.dart';
import '../widgets/history_debate_card.dart';
import '../widgets/history_summary_strip.dart';
import 'home_screen.dart';
import 'results_screen.dart';

/// The kit has no delete glyph; mapped privately here (see report).
const IconData _trashIcon = AppIcons.delete;

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DebateMode _selectedMode = DebateMode.ranked;
  String _stanceFilter = 'All';
  int _minScore = 0;

  bool get _filterActive => _stanceFilter != 'All' || _minScore > 0;

  void _showFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) {
          final c = ctx.colors;
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.md,
              AppSpacing.gutter,
              AppSpacing.xxl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.borderStrong,
                      borderRadius: AppRadius.pillAll,
                    ),
                  ),
                ),
                AppSpacing.vXl,
                Text('Filter debates', style: ctx.text.titleMedium),
                AppSpacing.vXxl,
                const AppSectionHeader(title: 'Stance'),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final s in const ['All', 'For', 'Against'])
                      Pressable(
                        pressedScale: 0.95,
                        onTap: () {
                          setModal(() {});
                          setState(() => _stanceFilter = s);
                        },
                        child: AppPill(
                          label: s,
                          tone: _stanceFilter == s
                              ? AppPillTone.accent
                              : AppPillTone.neutral,
                        ),
                      ),
                  ],
                ),
                AppSpacing.vXxl,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Expanded(
                      child: AppSectionHeader(
                        title: 'Minimum score',
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    Text('$_minScore', style: ctx.mono(size: 24)),
                  ],
                ),
                AppSpacing.vSm,
                SliderTheme(
                  data: SliderTheme.of(ctx).copyWith(
                    activeTrackColor: c.accent,
                    inactiveTrackColor: c.inset,
                    thumbColor: c.accent,
                    overlayColor: c.accentSoft,
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _minScore.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 10,
                    onChanged: (v) {
                      setModal(() {});
                      setState(() => _minScore = v.round());
                    },
                  ),
                ),
                AppSpacing.vLg,
                AppButton.primary(
                  label: 'Apply',
                  onPressed: () => Navigator.pop(ctx),
                ),
                AppSpacing.vSm,
                Center(
                  child: AppButton.ghost(
                    label: 'Reset',
                    onPressed: () {
                      setModal(() {});
                      setState(() {
                        _stanceFilter = 'All';
                        _minScore = 0;
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > ResponsiveLayout.desktopBreakpoint;
    final isWideDesktop = screenWidth >= ResponsiveLayout.wideDesktopBreakpoint;

    final Widget content = StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('debates')
          .doc(AuthService.currentUser?.uid)
          .collection('history')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.gutter,
              vertical: AppSpacing.lg,
            ),
            children: [
              _buildModeTabs(),
              AppSpacing.vXxl,
              const AppListGroup(
                children: [
                  AppSkeletonRow(),
                  AppSkeletonRow(),
                  AppSkeletonRow(),
                  AppSkeletonRow(),
                ],
              ),
            ],
          );
        }

        if (snapshot.hasError) {
          return const AppEmptyState(
            icon: AppIcons.warning,
            title: 'Could not load history',
            message: 'Check your connection and try again.',
          );
        }

        final allDocs = snapshot.data?.docs ?? [];
        final records =
            allDocs.map((d) => DebateRecord.fromFirestore(d)).toList();

        // Filter based on active tab and filter options
        final filtered = records.where((r) {
          if (r.mode != _selectedMode) {
            return false;
          }
          if (_stanceFilter != 'All' && r.stance != _stanceFilter) {
            return false;
          }
          if (r.score < _minScore) {
            return false;
          }
          return true;
        }).toList();

        return ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter,
            vertical: AppSpacing.lg,
          ),
          children: [
            StaggeredColumn(
              children: [
                HistorySummaryStrip(records: filtered),
                if (filtered.isNotEmpty) AppSpacing.vXxl,
                _buildModeTabs(),
                AppSpacing.vXxl,
                AppSectionHeader(
                  title: 'Recent debates',
                  subtitle: '${filtered.length} total',
                ),
                if (filtered.isEmpty)
                  _buildEmptyState()
                else
                  AppListGroup(
                    children: [
                      for (final record in filtered) _buildRow(record),
                    ],
                  ),
              ],
            ),
          ],
        );
      },
    );

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('History', style: context.text.titleMedium),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AppIconButton(
                  icon: AppIcons.filter,
                  filled: true,
                  tooltip: 'Filter',
                  onPressed: () => _showFilter(context),
                ),
                if (_filterActive)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: c.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: !isDesktop,
        child: isWideDesktop
            ? DesktopPageShell(maxWidth: 800, child: content)
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: content,
                ),
              ),
      ),
    );
  }

  /// Segmented control for the debate mode.
  Widget _buildModeTabs() {
    final c = context.colors;
    return AppCard(
      level: AppCardLevel.raised,
      padding: const EdgeInsets.all(AppSpacing.xs),
      radius: AppRadius.pillAll,
      child: Row(
        children: [
          for (final mode in DebateMode.values)
            Expanded(
              child: Pressable(
                pressedScale: 0.97,
                onTap: () => setState(() => _selectedMode = mode),
                child: AnimatedContainer(
                  duration: AppDurations.fast,
                  curve: Curves.easeOutCubic,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _selectedMode == mode
                        ? c.accentSoft
                        : c.surfaceRaised.withValues(alpha: 0),
                    borderRadius: AppRadius.pillAll,
                  ),
                  child: Text(
                    _modeLabel(mode),
                    style: context.text.labelLarge?.copyWith(
                      color: _selectedMode == mode
                          ? c.textPrimary
                          : c.textHint,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _modeLabel(DebateMode mode) => switch (mode) {
        DebateMode.ranked => 'Ranked',
        DebateMode.casual => 'Casual',
        DebateMode.learning => 'Learning',
      };

  Widget _buildRow(DebateRecord record) {
    final c = context.colors;
    final row = HistoryDebateCard(
      record: record,
      onTap: () {
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
              durationMinutes:
                  record.durationMinutes > 0 ? record.durationMinutes : null,
            ),
          ),
        );
      },
    );

    if (record.mode == DebateMode.ranked) {
      return row;
    }

    return Dismissible(
      key: Key(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: c.negativeBg,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        child: Icon(_trashIcon, size: 20, color: c.negativeText),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => const _ConfirmDeleteDialog(),
        );
      },
      onDismissed: (direction) async {
        await FirebaseFirestore.instance
            .collection('debates')
            .doc(AuthService.currentUser?.uid)
            .collection('history')
            .doc(record.id)
            .delete();
      },
      child: ColoredBox(color: c.surface, child: row),
    );
  }

  Widget _buildEmptyState() {
    return AppEmptyState(
      icon: AppIcons.history,
      title: 'No debates yet',
      message: 'Your finished debates will show up here.',
      action: AppButton.secondary(
        label: 'Start a debate',
        expand: false,
        onPressed: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        },
      ),
    );
  }
}

class _ConfirmDeleteDialog extends StatelessWidget {
  const _ConfirmDeleteDialog();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Dialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
        side: BorderSide(color: c.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delete debate', style: context.text.titleMedium),
            AppSpacing.vMd,
            Text(
              'Are you sure you want to delete this match? This cannot be undone.',
              style: context.text.bodyMedium?.copyWith(
                color: c.textSecondary,
              ),
            ),
            AppSpacing.vXxl,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton.ghost(
                  label: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                AppSpacing.hSm,
                AppButton.danger(
                  label: 'Delete',
                  expand: false,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
