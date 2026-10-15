import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/responsive_layout.dart';
import '../core/theme_provider.dart';
import '../ui/ui.dart';
import '../widgets/desktop_page_shell.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const double _maxWidth = 640;
  static const String _version = '1.0.2';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > ResponsiveLayout.desktopBreakpoint;
    final isWideDesktop =
        screenWidth >= ResponsiveLayout.wideDesktopBreakpoint;

    final content = StaggeredColumn(
      children: [
        Text('Settings', style: context.text.headlineMedium),
        AppSpacing.vXxl,
        const AppSectionHeader(title: 'Appearance'),
        AppListGroup(
          children: [
            _SettingsRow(
              icon: AppIcons.moon,
              title: 'Dark mode',
              subtitle: 'Arena Night is the default',
              onTap: () => context.read<ThemeProvider>().toggle(),
              trailing: Switch(
                value: context.watch<ThemeProvider>().isDark,
                onChanged: (_) => context.read<ThemeProvider>().toggle(),
              ),
            ),
          ],
        ),
        AppSpacing.vXxl,
        const AppSectionHeader(title: 'Preferences'),
        const AppListGroup(
          children: [
            _SettingsRow(
              icon: AppIcons.bell,
              title: 'Notifications',
              subtitle: 'Reminders when your daily quota resets',
              trailing: AppPill(label: 'Coming soon'),
            ),
            _SettingsRow(
              icon: AppIcons.speaker,
              title: 'Sound effects',
              subtitle: 'Timer and result cues',
              trailing: AppPill(label: 'Coming soon'),
            ),
          ],
        ),
        AppSpacing.vXxl,
        const AppSectionHeader(title: 'About'),
        AppListGroup(
          children: [
            _SettingsRow(
              icon: AppIcons.info,
              title: 'Version',
              trailing: Text(
                _version,
                style: context.mono(size: 12, color: c.textSecondary),
              ),
            ),
            _SettingsRow(
              icon: AppIcons.shield,
              title: 'Privacy policy',
              onTap: () {},
            ),
            _SettingsRow(
              icon: AppIcons.document,
              title: 'Terms of service',
              onTap: () {},
            ),
          ],
        ),
      ],
    );

    return ColoredBox(
      color: c.background,
      child: SafeArea(
        top: !isDesktop,
        child: isWideDesktop
            ? DesktopPageShell(
                maxWidth: _maxWidth,
                child: SingleChildScrollView(child: content),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxWidth),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      isDesktop ? AppSpacing.xxxl : AppSpacing.xl,
                      AppSpacing.gutter,
                      AppSpacing.xxxl,
                    ),
                    child: content,
                  ),
                ),
              ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      semanticLabel: title,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            AppIconTile(
              icon: icon,
              color: c.textSecondary,
              background: c.surfaceRaised,
              size: 36,
              iconSize: 18,
              radius: AppRadius.smAll,
            ),
            AppSpacing.hMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.titleSmall),
                  if (subtitle != null) ...[
                    AppSpacing.vXs,
                    Text(subtitle!, style: context.text.bodySmall),
                  ],
                ],
              ),
            ),
            AppSpacing.hMd,
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(AppIcons.forward, size: 18, color: c.textHint),
          ],
        ),
      ),
    );
  }
}
