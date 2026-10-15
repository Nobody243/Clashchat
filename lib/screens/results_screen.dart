import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'home_screen.dart';
import '../models/chat_message.dart';
import '../models/debate_mode.dart';
import '../widgets/feedback_section.dart';
import '../widgets/result_stat_card.dart';
import '../ui/ui.dart';

class ResultsScreen extends StatefulWidget {
  final String topic;
  final String stance;
  final List<ChatMessage> messages;
  final int score;
  final DebateMode mode;
  final int pointsEarned;
  final List<String> strengths;
  final List<String> weaknesses;
  final String summary;
  final String difficulty;
  final bool isFromHistory;

  /// Minutes the debate ran. Null when unknown (older history records).
  final int? durationMinutes;

  const ResultsScreen({
    super.key,
    required this.topic,
    required this.stance,
    required this.messages,
    required this.score,
    this.mode = DebateMode.casual,
    this.pointsEarned = 0,
    this.strengths = const [],
    this.weaknesses = const [],
    this.summary = '',
    this.difficulty = 'Medium',
    this.isFromHistory = false,
    this.durationMinutes,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _showTranscript = false;

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (_) => false,
    );
  }

  void _debateAgain() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          topic: widget.topic,
          stance: widget.stance,
          difficulty: widget.difficulty,
          timerMinutes: null,
          mode: DebateMode.casual,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  bool get _isRanked => widget.mode == DebateMode.ranked;

  bool get _celebrate => widget.score >= 70 || widget.pointsEarned > 0;

