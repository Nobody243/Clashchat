import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/chat_message.dart';
import '../models/debate_mode.dart';
import '../ui/ui.dart';
import '../widgets/feedback_section.dart';
import '../widgets/history_debate_card.dart';

/// Full-screen review of a finished debate: a reading-width page whose
/// content is [DebateReviewBody].
class DebateReviewScreen extends StatelessWidget {
  final Map<String, dynamic> debateData;

  const DebateReviewScreen({super.key, required this.debateData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: AppPage(
        width: AppPageWidth.content,
        child: DebateReviewBody(debateData: debateData),
      ),
    );
  }
}

/// The review itself: header (back button, topic, pills), score hero,
/// optional summary, feedback and transcript, entering as one staggered
/// reveal. Reusable inside a master–detail pane with [embedded] = true,
/// which hides the back button. Non-scrolling: the host scrolls.
class DebateReviewBody extends StatelessWidget {
  const DebateReviewBody({
    super.key,
    required this.debateData,
    this.embedded = false,
  });

  final Map<String, dynamic> debateData;

  /// True when shown beside a list rather than as its own route.
  final bool embedded;

  /// Mode is optional in older records; derive it only when we can.
  DebateMode? _modeOf(Map<String, dynamic> data) {
    final raw = data['mode'];
    if (raw is DebateMode) return raw;
    if (raw is String) {
      for (final m in DebateMode.values) {
        if (m.name == raw) return m;
      }
    }
    if (data['isRanked'] == true) return DebateMode.ranked;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    final topic = debateData['topic'] as String? ?? 'Unknown Topic';
    final stance = debateData['stance'] as String? ?? 'Unknown';
    final difficulty = debateData['difficulty'] as String? ?? 'Not recorded';
    final dateStr = debateData['date'] as String? ?? '';
    final score = (debateData['score'] as num?)?.toInt() ?? 0;
    final summary = debateData['summary'] as String? ?? '';
    final strengths = List<String>.from(debateData['strengths'] ?? []);
    final weaknesses = List<String>.from(debateData['weaknesses'] ?? []);
    final messages = debateData['messages'] as List? ?? [];
    final mode = _modeOf(debateData);
    final isRanked = mode == DebateMode.ranked;
    final pointsEarned = (debateData['pointsEarned'] as num?)?.toInt() ?? 0;
    final durationMinutes =
        (debateData['durationMinutes'] as num?)?.toInt() ??
            (debateData['timerMinutes'] as num?)?.toInt();
    final hasDifficulty =
        difficulty.isNotEmpty && difficulty != 'Not recorded';

    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(dateStr);
    } catch (_) {}

    final pills = <Widget>[
      if (stance != 'Unknown') AppPill.stance(stance),
      if (mode != null) AppPill.mode(mode),
      if (hasDifficulty) AppPill.difficulty(difficulty),
    ];

    return StaggeredColumn(
      children: [
        // Header: back + topic + pills.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!embedded) ...[
              AppIconButton(
                icon: AppIcons.back,
                tooltip: 'Back',
                onPressed: () => Navigator.pop(context),
              ),
              AppSpacing.hSm,
            ],
            Expanded(
              child: Padding(
                // Centre the first text line on the 44 px button.
                padding: EdgeInsets.only(top: embedded ? 0 : 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall,
                    ),
                    if (pills.isNotEmpty) ...[
                      AppSpacing.vSm,
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: pills,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        AppSpacing.vXxl,

        // Score hero.
        _ScoreHero(
          score: score,
          date: parsedDate,
          messageCount: messages.length,
          durationMinutes: durationMinutes,
          pointsEarned: isRanked ? pointsEarned : null,
        ),
        AppSpacing.vXxl,

        // Summary.
        if (summary.isNotEmpty) ...[
          const AppSectionHeader(title: 'Summary'),
          AppCard(
            child: Text(
              summary,
              style: context.text.bodyMedium?.copyWith(color: c.textPrimary),
            ),
          ),
          AppSpacing.vXxl,
        ],

        // Feedback. FeedbackSection renders its own heading.
        FeedbackSection(
          icon: AppIcons.strengths,
          color: c.positiveText,
          title: 'What worked',
          points: strengths,
        ),
        if (strengths.isNotEmpty) AppSpacing.vXxl,
        FeedbackSection(
          icon: AppIcons.weaknesses,
          color: c.negativeText,
          title: 'What to sharpen',
          points: weaknesses,
        ),
        if (weaknesses.isNotEmpty) AppSpacing.vXxl,

        // Transcript.
        const AppSectionHeader(title: 'Transcript'),
        if (messages.isEmpty)
          const AppCard(
            padding: EdgeInsets.zero,
            child: AppEmptyState(
              compact: true,
              icon: AppIcons.messages,
              title: 'Transcript unavailable',
              message: 'Older debates did not save their conversation.',
            ),
          )
        else
          _Transcript(messages: messages),
      ],
    );
  }
}

/// Hero card: band-coloured score ring on the left, date, counts and the
/// ranked points pill on the right. The pill moves under the counts when the
/// card is too narrow to hold it beside them.
class _ScoreHero extends StatelessWidget {
  const _ScoreHero({
    required this.score,
    required this.date,
    required this.messageCount,
    required this.durationMinutes,
    required this.pointsEarned,
  });

