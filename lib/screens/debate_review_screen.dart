import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../models/debate_mode.dart';
import '../ui/ui.dart';
import '../widgets/feedback_section.dart';

class DebateReviewScreen extends StatelessWidget {
  final Map<String, dynamic> debateData;

  const DebateReviewScreen({super.key, required this.debateData});

  Color _scoreColor(BuildContext context, int score) {
    final c = context.colors;
    if (score >= 70) return c.positiveText;
    if (score >= 40) return c.warningText;
    return c.negativeText;
  }

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

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        leading: Center(
          child: AppIconButton(
            icon: AppIcons.back,
            tooltip: 'Back',
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          topic,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.titleSmall,
        ),
        bottom: pills.isEmpty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(44),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    0,
                    AppSpacing.gutter,
                    AppSpacing.md,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(spacing: AppSpacing.sm, children: pills),
                  ),
                ),
              ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
                vertical: AppSpacing.lg,
              ),
              children: [
                StaggeredColumn(
                  children: [
                    // Score card
                    AppCard(
                      child: Row(
                        children: [
                          ScoreRing(
                            value: score.toDouble(),
                            size: 120,
                            label: 'out of 100',
                            color: _scoreColor(context, score),
                          ),
                          AppSpacing.hXl,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (parsedDate != null) ...[
                                  Text(
                                    _formatDate(parsedDate),
                                    style: context.text.labelSmall?.copyWith(
                                      color: c.textSecondary,
                                    ),
                                  ),
                                  AppSpacing.vMd,
                                ],
                                _MetaLine(
                                  icon: AppIcons.messages,
                                  value: '${messages.length}',
                                  unit: 'messages',
                                ),
                                if (durationMinutes != null) ...[
                                  AppSpacing.vSm,
                                  _MetaLine(
                                    icon: AppIcons.timer,
                                    value: '$durationMinutes',
                                    unit: 'min',
                                  ),
                                ],
                                if (isRanked) ...[
                                  AppSpacing.vMd,
                                  AppPill(
                                    mono: true,
                                    icon: AppIcons.points,
                                    tone: pointsEarned >= 0
                                        ? AppPillTone.positive
                                        : AppPillTone.negative,
                                    label:
                                        '${pointsEarned > 0 ? '+' : ''}$pointsEarned',
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.vXxl,

                    // Summary
                    if (summary.isNotEmpty) ...[
                      const AppSectionHeader(title: 'Summary'),
                      AppCard(
                        child: Text(
                          summary,
                          style: context.text.bodyMedium?.copyWith(
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      AppSpacing.vXxl,
                    ],

                    // Feedback. FeedbackSection renders its own heading, so
                    // the section titles live there.
                    FeedbackSection(
                      icon: AppIcons.strengths,
                      color: c.positiveText,
                      title: 'What worked',
                      points: strengths,
                    ),
                    FeedbackSection(
                      icon: AppIcons.weaknesses,
                      color: c.negativeText,
                      title: 'What to sharpen',
                      points: weaknesses,
                    ),
                    if (strengths.isNotEmpty || weaknesses.isNotEmpty)
                      AppSpacing.vSm,

                    // Transcript
                    const AppSectionHeader(title: 'Transcript'),
                    if (messages.isEmpty)
                      const AppEmptyState(
                        compact: true,
                        icon: AppIcons.messages,
                        title: 'Transcript unavailable',
                        message:
                            'Older debates did not save their conversation.',
                      )
                    else
                      _Transcript(messages: messages),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}

/// Icon + mono number + unit, e.g. "12 messages".
class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.icon,
    required this.value,
    required this.unit,
  });

  final IconData icon;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Icon(icon, size: 16, color: c.textHint),
        AppSpacing.hSm,
        Text(value, style: context.mono(size: 16)),
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
        final maxWidth = constraints.maxWidth * 0.78;
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
            children.add(_CoachTip(tip: coachTip));
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

class _CoachTip extends StatelessWidget {
  const _CoachTip({required this.tip});

  final String tip;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
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
    );
  }
}
