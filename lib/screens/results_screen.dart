import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'home_screen.dart';
import '../core/responsive_layout.dart';
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

  String get _durationLabel {
    final minutes = widget.durationMinutes;
    if (minutes == null) return '—';
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth > ResponsiveLayout.desktopBreakpoint;
    final isRanked = widget.mode == DebateMode.ranked;
    final pointsNegative = widget.pointsEarned < 0;
    final pointsLabel =
        '${pointsNegative ? '' : '+'}${widget.pointsEarned} pts';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.isFromHistory,
        title: const Text('Debate results'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.gutter),
            child: AppPill.mode(widget.mode),
          ),
        ],
      ),
      body: Container(
        color: c.background,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 640 : double.infinity,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                  vertical: AppSpacing.xxl,
                ),
                child: StaggeredColumn(
                  children: [
                    // ── Score ──
                    const Center(child: AppOverline('Final score')),
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: ScoreRing(
                        value: widget.score.toDouble(),
                        size: 200,
                        label: 'out of 100',
                        // Same rule as history rows: >=70 positive, 40-69 warning, <40 negative.
                        color: widget.score >= 70
                            ? c.positiveText
                            : widget.score >= 40
                                ? c.warningText
                                : c.negativeText,
                      ),
                    ),
                    if (widget.summary.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Text(
                            widget.summary,
                            textAlign: TextAlign.center,
                            style: text.bodyMedium?.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (isRanked) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Center(
                        child: AppPill(
                          tone: pointsNegative
                              ? AppPillTone.negative
                              : AppPillTone.rank,
                          mono: true,
                          icon: AppIcons.points,
                          label: pointsLabel,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxxl),

                    // ── Stats ──
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ResultStatCard(
                              label: 'Messages',
                              value: '${widget.messages.length}',
                              icon: AppIcons.messages,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: ResultStatCard(
                              label: 'Duration',
                              value: _durationLabel,
                              icon: AppIcons.timer,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: ResultStatCard(
                              label: 'Difficulty',
                              value: widget.difficulty,
                              icon: AppIcons.forDifficulty(widget.difficulty),
                              child: AppPill.difficulty(
                                widget.difficulty,
                                withIcon: false,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // ── Feedback ──
                    FeedbackSection(
                      title: 'What worked',
                      points: widget.strengths,
                      icon: AppIcons.checkCircle,
                      color: c.positiveText,
                      emptyTitle: 'No strengths recorded',
                      emptyMessage: 'The judge did not single anything out.',
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    FeedbackSection(
                      title: 'What to sharpen',
                      points: widget.weaknesses,
                      icon: AppIcons.weaknesses,
                      color: c.warningText,
                      emptyTitle: 'Nothing to sharpen',
                      emptyMessage: 'The judge found no weak points.',
                    ),

                    // ── Transcript ──
                    if (widget.messages.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxl),
                      AppSectionHeader(
                        title: 'Transcript',
                        subtitle: '${widget.messages.length} messages',
                        actionLabel: _showTranscript ? 'Hide' : 'Show',
                        onAction: () => setState(
                          () => _showTranscript = !_showTranscript,
                        ),
                      ),
                      if (_showTranscript)
                        _Transcript(messages: widget.messages),
                    ],

                    // ── Actions ──
                    if (!widget.isFromHistory) ...[
                      const SizedBox(height: AppSpacing.xxxl),
                      AppButton.primary(
                        label: 'Debate again',
                        icon: AppIcons.shuffle,
                        onPressed: _debateAgain,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppButton.secondary(
                        label: 'Back to home',
                        icon: AppIcons.home,
                        onPressed: _goHome,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      msg.isUser ? AppIcons.user : AppIcons.ai,
                      size: 14,
                      color: msg.isUser ? c.accent : c.textHint,
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                    Text(
                      msg.isUser ? 'You' : 'Opponent',
                      style: text.labelMedium?.copyWith(
                        color: msg.isUser ? c.accent : c.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs + 2),
                Text(msg.text, style: text.bodySmall),
                if (msg.coachTip != null && msg.coachTip!.trim().isNotEmpty) ...[
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
                          style: text.bodySmall?.copyWith(color: c.infoText),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