  final int score;
  final DateTime? date;
  final int messageCount;
  final int? durationMinutes;

  /// Null when the debate was not ranked.
  final int? pointsEarned;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final days = today.difference(day).inDays;

    if (days == 0) return 'Today, ${DateFormat.jm().format(date)}';
    if (days == 1) return 'Yesterday';
    if (days < 7) return '$days days ago';
    return DateFormat.yMMMd().format(date);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final points = pointsEarned;
    final pointsPill = points == null
        ? null
        : AppPill(
            mono: true,
            icon: AppIcons.points,
            tone: points >= 0 ? AppPillTone.positive : AppPillTone.negative,
            label: '${points > 0 ? '+' : ''}$points',
          );

    return AppCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final roomy = constraints.maxWidth >= 440;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ScoreRing(
                value: score.toDouble(),
                size: 120,
                label: 'out of 100',
                color: HistoryDebateCard.scoreColor(context, score),
              ),
              AppSpacing.hXl,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (date != null) ...[
                      Text(
                        _formatDate(date!),
                        style: context.text.labelSmall?.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                      AppSpacing.vMd,
                    ],
                    _MetaLine(
                      icon: AppIcons.messages,
                      value: messageCount,
                      unit: 'messages',
                    ),
                    if (durationMinutes != null) ...[
                      AppSpacing.vSm,
                      _MetaLine(
                        icon: AppIcons.timer,
                        value: durationMinutes!,
                        unit: 'min',
                      ),
                    ],
                    if (pointsPill != null && !roomy) ...[
                      AppSpacing.vMd,
                      pointsPill,
                    ],
                  ],
                ),
              ),
              if (pointsPill != null && roomy) ...[
                AppSpacing.hMd,
                Align(alignment: Alignment.topRight, child: pointsPill),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Icon + counting mono number + unit, e.g. "12 messages".
class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.icon,
    required this.value,
    required this.unit,
  });

  final IconData icon;
  final int value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Icon(icon, size: 16, color: c.textHint),
        AppSpacing.hSm,
        AnimatedNumber(value: value, size: 16),
        AppSpacing.hXs,
        Text(
          unit,
          style: context.text.bodySmall?.copyWith(color: c.textSecondary),
        ),
      ],
    );
  }
}

class _Transcript extends StatelessWidget {
  const _Transcript({required this.messages});

  final List messages;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = math.min(constraints.maxWidth * 0.78, 640.0);
        final children = <Widget>[];
        for (final raw in messages) {
          final bool isUser;
          final String text;
          final String? coachTip;
          if (raw is ChatMessage) {
            isUser = raw.isUser;
            text = raw.text;
            coachTip = raw.coachTip;
          } else {
            final msg = raw as Map<String, dynamic>? ?? {};
            isUser = msg['isUser'] as bool? ?? false;
            text = msg['text'] as String? ?? '';
            coachTip = msg['coachTip'] as String?;
          }
          children.add(
            _Bubble(text: text, isUser: isUser, maxWidth: maxWidth),
          );
          if (coachTip != null && coachTip.isNotEmpty) {
            children.add(_CoachTip(tip: coachTip, maxWidth: maxWidth));
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      },
    );
  }
}

/// Chat bubble: user in accent with a 6 px bottom-right tail, AI on the
/// raised surface with a 6 px bottom-left tail.
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.isUser,
    required this.maxWidth,
  });

  final String text;
  final bool isUser;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const big = Radius.circular(18);
    const tail = Radius.circular(6);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg - 2,
            vertical: AppSpacing.md - 2,
          ),
          decoration: BoxDecoration(
            color: isUser ? c.accent : c.surfaceRaised,
            border: isUser ? null : Border.all(color: c.border),
            borderRadius: BorderRadius.only(
              topLeft: big,
              topRight: big,
              bottomLeft: isUser ? big : tail,
              bottomRight: isUser ? tail : big,
            ),
          ),
          child: Text(
            text,
            style: context.text.bodyMedium?.copyWith(
              color: isUser ? c.onAccent : c.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Coach tip that follows an AI message, aligned under its bubble.
class _CoachTip extends StatelessWidget {
  const _CoachTip({required this.tip, required this.maxWidth});

  final String tip;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: AppCard(
          level: AppCardLevel.raised,
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          radius: AppRadius.mdAll,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(AppIcons.coachTipFilled, size: 18, color: c.infoText),
              AppSpacing.hSm,
              Expanded(
                child: Text(
                  tip,
                  style: context.text.bodySmall?.copyWith(
                    color: c.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