  Color _scoreColor(BuildContext context) {
    final c = context.colors;
    // Same rule as history rows: >=70 positive, 40-69 warning, <40 negative.
    if (widget.score >= 70) return c.positiveText;
    if (widget.score >= 40) return c.warningText;
    return c.negativeText;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final twoPane = context.screenWidth >= AppBreakpoints.medium;
    final gutter = context.pageGutter;

    final column = twoPane ? _buildWide(context) : _buildCompact(context);

    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Page shell (same contract as AppPage: backdrop, safe area,
          // centered max-width column, responsive gutters). Hand-rolled so
          // the stage lights can be gated for widget tests.
          AppBackdrop(
            intensity: 0.8,
            lights: true,
            child: SafeArea(
              child: SingleChildScrollView(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: twoPane
                          ? AppPageWidth.wide.maxWidth
                          : AppPageWidth.content.maxWidth,
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        gutter,
                        AppSpacing.lg,
                        gutter,
                        AppSpacing.xxxl,
                      ),
                      child: column,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: ParticleBurst(
              play: _celebrate,
              origin: const Alignment(0, -0.45),
            ),
          ),
        ],
      ),
    );
  }

  // ── Layouts ────────────────────────────────────────────────────────────

  Widget _buildCompact(BuildContext context) {
    return StaggeredColumn(
      children: [
        _buildTopRow(context),
        const SizedBox(height: AppSpacing.lg),
        _buildHero(context),
        const SizedBox(height: AppSpacing.xxxl),
        _buildStats(context),
        const SizedBox(height: AppSpacing.xxl),
        _buildStrengths(context),
        const SizedBox(height: AppSpacing.xxl),
        _buildWeaknesses(context),
        if (widget.messages.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          _buildTranscript(context),
        ],
        if (!widget.isFromHistory) ...[
          const SizedBox(height: AppSpacing.xxxl),
          _buildActions(context),
        ],
      ],
    );
  }

  Widget _buildWide(BuildContext context) {
    return StaggeredColumn(
      children: [
        _buildTopRow(context),
        const SizedBox(height: AppSpacing.xl),
        Bento(
          collapseBelow: 0,
          gap: AppSpacing.xxl,
          rows: [
            [
              BentoTile(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.xxxl,
                      ),
                      child: _buildHero(context),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildStats(context),
                  ],
                ),
              ),
              BentoTile(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStrengths(context),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildWeaknesses(context),
                    if (widget.messages.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxl),
                      _buildTranscript(context),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
        if (!widget.isFromHistory) ...[
          const SizedBox(height: AppSpacing.xxxl),
          _buildActions(context),
        ],
      ],
    );
  }

  // ── Blocks ─────────────────────────────────────────────────────────────

  Widget _buildTopRow(BuildContext context) {
    final text = context.text;
    return Row(
      children: [
        if (widget.isFromHistory) ...[
          AppIconButton(
            icon: AppIcons.back,
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        Expanded(
          child: Text(
            'Debate results',
            style: text.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        AppPill.mode(widget.mode),
      ],
    );
  }

  Widget _buildHero(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final pointsNegative = widget.pointsEarned < 0;
    final pointsLabel =
        '${pointsNegative ? '' : '+'}${widget.pointsEarned} pts';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppOverline('Final score'),
        const SizedBox(height: AppSpacing.lg),
        ScoreRing(
          value: widget.score.toDouble(),
          size: 220,
          label: 'out of 100',
          color: _scoreColor(context),
          animate: true,
        ),
        if (widget.summary.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Text(
              widget.summary,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: c.textSecondary),
            ),
          ),
        ],
        if (_isRanked) ...[
          const SizedBox(height: AppSpacing.lg),
          AppPill(
            tone: pointsNegative ? AppPillTone.negative : AppPillTone.rank,
            mono: true,
            icon: AppIcons.points,
            label: pointsLabel,
          ),
          // Rank progress card deliberately omitted: this screen is not
          // given the player's rank or current points, and we do not
          // invent data.
        ],
      ],
    );
  }

  Widget _buildStats(BuildContext context) {
    final minutes = widget.durationMinutes;
    return Bento(
      // Always a row: this Bento nests inside the two-pane Bento on wide
      // screens, where a LayoutBuilder would break intrinsic sizing.
      collapseBelow: 0,
      gap: AppSpacing.md,
      rows: [
        [
          BentoTile(
            child: ResultStatCard(
              label: 'Messages',
              value: '${widget.messages.length}',
              numericValue: widget.messages.length,
              icon: AppIcons.messages,
            ),
          ),
          BentoTile(
            child: ResultStatCard(
              label: 'Duration',
              value: minutes == null ? '—' : '$minutes min',
              numericValue: minutes,
              suffix: ' min',
              icon: AppIcons.timer,
            ),
          ),
          BentoTile(
            child: ResultStatCard(
              label: 'Difficulty',
              value: widget.difficulty,
              icon: AppIcons.forDifficulty(widget.difficulty),
              child: AppPill.difficulty(widget.difficulty, withIcon: false),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStrengths(BuildContext context) => FeedbackSection(
        title: 'What worked',
        points: widget.strengths,
        icon: AppIcons.checkCircle,
        color: context.colors.positiveText,
        emptyTitle: 'No strengths recorded',
        emptyMessage: 'The judge did not single anything out.',
      );

  Widget _buildWeaknesses(BuildContext context) => FeedbackSection(
        title: 'What to sharpen',
        points: widget.weaknesses,
        icon: AppIcons.weaknesses,
        color: context.colors.warningText,
        emptyTitle: 'Nothing to sharpen',
        emptyMessage: 'The judge found no weak points.',
      );

  Widget _buildTranscript(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSectionHeader(
          title: 'Transcript',
          subtitle: '${widget.messages.length} messages',
          actionLabel: _showTranscript ? 'Hide' : 'Show',
          onAction: () => setState(() => _showTranscript = !_showTranscript),
        ),
        AnimatedSize(
          duration: AppDurations.normal,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _showTranscript
              ? _Transcript(messages: widget.messages)
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final again = AppButton.primary(
      label: 'Debate again',
      icon: AppIcons.shuffle,
      onPressed: _debateAgain,
    );
    final home = AppButton.secondary(
      label: 'Back to home',
      icon: AppIcons.home,
      onPressed: _goHome,
    );

    if (context.isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          again,
          const SizedBox(height: AppSpacing.md),
          home,
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: again),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: home),
        ],
      ),
    );
  }
}

class _Transcript extends StatelessWidget {
  const _Transcript({required this.messages});

  final List<ChatMessage> messages;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;

    return AppListGroup(
      children: [
        for (final msg in messages)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md + 2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIconTile(
                  icon: msg.isUser ? AppIcons.user : AppIcons.ai,
                  size: 28,
                  iconSize: 14,
                  color: msg.isUser ? c.accent : c.textSecondary,
                  background: msg.isUser ? c.accentSoft : c.surfaceRaised,
                  radius: const BorderRadius.all(Radius.circular(14)),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.isUser ? 'You' : 'Opponent',
                        style: text.labelMedium?.copyWith(
                          color: msg.isUser ? c.accent : c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(msg.text, style: text.bodySmall),
                      if (msg.coachTip != null &&
                          msg.coachTip!.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Icon(
                                AppIcons.coachTipFilled,
                                size: 14,
                                color: c.infoText,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs + 2),
                            Expanded(
                              child: Text(
                                msg.coachTip!,
                                style: text.bodySmall
                                    ?.copyWith(color: c.infoText),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
