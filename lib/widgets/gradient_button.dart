import 'package:flutter/material.dart';

import '../ui/ui.dart';

/// Legacy name kept for existing call sites (results_screen).
///
/// This is now a thin wrapper around [AppButton.primary]: no gradient, no
/// shimmer, no glow. Prefer using [AppButton] directly in new code.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AppButton.primary(
      label: label,
      onPressed: onPressed,
      icon: icon,
    );
  }
}
