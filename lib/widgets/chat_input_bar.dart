import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ui/ui.dart';

/// Bottom composer: a raised pill holding a borderless multiline field and a
/// 40 px circular send button.
class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;
  final bool isSending;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.enabled = true,
    this.isSending = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final canInput = enabled && !isSending;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.xs,
            AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            borderRadius: AppRadius.xlAll,
            border: Border.all(color: c.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: canInput,
                  minLines: 1,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.send,
                  textCapitalization: TextCapitalization.sentences,
                  cursorColor: c.accent,
                  style: text.bodyMedium?.copyWith(
                    color: canInput ? c.textPrimary : c.textHint,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Make your point…',
                    hintStyle: text.bodyMedium?.copyWith(color: c.textHint),
                    filled: false,
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                  onSubmitted: canInput ? (_) => onSend() : null,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _SendButton(
                controller: controller,
                enabled: canInput,
                onSend: onSend,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;

  const _SendButton({
    required this.controller,
    required this.onSend,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final active = enabled && value.text.trim().isNotEmpty;
        return Pressable(
          enabled: active,
          pressedScale: 0.92,
          semanticLabel: 'Send',
          onTap: active
              ? () {
                  HapticFeedback.lightImpact();
                  onSend();
                }
              : null,
          child: AnimatedContainer(
            duration: AppDurations.fast,
            curve: Curves.easeOutCubic,
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: active ? c.ctaBg : c.surfaceRaised,
              shape: BoxShape.circle,
              border: active ? null : Border.all(color: c.border),
            ),
            alignment: Alignment.center,
            child: Icon(
              AppIcons.sendFilled,
              size: 18,
              color: active ? c.ctaFg : c.textHint,
            ),
          ),
        );
      },
    );
  }
}
