import 'dart:math' as math;

import 'package:flutter/material.dart';

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
    final c = context.colors;
    final columns = context.isCompact
        ? 2
        : context.isMedium
            ? 3
            : 4;
    final gutter = context.pageGutter;

    return Scaffold(
      backgroundColor: c.background,
      extendBody: true,
      appBar: AppBar(
        title: const Text('Choose your avatar'),
        leading: AppIconButton(
          icon: AppIcons.back,
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Builder(
        builder: (context) {
          // With `extendBody` the bar height arrives as bottom padding; keep
          // it inside the scroll content so the grid slides under the glass.
          final bottomInset = MediaQuery.paddingOf(context).bottom;
          return AppPage(
            width: AppPageWidth.content,
            topSafe: false,
            bottomSafe: false,
            padding: EdgeInsets.fromLTRB(
              gutter,
              AppSpacing.lg,
              gutter,
              AppSpacing.xxl + bottomInset,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pick a face for the arena. You can change it any time.',
                  style: context.text.bodySmall,
                ),
                AppSpacing.vLg,
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
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
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _PickerBar(
        onShuffle: _shuffle,
        onConfirm:
            _selected == null ? null : () => Navigator.pop(context, _selected),
      ),
    );
  }
}

/// Frosted action bar pinned to the bottom; the grid scrolls under it.
class _PickerBar extends StatelessWidget {
  const _PickerBar({required this.onShuffle, required this.onConfirm});

  final VoidCallback onShuffle;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final gutter = context.pageGutter;
    return DecoratedBox(
      position: DecorationPosition.foreground,
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
              constraints:
                  BoxConstraints(maxWidth: AppPageWidth.content.maxWidth),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  AppSpacing.md,
                  gutter,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton.secondary(
                        label: 'Shuffle',
                        icon: AppIcons.shuffle,
                        onPressed: onShuffle,
                      ),
                    ),
                    AppSpacing.hMd,
                    Expanded(
                      flex: 2,
                      child: AppButton.primary(
                        label: 'Use this avatar',
                        icon: AppIcons.check,
                        onPressed: onConfirm,
                      ),
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
