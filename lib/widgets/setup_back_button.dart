import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ui/ui.dart';

/// Back affordance for the setup flow. Sits in the `AppBar.leading` slot of
/// every setup screen. Pops the route unless [onPressed] is given.
class SetupBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const SetupBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: AppIcons.back,
      tooltip: 'Back',
      onPressed: () {
        HapticFeedback.lightImpact();
        if (onPressed != null) {
          onPressed!();
        } else {
          Navigator.of(context).pop();
        }
      },
    );
  }
}
