import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/responsive_layout.dart';
import '../models/avatar_option.dart';
import '../ui/ui.dart';
import '../widgets/avatar_card.dart';

class AvatarPickerScreen extends StatefulWidget {
  final String? initialSeed;

  const AvatarPickerScreen({super.key, this.initialSeed});

  @override
  State<AvatarPickerScreen> createState() => _AvatarPickerScreenState();
}

class _AvatarPickerScreenState extends State<AvatarPickerScreen> {
  String? _selected;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSeed;
  }

  void _shuffle() {
    final candidates =
        kAvatars.where((a) => a.seed != _selected).toList(growable: false);
    if (candidates.isEmpty) return;
    setState(
      () => _selected = candidates[_random.nextInt(candidates.length)].seed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 600
        ? 2
        : (screenWidth > ResponsiveLayout.desktopBreakpoint ? 4 : 3);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose your avatar'),
        leading: AppIconButton(
          icon: AppIcons.back,
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.lg,
                      AppSpacing.gutter,
                      AppSpacing.xxl,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: kAvatars.length,
                    itemBuilder: (_, i) {
                      final avatar = kAvatars[i];
                      return AppReveal(
                        index: i,
                        child: AvatarCard(
                          avatar: avatar,
                          isSelected: _selected == avatar.seed,
                          onTap: () => setState(() => _selected = avatar.seed),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.md,
                    AppSpacing.gutter,
                    AppSpacing.xl,
                  ),
                  child: Row(
                    children: [
                      AppButton.secondary(
                        label: 'Shuffle',
                        icon: AppIcons.shuffle,
                        expand: false,
                        onPressed: _shuffle,
                      ),
                      AppSpacing.hMd,
                      Expanded(
                        child: AppButton.primary(
                          label: 'Use this avatar',
                          onPressed: _selected == null
                              ? null
                              : () => Navigator.pop(context, _selected),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
