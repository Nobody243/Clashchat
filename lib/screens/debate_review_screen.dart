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

    // Phones get the §10 composition; wide and embedded keep the card layout.
    if (context.isCompact && !embedded) {
      return _PhoneReview(
        topic: topic,
        stance: stance,
        difficulty: hasDifficulty ? difficulty : null,
        date: parsedDate,
        score: score,
        summary: summary,
        strengths: strengths,
        weaknesses: weaknesses,
        messages: messages,
        mode: mode,
        pointsEarned: isRanked ? pointsEarned : null,
        durationMinutes: durationMinutes,
      );
    }

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

// ── Phone composition (DESIGN.md §10) ──

/// Phone review: the score is the design. Title line, 72 px mono numeral with
/// its band label, a hairline meta row, the summary, feedback as left-ruled
/// paragraphs under small-caps labels, then the transcript as ruled blocks
/// (ClashBot, coach) and flame bubbles (you). No cards, rings or pills.
class _PhoneReview extends StatelessWidget {
  const _PhoneReview({
    required this.topic,
    required this.stance,
    required this.difficulty,
    required this.date,
    required this.score,
    required this.summary,
    required this.strengths,
    required this.weaknesses,
    required this.messages,
    required this.mode,
    required this.pointsEarned,
    required this.durationMinutes,
  });

  final String topic;
  final String stance;

  /// Null when the record did not store one.
  final String? difficulty;
  final DateTime? date;
  final int score;
  final String summary;
  final List<String> strengths;
  final List<String> weaknesses;
  final List messages;
  final DebateMode? mode;

  /// Null when the debate was not ranked.
  final int? pointsEarned;
  final int? durationMinutes;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final days = today.difference(day).inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (date.year == now.year) return DateFormat('d MMM').format(date);
    return DateFormat('d MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final band = scoreBand(score);
    final points = pointsEarned;

    final title = stance == 'Unknown' ? topic : '$topic · $stance';
    final eyebrow = [
      if (mode != null) HistoryDebateCard.modeLabel(mode!),
      ?difficulty,
      if (date != null) _formatDate(date!),
    ].join(' · ');

    var bandLine = band.label.toUpperCase();
    if (points != null && points > 0) bandLine += ' · +$points PTS';

    return StaggeredColumn(
      children: [
        // Title line.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIconButton(
              icon: AppIcons.back,
              tooltip: 'Back',
              onPressed: () => Navigator.pop(context),
            ),
            AppSpacing.hSm,
            Expanded(
              child: Padding(
                // Centre the first text line on the 44 px button.
                padding: const EdgeInsets.only(top: 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall,
                    ),
                    if (eyebrow.isNotEmpty) ...[
                      AppSpacing.vXs,
                      Text(
                        eyebrow,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.labelSmall?.copyWith(
                          color: c.textHint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        AppSpacing.vXxxl,

        // Score.
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('$score', style: context.mono(size: 72, height: 1)),
            AppSpacing.hSm,
            Text(
              '/100',
              style: context.text.labelLarge?.copyWith(color: c.textHint),
            ),
          ],
        ),
        AppSpacing.vSm,
        Text(
          bandLine,
          style: context.text.labelSmall?.copyWith(
            color: band.color(context),
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        AppSpacing.vXxl,

        // Meta: hairline row of three mono values.
        Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: c.border),
              bottom: BorderSide(color: c.border),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _MetaCell(
                  label: 'Messages',
                  value: '${messages.length}',
                ),
              ),
              Expanded(
                child: _MetaCell(
                  label: 'Length',
                  value:
                      durationMinutes == null ? '—' : '$durationMinutes min',
                ),
              ),
              Expanded(
                child: _MetaCell(label: 'Opponent', value: difficulty ?? '—'),
              ),
            ],
          ),
        ),

        // Summary.
        if (summary.isNotEmpty) ...[
          AppSpacing.vXxl,
          Text(
            summary,
            style: context.text.bodyMedium?.copyWith(color: c.textSecondary),
          ),
        ],

        // Feedback: left-ruled paragraphs under small-caps labels.
        if (strengths.isNotEmpty) ...[
          _RuledLabel('What worked', color: c.positiveText),
          for (final p in strengths) ...[
            _RuledBlock(
              color: c.positiveText,
              child: Text(p, style: context.text.bodyMedium),
            ),
            AppSpacing.vMd,
          ],
        ],
        if (weaknesses.isNotEmpty) ...[
          _RuledLabel('What to sharpen', color: c.warningText),
          for (final p in weaknesses) ...[
            _RuledBlock(
              color: c.warningText,
              child: Text(p, style: context.text.bodyMedium),
            ),
            AppSpacing.vMd,
          ],
        ],

        // Transcript.
        const AppSectionLabel('Transcript'),
        if (messages.isEmpty)
          Text(
            'Transcript unavailable. Older debates did not save their '
            'conversation.',
            style: context.text.bodySmall?.copyWith(color: c.textHint),
          )
        else
          _PhoneTranscript(messages: messages),
      ],
    );
  }
}

/// Mono value over a small-caps caption: one cell of the meta row.
class _MetaCell extends StatelessWidget {
  const _MetaCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.mono(size: 15),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.labelSmall?.copyWith(
            color: c.textHint,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// [AppSectionLabel] in a semantic colour (the kit label is always muted).
class _RuledLabel extends StatelessWidget {
  const _RuledLabel(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(top: AppSpacing.xxl, bottom: AppSpacing.sm),
      child: Text(
        text.toUpperCase(),
        style: context.text.labelSmall?.copyWith(
          color: color,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Left-ruled text block: a 2 px rule in [color], an optional small-caps
/// label, then the child. The phone's replacement for a card.
class _RuledBlock extends StatelessWidget {
  const _RuledBlock({required this.color, required this.child, this.label});

  final Color color;
  final Widget child;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: color, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: context.text.labelSmall?.copyWith(
                color: color,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          child,
        ],
      ),
    );
  }
}

/// Phone transcript: ClashBot as ruled blocks, you as flame bubbles, coach
/// tips as info-coloured ruled blocks.
class _PhoneTranscript extends StatelessWidget {
  const _PhoneTranscript({required this.messages});

  final List messages;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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

      if (isUser) {
        children.add(_FlameBubble(text: text));
      } else {
        children.add(
          _RuledBlock(
            color: c.borderStrong,
            label: 'CLASHBOT',
            child: Text(text, style: context.text.bodyMedium),
          ),
        );
      }
      if (coachTip != null && coachTip.isNotEmpty) {
        children.add(AppSpacing.vMd);
        children.add(
          _RuledBlock(
            color: c.infoText,
            label: 'COACH',
            child: Text(
              coachTip,
              style: context.text.bodySmall?.copyWith(color: c.infoText),
            ),
          ),
        );
      }
      children.add(AppSpacing.vLg);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

/// Your message: accent fill, 16 px corners with a 5 px bottom-right tail.
class _FlameBubble extends StatelessWidget {
  const _FlameBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: constraints.maxWidth * 0.82),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg - 2,
                vertical: AppSpacing.md - 2,
              ),
              decoration: BoxDecoration(
                color: c.accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(5),
                ),
              ),
              child: Text(
                text,
                style: context.text.bodyMedium?.copyWith(color: c.onAccent),
              ),
            ),
          ),
        );
      },
    );
  }
}
