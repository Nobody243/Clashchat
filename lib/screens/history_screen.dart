import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/debate_mode.dart';
import '../models/debate_record.dart';
import '../services/auth_service.dart';
import '../ui/ui.dart';
import '../widgets/history_debate_card.dart';
import '../widgets/history_summary_strip.dart';
import 'debate_review_screen.dart';
import 'home_screen.dart';
import 'results_screen.dart';

/// Height of the pinned glass header (wide layouts): 44 px control + 12 px
/// padding above and below + 1 px hairline. Scroll views pad their top by this
/// so content starts under the bar and slides beneath it.
const double _headerHeight = 69;

/// Blocks above the list in the entry stagger (strip, gap, control, gap,
/// section header). Rows continue the sequence from here.
const int _revealRowStart = 5;

/// Rows past this index reveal together so long lists do not keep waiting.
const int _revealCap = 8;

/// Order of the mode tabs after "All".
const List<DebateMode> _modes = [
  DebateMode.casual,
  DebateMode.ranked,
  DebateMode.learning,
];

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  /// Null means "All": the mode filter is off and every record passes.
  DebateMode? _selectedMode;
  String _stanceFilter = 'All';
  int _minScore = 0;

  /// Debate shown in the detail pane on large layouts.
  String? _selectedId;

  bool get _filterActive => _stanceFilter != 'All' || _minScore > 0;

  /// Tab index: 0 = All, then [_modes].
  int get _modeIndex =>
      _selectedMode == null ? 0 : _modes.indexOf(_selectedMode!) + 1;

  void _setModeIndex(int i) =>
      setState(() => _selectedMode = i == 0 ? null : _modes[i - 1]);

  // ── Filter ──

  void _showFilter(BuildContext context) {
    // Wide screens get a centred dialog; phones and small tablets a sheet.
    if (context.screenWidth >= AppBreakpoints.medium) {
      showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: _buildFilterContent(),
            ),
          ),
        ),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.sm,
          AppSpacing.gutter,
          AppSpacing.xxl,
        ),
        child: _buildFilterContent(),
      ),
    );
  }

  Widget _buildFilterContent() {
    const stances = ['All', 'For', 'Against'];
    return StatefulBuilder(
      builder: (ctx, setModal) {
        final c = ctx.colors;
        final caption = _minScore == 0
            ? 'Any score'
            : 'Only debates scoring $_minScore or more';
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Filter', style: ctx.text.titleMedium),
            AppSpacing.vXxl,
            const AppSectionLabel(
              'Stance',
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
            ),
            AppTextTabs(
              labels: stances,
              index: stances.indexOf(_stanceFilter),
              onChanged: (i) {
                setModal(() {});
                setState(() => _stanceFilter = stances[i]);
              },
            ),
            AppSpacing.vXxl,
            const AppSectionLabel(
              'Minimum score',
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$_minScore', style: ctx.mono(size: 28)),
                AppSpacing.hMd,
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      caption,
                      style: ctx.text.labelSmall?.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.vXs,
            SliderTheme(
              // Flush with the number above; the theme styles the rest.
              data: SliderTheme.of(ctx).copyWith(padding: EdgeInsets.zero),
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
        );
      },
    );
  }

  // ── Actions ──

  /// The stream is live, so a pull simply gives the gesture a moment to land.
  Future<void> _refresh() =>
      Future<void>.delayed(const Duration(milliseconds: 600));

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
          durationMinutes:
              record.durationMinutes > 0 ? record.durationMinutes : null,
        ),
      ),
    );
  }

  /// Shape a record the way [DebateReviewBody] reads it.
  Map<String, dynamic> _reviewData(DebateRecord r) => {
        'topic': r.topic,
        'stance': r.stance,
        'difficulty': r.difficulty,
        'date': r.date.toIso8601String(),
        'score': r.score,
        'summary': r.summary,
        'strengths': r.strengths,
        'weaknesses': r.weaknesses,
        'messages': r.messages,
        'mode': r.mode,
        'isRanked': r.isRanked,
        'pointsEarned': r.pointsEarned,
        'durationMinutes': r.durationMinutes > 0 ? r.durationMinutes : null,
      };

  // ── Data ──

  Stream<QuerySnapshot> get _stream => FirebaseFirestore.instance
      .collection('debates')
      .doc(AuthService.currentUser?.uid)
      .collection('history')
      .orderBy('date', descending: true)
      .snapshots();

  /// Active tab and filter options applied to the snapshot.
  List<DebateRecord> _filter(QuerySnapshot? data) {
    final records =
        (data?.docs ?? []).map((d) => DebateRecord.fromFirestore(d)).toList();
    return records.where((r) {
      if (_selectedMode != null && r.mode != _selectedMode) {
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
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: context.isCompact ? _buildPhone() : _buildWide(),
    );
  }

  // ── Phone (DESIGN.md §10) ──

  /// One scrolling list: title + Filter link, three numbers, text tabs, rows
  /// grouped by day. No glass bar, no cards.
  Widget _buildPhone() {
    final c = context.colors;
    return AppPage(
      width: AppPageWidth.form,
      scroll: false,
      padding: EdgeInsets.zero,
      child: StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (context, snapshot) {
          final String revealKey;
          final List<Widget> top;
          final Widget body;

          if (snapshot.connectionState == ConnectionState.waiting) {
            revealKey = 'loading';
            top = [_buildModeTabs(), AppSpacing.vXxl];
            body = const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSkeleton.line(width: 220),
                SizedBox(height: AppSpacing.xl),
                AppSkeleton.line(width: 180),
                SizedBox(height: AppSpacing.xl),
                AppSkeleton.line(width: 240),
                SizedBox(height: AppSpacing.xl),
                AppSkeleton.line(width: 160),
              ],
            );
          } else if (snapshot.hasError) {
            revealKey = 'error';
            top = const [];
            body = const AppEmptyState(
              icon: AppIcons.warning,
              title: 'Could not load history',
              message: 'Check your connection and try again.',
            );
          } else {
            final filtered = _filter(snapshot.data);
            revealKey = 'loaded';
            top = [
              HistorySummaryStrip(records: filtered, compact: true),
              if (filtered.isNotEmpty) AppSpacing.vXxl,
              _buildModeTabs(),
            ];
            body = filtered.isEmpty
                ? AppReveal(index: _revealRowStart, child: _buildEmptyState())
                : _buildDayGroups(filtered);
          }

          return RefreshIndicator(
            color: c.accent,
            backgroundColor: c.surfaceRaised,
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.lg,
                AppSpacing.gutter,
                AppSpacing.xxxl,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _buildPhoneHeader(),
                AppSpacing.vXxl,
                StaggeredColumn(key: ValueKey(revealKey), children: top),
                body,
              ],
            ),
          );
        },
      ),
    );
  }

  /// "History" with a Filter text link; the accent dot marks an active filter.
  Widget _buildPhoneHeader() {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: Text('History', style: context.text.headlineMedium)),
        Pressable(
          onTap: () => _showFilter(context),
          pressedScale: 0.96,
          semanticLabel: 'Filter',
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_filterActive) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: c.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  AppSpacing.hSm,
                ],
                Text(
                  'Filter',
                  style: context.text.labelLarge?.copyWith(color: c.accent),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Underlined text tabs: All · Casual · Ranked · Learning.
  Widget _buildModeTabs() {
    return AppTextTabs(
      labels: ['All', for (final m in _modes) HistoryDebateCard.modeLabel(m)],
      index: _modeIndex,
      onChanged: _setModeIndex,
    );
  }

  /// Rows grouped under a small-caps day label, revealing in one sequence.
  Widget _buildDayGroups(List<DebateRecord> filtered) {
    final groups = <DateTime, List<DebateRecord>>{};
    for (final r in filtered) {
      final day = DateTime(r.date.year, r.date.month, r.date.day);
      groups.putIfAbsent(day, () => []).add(r);
    }

    var i = 0;
    final children = <Widget>[];
    for (final entry in groups.entries) {
      children.add(
        AppReveal(
          key: ValueKey('day-${entry.key.millisecondsSinceEpoch}'),
          index: _revealRowStart + math.min(i, _revealCap),
          child: AppSectionLabel(_dayLabel(entry.key)),
        ),
      );
      children.add(
        AppRows(
          children: [
            for (final r in entry.value)
              AppReveal(
                key: ValueKey(r.id),
                index: _revealRowStart + math.min(i++, _revealCap),
                child: _buildRow(r, false),
              ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  /// "Today" / "Yesterday" / weekday within the last week / "12 Oct" beyond.
  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = today.difference(day).inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days > 1 && days < 7) return DateFormat.EEEE().format(day);
    return DateFormat('d MMM').format(day);
  }

  // ── Wide (≥ 600): unchanged composition ──

  Widget _buildWide() {
    final large = context.isLarge;
    final gutter = context.pageGutter;
    final topInset = MediaQuery.paddingOf(context).top;
    final contentTop = topInset + _headerHeight + AppSpacing.lg;

    return AppPage(
      width: AppPageWidth.wide,
      scroll: false,
      // The glass bar owns the status-bar area; lists pad for it.
      topSafe: false,
      padding: EdgeInsets.zero,
      child: SizedBox.expand(
        child: Stack(
          children: [
            Positioned.fill(
              child: StreamBuilder<QuerySnapshot>(
                stream: _stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildPanes(
                      revealKey: 'loading',
                      large: large,
                      gutter: gutter,
                      contentTop: contentTop,
                      top: [_buildModeControl(), AppSpacing.vXxl],
                      body: const AppListGroup(
                        children: [
                          AppSkeletonRow(),
                          AppSkeletonRow(),
                          AppSkeletonRow(),
                          AppSkeletonRow(),
                        ],
                      ),
                      detail: large ? _buildDetail(null, contentTop) : null,
                    );
                  }

                  if (snapshot.hasError) {
                    return _buildPanes(
                      revealKey: 'error',
                      large: large,
                      gutter: gutter,
                      contentTop: contentTop,
                      top: const [],
                      body: const AppEmptyState(
                        icon: AppIcons.warning,
                        title: 'Could not load history',
                        message: 'Check your connection and try again.',
                      ),
                      detail: large ? _buildDetail(null, contentTop) : null,
                    );
                  }

                  final filtered = _filter(snapshot.data);

                  DebateRecord? selected;
                  for (final r in filtered) {
                    if (r.id == _selectedId) {
                      selected = r;
                      break;
                    }
                  }

                  return _buildPanes(
                    revealKey: 'loaded',
                    large: large,
                    gutter: gutter,
                    contentTop: contentTop,
                    top: [
                      HistorySummaryStrip(records: filtered),
                      if (filtered.isNotEmpty) AppSpacing.vXxl,
                      _buildModeControl(),
                      AppSpacing.vXxl,
                      AppSectionHeader(
                        title: 'Recent debates',
                        subtitle: '${filtered.length} total',
                      ),
                    ],
                    body: filtered.isEmpty
                        ? AppReveal(
                            index: _revealRowStart,
                            child: _buildEmptyState(),
                          )
                        : _buildGroup(filtered, large),
                    detail: large ? _buildDetail(selected, contentTop) : null,
                  );
                },
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildHeader(context, topInset, gutter),
            ),
          ],
        ),
      ),
    );
  }

  /// Pinned glass bar: title + filter button with the active dot.
  Widget _buildHeader(BuildContext context, double topInset, double gutter) {
    final c = context.colors;
    return GlassBar(
      padding: EdgeInsets.fromLTRB(
        gutter,
        topInset + AppSpacing.md,
        gutter,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('History', style: context.text.titleMedium),
          ),
          Stack(
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
                  child: IgnorePointer(
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: c.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// The scrolling list (plus, on large layouts, the detail pane beside it).
  Widget _buildPanes({
    required String revealKey,
    required bool large,
    required double gutter,
    required double contentTop,
    required List<Widget> top,
    required Widget body,
    Widget? detail,
  }) {
    final c = context.colors;

    final list = ListView(
      padding: EdgeInsets.fromLTRB(
        gutter,
        contentTop,
        large ? 0 : gutter,
        AppSpacing.xxxl,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        StaggeredColumn(key: ValueKey(revealKey), children: top),
        body,
      ],
    );

    if (!large || detail == null) return list;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 5, child: list),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            contentTop - AppSpacing.lg,
            AppSpacing.xxl,
            0,
          ),
          child: SizedBox(width: 1, child: ColoredBox(color: c.border)),
        ),
        Expanded(
          flex: 7,
          child: Padding(
            padding: EdgeInsets.only(right: gutter),
            child: detail,
          ),
        ),
      ],
    );
  }

  /// Right pane on large layouts: the selected debate's review, or a prompt.
  Widget _buildDetail(DebateRecord? record, double contentTop) {
    return AnimatedSwitcher(
      duration: AppDurations.normal,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      child: record == null
          ? Padding(
              key: const ValueKey('none'),
              padding: EdgeInsets.only(top: contentTop - AppSpacing.lg),
              child: const AppEmptyState(
                icon: AppIcons.history,
                title: 'Pick a debate',
                message: 'Its score, feedback and transcript show up here.',
              ),
            )
          : SingleChildScrollView(
              key: ValueKey(record.id),
              padding: EdgeInsets.fromLTRB(0, contentTop, 0, AppSpacing.xxxl),
              child: DebateReviewBody(
                debateData: _reviewData(record),
                embedded: true,
              ),
            ),
    );
  }

  /// Segmented control for the debate mode (All + the three modes).
  Widget _buildModeControl() {
    return AppSegmented(
      labels: ['All', for (final m in _modes) HistoryDebateCard.modeLabel(m)],
      icons: [AppIcons.history, for (final m in _modes) AppIcons.forMode(m)],
      index: _modeIndex,
      onChanged: _setModeIndex,
    );
  }

  Widget _buildGroup(List<DebateRecord> filtered, bool large) {
    return AppListGroup(
      children: [
        for (var i = 0; i < filtered.length; i++)
          AppReveal(
            key: ValueKey(filtered[i].id),
            index: _revealRowStart + math.min(i, _revealCap),
            child: _buildRow(filtered[i], large),
          ),
      ],
    );
  }

  // ── Shared ──

  /// A history row, swipe-to-delete for everything but ranked debates.
  Widget _buildRow(DebateRecord record, bool large) {
    final c = context.colors;
    final compact = context.isCompact;
    final row = HistoryDebateCard(
      record: record,
      compact: compact,
      selected: large && record.id == _selectedId,
      onTap: () {
        if (large) {
          setState(() => _selectedId = record.id);
        } else {
          _openRecord(record);
        }
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
        child: Icon(AppIcons.delete, size: 20, color: c.negativeText),
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
      // Opaque so the delete background stays hidden until the swipe starts.
      child: ColoredBox(color: compact ? c.background : c.surface, child: row),
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
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
      ),
    );
  }
}
