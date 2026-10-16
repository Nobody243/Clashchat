import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/chat_message.dart';
import '../ui/ui.dart';

/// One debate message.
///
/// Wide layouts (the default): user turns are an accent fill; AI turns are a
/// raised surface with a hairline. A coach tip (learning mode) renders as its
/// own raised card directly under the AI bubble. The screen passes a 28 px
/// [leading] avatar for the last bubble of a sender run and sets
/// [reserveLeading] on every bubble so the run stays aligned.
///
/// Phones ([compact], DESIGN.md §10): AI turns are plain text blocks with a
/// 2 px left rule and a small-caps CLASHBOT label; user turns are flame
/// bubbles; a coach tip is a left-ruled block in the info colour labelled
/// COACH. No avatars, no bubble chrome on the AI side.
///
/// New messages enter with a fade, an 8 px rise and a 0.98 → 1 settle.
class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  /// Previous message came from the same sender (tightens the top gap).
  final bool isGrouped;

  /// This is the last message of its sender run; shows the timestamp.
  final bool isLastInGroup;

  /// Max bubble width as a fraction of the screen on compact layouts.
  final double maxWidthFactor;

  /// Max bubble width in px on anything wider than a phone.
  final double wideMaxWidth;

  /// Avatar shown beside the bubble (outer edge). Usually only on the last
  /// bubble of a run. Ignored when [compact].
  final Widget? leading;

  /// Reserve the avatar column even when [leading] is null. Ignored when
  /// [compact].
  final bool reserveLeading;

  /// Play the entrance (fade + rise + settle). Runs once per mount.
  final bool animateIn;

  /// Phone composition: ruled text blocks for the AI, flame bubbles for you.
  final bool compact;

  const MessageBubble({
    super.key,
    required this.message,
    this.isGrouped = false,
    this.isLastInGroup = true,
    this.maxWidthFactor = 0.78,
    this.wideMaxWidth = 640,
    this.leading,
    this.reserveLeading = false,
    this.animateIn = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    Widget child = Padding(
      padding: EdgeInsets.only(
        top: isGrouped ? AppSpacing.xs : (compact ? AppSpacing.lg : AppSpacing.md),
      ),
      child: compact ? _buildCompact(context) : _buildWide(context),
    );

    if (animateIn && !context.reduceMotion) {
      child = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.98, end: 1),
        duration: kRevealDuration,
        curve: Curves.easeOutCubic,
        child: child,
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          alignment:
              isUser ? Alignment.bottomRight : Alignment.bottomLeft,
          child: child,
        ),
      );
    }

    return AppReveal(child: child);
  }

  Widget _timestamp(BuildContext context) => Text(
        DateFormat('h:mm a').format(message.timestamp),
        style: context.text.labelSmall?.copyWith(color: context.colors.textHint),
      );

  // ── Phone ──────────────────────────────────────────────────────────────

  Widget _buildCompact(BuildContext context) {
    final c = context.colors;
    final text = context.text;

    if (message.isUser) {
      final maxWidth = MediaQuery.sizeOf(context).width * 0.86;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
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
                message.text,
                style: text.bodyMedium?.copyWith(color: c.onAccent),
              ),
            ),
          ),
          if (isLastInGroup) ...[
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: _timestamp(context),
            ),
          ],
        ],
      );
    }

    final tip = message.coachTip;
    final hasTip = tip != null && tip.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isGrouped) ...[
          _SmallCaps('ClashBot', color: c.textHint),
          const SizedBox(height: AppSpacing.xs + 2),
        ],
        _RuledBlock(
          color: c.borderStrong,
          child: Text(
            message.text,
            style: text.bodyMedium?.copyWith(color: c.textPrimary),
          ),
        ),
        if (hasTip) ...[
          const SizedBox(height: AppSpacing.md),
          _RuledBlock(
            color: c.infoText,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _SmallCaps('Coach', color: c.infoText),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  tip,
                  style: text.bodySmall?.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
        ],
        if (isLastInGroup) ...[
          const SizedBox(height: AppSpacing.xs + 2),
          Padding(
            // Rule (2) + inset (12) so the stamp sits under the text.
            padding: const EdgeInsets.only(left: 2 + AppSpacing.md),
            child: _timestamp(context),
          ),
        ],
      ],
    );
  }

  // ── Wide (unchanged composition) ───────────────────────────────────────

  Widget _buildWide(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final isUser = message.isUser;
    final maxWidth = context.isCompact
        ? MediaQuery.sizeOf(context).width * maxWidthFactor
        : wideMaxWidth;
    final hasAvatarSlot = reserveLeading || leading != null;

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

    final avatarSlot = SizedBox(width: 28, height: 28, child: leading);

    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser && hasAvatarSlot) ...[
              avatarSlot,
              const SizedBox(width: AppSpacing.sm),
            ],
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    bubble,
                    if (hasTip) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _CoachTipCard(tip: tip),
                    ],
                  ],
                ),
              ),
            ),
            if (isUser && hasAvatarSlot) ...[
              const SizedBox(width: AppSpacing.sm),
              avatarSlot,
            ],
          ],
        ),
        if (isLastInGroup) ...[
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal:
                  AppSpacing.xs + (hasAvatarSlot ? 28 + AppSpacing.sm : 0),
            ),
            child: _timestamp(context),
          ),
        ],
      ],
    );
  }
}

/// Small-caps label ("CLASHBOT", "COACH") in the phone composition.
class _SmallCaps extends StatelessWidget {
  const _SmallCaps(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: context.text.labelSmall?.copyWith(
        color: color,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// Text block with a 2 px left rule and 12 px inset; no background.
class _RuledBlock extends StatelessWidget {
  const _RuledBlock({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: color, width: 2)),
      ),
      child: child,
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
