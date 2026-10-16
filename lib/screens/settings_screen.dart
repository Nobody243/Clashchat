import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme_provider.dart';
import '../ui/ui.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String _version = '1.1.1';

  static const List<ThemeMode> _modes = [
    ThemeMode.system,
    ThemeMode.light,
    ThemeMode.dark,
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final compact = context.isCompact;
    final gutter = context.pageGutter;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    // The appearance control is the one place that reads the theme choice.
    final themeMode = context.watch<ThemeProvider>().themeMode;

    final segmented = AppSegmented(
      labels: const ['System', 'Light', 'Dark'],
      icons: const [AppIcons.sparkle, AppIcons.sun, AppIcons.moon],
      index: _modes.indexOf(themeMode),
      onChanged: (i) => context.read<ThemeProvider>().setMode(_modes[i]),
    );

    if (compact) {
      // Phone composition (DESIGN.md §10): type and hairlines, no cards.
      final soon = Text(
        'Coming soon',
        style: context.text.labelSmall?.copyWith(color: c.textHint),
      );
      return AppPage(
        width: AppPageWidth.form,
        bottomSafe: false,
        padding: EdgeInsets.fromLTRB(
          gutter,
          AppSpacing.xl,
          gutter,
          AppSpacing.xxxl + bottomInset,
        ),
        child: StaggeredColumn(
          children: [
            Text('Settings', style: context.text.headlineMedium),
            const AppSectionLabel('Appearance'),
            segmented,
            const AppSectionLabel('Preferences'),
            AppRows(
              children: [
                AppPlainRow(
                  title: 'Notifications',
                  subtitle: 'Reminders when your daily quota resets',
                  trailing: soon,
                ),
                AppPlainRow(
                  title: 'Sound effects',
                  subtitle: 'Timer and result cues',
                  trailing: soon,
                ),
              ],
            ),
            const AppSectionLabel('About'),
            AppRows(
              children: [
                AppPlainRow(
                  title: 'Version',
                  trailing: Text(
                    _version,
                    style: context.mono(size: 12, color: c.textSecondary),
                  ),
                ),
                AppPlainRow(
                  title: 'Privacy policy',
                  chevron: true,
                  onTap: () {},
                ),
                AppPlainRow(
                  title: 'Terms of service',
                  chevron: true,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      );
    }

    return AppPage(
      width: AppPageWidth.content,
      bottomSafe: false,
      padding: EdgeInsets.fromLTRB(
        gutter,
        AppSpacing.xxl,
        gutter,
        AppSpacing.xxxl + bottomInset,
      ),
      child: StaggeredColumn(
        children: [
          Text('Settings', style: context.text.headlineMedium),
          AppSpacing.vXxl,
          const AppSectionHeader(title: 'Appearance'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme', style: context.text.titleSmall),
                AppSpacing.vXs,
                Text(
                  'System follows your device. Ink is the default.',
                  style: context.text.bodySmall,
                ),
                AppSpacing.vLg,
                segmented,
              ],
            ),
          ),
          AppSpacing.vXxl,
          const AppSectionHeader(title: 'Preferences'),
          AppListGroup(
            children: [
              AppListRow(
                title: 'Notifications',
                subtitle: 'Reminders when your daily quota resets',
                leading: _SettingsIcon(AppIcons.bell),
                trailing: const AppPill(label: 'Coming soon'),
              ),
              AppListRow(
                title: 'Sound effects',
                subtitle: 'Timer and result cues',
                leading: _SettingsIcon(AppIcons.speaker),
                trailing: const AppPill(label: 'Coming soon'),
              ),
            ],
          ),
          AppSpacing.vXxl,
          const AppSectionHeader(title: 'About'),
          AppListGroup(
            children: [
              AppListRow(
                title: 'Version',
                leading: _SettingsIcon(AppIcons.info),
                trailing: Text(
                  _version,
                  style: context.mono(size: 12, color: c.textSecondary),
                ),
              ),
              AppListRow(
                title: 'Privacy policy',
                leading: _SettingsIcon(AppIcons.shield),
                onTap: () {},
              ),
              AppListRow(
                title: 'Terms of service',
                leading: _SettingsIcon(AppIcons.document),
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppIconTile(
      icon: icon,
      color: c.textSecondary,
      background: c.surfaceRaised,
      size: 36,
      iconSize: 18,
      radius: AppRadius.smAll,
    );
  }
}
