import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors_ext.dart';
import '../core/app_spacing.dart';
import 'app_icons.dart';

/// Labelled text field: label above, helper/error below. See DESIGN.md §4.
/// Password fields get a built-in visibility toggle.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.focusNode,
    this.prefixIcon,
    this.suffix,
    this.helper,
    this.errorText,
    this.obscure = false,
    this.enabled = true,
    this.autofocus = false,
    this.readOnly = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final IconData? prefixIcon;
  final Widget? suffix;
  final String? helper;
  final String? errorText;
  final bool obscure;
  final bool enabled;
  final bool autofocus;
  final bool readOnly;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    Widget? suffix = widget.suffix;
    if (widget.obscure) {
      suffix = IconButton(
        onPressed: () => setState(() => _hidden = !_hidden),
        icon: Icon(_hidden ? AppIcons.eye : AppIcons.eyeSlash, size: 20),
        tooltip: _hidden ? 'Show password' : 'Hide password',
        color: c.textHint,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: context.text.labelMedium?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          readOnly: widget.readOnly,
          obscureText: _hidden,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          autofillHints: widget.autofillHints,
          inputFormatters: widget.inputFormatters,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          onTap: widget.onTap,
          style: context.text.bodyLarge,
          cursorColor: c.accent,
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helper,
            errorText: widget.errorText,
            counterText: '',
            prefixIcon: widget.prefixIcon == null
                ? null
                : Icon(widget.prefixIcon, size: 20),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}
