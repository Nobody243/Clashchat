import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ui/ui.dart';

/// Bottom composer on a glass bar: an optional row of argument prompt chips,
/// a raised pill field (multiline 1–5) and a 44 px send circle.
///
/// Sits above the keyboard: the bar respects the bottom safe area and the
/// hosting [Scaffold] shrinks the body by the keyboard inset.
///
/// Tapping a prompt chip inserts `"<prompt>: "` at the cursor and focuses
/// the field. Pass [onPromptTap] to own that behaviour instead.
class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;
  final bool isSending;

  /// Argument prompt chips shown above the field. Null or empty hides the row.
  final List<String>? prompts;

  /// Called with the prompt label when a chip is tapped. When null the bar
  /// inserts the prompt into [controller] itself.
  final ValueChanged<String>? onPromptTap;

  /// Focus node for the field; one is created when null.
  final FocusNode? focusNode;

  /// Max width of the composer content (matches the chat column).
  final double maxWidth;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.enabled = true,
    this.isSending = false,
    this.prompts,
    this.onPromptTap,
    this.focusNode,
    this.maxWidth = 880,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  FocusNode? _ownedFocus;

  FocusNode get _focus => widget.focusNode ?? (_ownedFocus ??= FocusNode());

  @override
  void dispose() {
    _ownedFocus?.dispose();
    super.dispose();
  }

  void _insertPrompt(String prompt) {
    final insert = '$prompt: ';
    final value = widget.controller.value;
    final text = value.text;
    final sel = value.selection;
    final start = sel.isValid ? sel.start.clamp(0, text.length) : text.length;
    final end = sel.isValid ? sel.end.clamp(0, text.length) : text.length;
    final next = text.replaceRange(start, end, insert);
    widget.controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + insert.length),
    );
    _focus.requestFocus();
  }

  void _onPrompt(String prompt) {
    if (widget.onPromptTap != null) {
      widget.onPromptTap!(prompt);
    } else {
      _insertPrompt(prompt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final canInput = widget.enabled && !widget.isSending;
    final prompts = widget.prompts ?? const <String>[];
    final gutter = context.isCompact ? AppSpacing.lg : AppSpacing.xxl;

    final field = Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: AppRadius.xlAll,
        border: Border.all(color: c.border),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
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
        onSubmitted: canInput ? (_) => widget.onSend() : null,
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: GlassBar(
        bottomBorder: false,
        padding: EdgeInsets.zero,
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: widget.maxWidth),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  AppSpacing.sm,
                  gutter,
                  AppSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (prompts.isNotEmpty) ...[
                      _PromptRow(
                        prompts: prompts,
                        enabled: canInput,
                        onTap: _onPrompt,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: field),
                        const SizedBox(width: AppSpacing.sm),
                        _SendButton(
                          controller: widget.controller,
                          enabled: canInput,
                          onSend: widget.onSend,
                        ),
                      ],
                    ),
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

/// Horizontally scrolling row of neutral sparkle pills.
class _PromptRow extends StatelessWidget {
  const _PromptRow({
    required this.prompts,
    required this.enabled,
    required this.onTap,
  });

  final List<String> prompts;
  final bool enabled;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          itemCount: prompts.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, i) {
            final p = prompts[i];
            return Pressable(
              enabled: enabled,
              onTap: enabled ? () => onTap(p) : null,
              pressedScale: 0.95,
              semanticLabel: p,
              child: Opacity(
                opacity: enabled ? 1 : 0.6,
                child: AppPill(
                  label: p,
                  icon: AppIcons.sparkle,
                  tone: AppPillTone.neutral,
                ),
              ),
            );
          },
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
            width: 44,
            height: 44,
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
