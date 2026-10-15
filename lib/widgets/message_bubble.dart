import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/chat_message.dart';
import '../ui/ui.dart';

/// One debate message. User turns are an accent fill; AI turns are a raised
/// surface with a hairline. A coach tip (learning mode) renders as its own
/// raised card directly under the AI bubble.
class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  /// Previous message came from the same sender (tightens the top gap).
  final bool isGrouped;

  /// This is the last message of its sender run; shows the timestamp.
  final bool isLastInGroup;
  final double maxWidthFactor;

  const MessageBubble({
    super.key,
    required this.message,
    this.isGrouped = false,
    this.isLastInGroup = true,
    this.maxWidthFactor = 0.78,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final isUser = message.isUser;
    final maxWidth = MediaQuery.sizeOf(context).width * maxWidthFactor;

    final bubble = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isUser ? c.accent : c.surfaceRaised,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 6),
          bottomRight: Radius.circular(isUser ? 6 : 18),
        ),
        border: isUser ? null : Border.all(color: c.border),
      ),
      child: Text(
        message.text,
        style: text.bodyMedium?.copyWith(
          color: isUser ? c.onAccent : c.textPrimary,
        ),
      ),
    );

    final tip = message.coachTip;
    final hasTip = !isUser && tip != null && tip.trim().isNotEmpty;

    return AppReveal(
      child: Padding(
        padding: EdgeInsets.only(
          top: isGrouped ? AppSpacing.xs : AppSpacing.md,
        ),
        child: Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                bubble,
                if (hasTip) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _CoachTipCard(tip: tip),
                ],
                if (isLastInGroup) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: Text(
                      DateFormat('h:mm a').format(message.timestamp),
                      style: text.labelSmall?.copyWith(color: c.textHint),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CoachTipCard extends StatelessWidget {
  const _CoachTipCard({required this.tip});

  final String tip;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    return AppCard(
      level: AppCardLevel.raised,
      padding: const EdgeInsets.all(AppSpacing.md),
      radius: AppRadius.mdAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.coachTipFilled, size: 16, color: c.infoText),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(
                'Coach',
                style: text.labelMedium?.copyWith(color: c.infoText),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Text(tip, style: text.bodySmall),
        ],
      ),
    );
  }
}
