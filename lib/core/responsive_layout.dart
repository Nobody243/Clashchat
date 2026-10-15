import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ui/ui.dart';
import 'theme_provider.dart';

/// Switches between the phone shell (bottom navigation bar) and the desktop
/// shell (fixed left sidebar) based on screen width.
class ResponsiveLayout extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigationChanged;
  final List<Widget> screens;

  const ResponsiveLayout({
    super.key,
    required this.currentIndex,
    required this.onNavigationChanged,
    required this.screens,
  });

  static const double desktopBreakpoint = 850.0;
  static const double wideDesktopBreakpoint = 1024.0;

  /// The four top-level destinations, shared by both shells.
  static const List<AppNavDestination> destinations = [
    AppNavDestination(
      label: 'Home',
      icon: AppIcons.home,
      selectedIcon: AppIcons.homeFilled,
    ),
    AppNavDestination(
      label: 'History',
      icon: AppIcons.history,
      selectedIcon: AppIcons.historyFilled,
    ),
    AppNavDestination(
      label: 'Profile',
      icon: AppIcons.profile,
      selectedIcon: AppIcons.profileFilled,
    ),
    AppNavDestination(
      label: 'Settings',
      icon: AppIcons.settings,
      selectedIcon: AppIcons.settingsFilled,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > desktopBreakpoint;

    if (isDesktop) {
      return _DesktopScaffold(
        currentIndex: currentIndex,
        onNavigationChanged: onNavigationChanged,
        screens: screens,
      );
    }

    return _MobileScaffold(
      currentIndex: currentIndex,
      onNavigationChanged: onNavigationChanged,
      screens: screens,
    );
  }
}

/// A top-level navigation destination (label + regular/filled icon pair).
class AppNavDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const AppNavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

/// Bottom navigation bar for the phone shell. Styled by the theme
/// (surface fill, hairline top, accent-soft indicator).
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onChanged,
        destinations: [
          for (final d in ResponsiveLayout.destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
              tooltip: '',
            ),
        ],
      ),
    );
  }
}

class _DesktopScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigationChanged;
  final List<Widget> screens;

  const _DesktopScaffold({
    required this.currentIndex,
    required this.onNavigationChanged,
    required this.screens,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _SidebarNavigation(
            currentIndex: currentIndex,
            onNavigationChanged: onNavigationChanged,
          ),
          Expanded(child: screens[currentIndex]),
        ],
      ),
    );
  }
}

class _MobileScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigationChanged;
  final List<Widget> screens;

  const _MobileScaffold({
    required this.currentIndex,
    required this.onNavigationChanged,
    required this.screens,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: AppBottomNav(
        currentIndex: currentIndex,
        onChanged: onNavigationChanged,
      ),
    );
  }
}

class _SidebarNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigationChanged;

  const _SidebarNavigation({
    required this.currentIndex,
    required this.onNavigationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // The sidebar's theme row is the desktop counterpart of the Settings
    // switch, so it may read the ThemeProvider.
    final themeIsDark = context.watch<ThemeProvider>().isDark;

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(right: BorderSide(color: c.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Wordmark
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xxl,
              AppSpacing.xl,
              AppSpacing.xxl,
            ),
            child: Row(
              children: [
                const AppIconTile(icon: AppIcons.casual, size: 36, iconSize: 20),
                AppSpacing.hMd,
                Text('ClashChat', style: context.text.titleMedium),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: c.border),
          AppSpacing.vLg,
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                for (var i = 0; i < ResponsiveLayout.destinations.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: _SidebarNavItem(
                      icon: currentIndex == i
                          ? ResponsiveLayout.destinations[i].selectedIcon
                          : ResponsiveLayout.destinations[i].icon,
                      label: ResponsiveLayout.destinations[i].label,
                      isSelected: currentIndex == i,
                      onTap: () => onNavigationChanged(i),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: c.border),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _SidebarNavItem(
              icon: themeIsDark ? AppIcons.sun : AppIcons.moon,
              label: themeIsDark ? 'Light mode' : 'Dark mode',
              isSelected: false,
              onTap: () => context.read<ThemeProvider>().toggle(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = isSelected ? c.accent : c.textSecondary;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected ? c.accentSoft : null,
          borderRadius: AppRadius.pillAll,
        ),
        child: Row(
          children: [
            Icon(icon, color: fg, size: 20),
            AppSpacing.hMd,
            Text(
              label,
              style: context.text.labelLarge?.copyWith(
                color: isSelected ? c.textPrimary : c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
