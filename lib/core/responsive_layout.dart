import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ui/ui.dart';
import '../widgets/app_logo.dart';
import 'theme_provider.dart';

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

/// The app shell: one widget that owns the top-level navigation and switches
/// chrome on viewport width (DESIGN.md §9, Layout classes).
///
/// * compact  (< 600)   body + blurred bottom bar, content scrolls under it
/// * medium   (600–899) 80 px navigation rail
/// * expanded (≥ 900)   264 px sidebar with wordmark, CTA and theme row
///
/// Pages are built lazily on first visit and kept alive in an [IndexedStack]
/// so switching tabs is instant, keeps scroll positions and never replays a
/// page's entrance stagger. Off-screen pages have their tickers paused.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.currentIndex,
    required this.onNavigationChanged,
    required this.pages,
    this.onStartDebate,
  });

  final int currentIndex;
  final ValueChanged<int> onNavigationChanged;

  /// One builder per destination, in [destinations] order.
  final List<WidgetBuilder> pages;

  /// Sidebar CTA (expanded layouts only).
  final VoidCallback? onStartDebate;

  /// The four top-level destinations, shared by every layout.
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
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final Set<int> _visited = {};

  /// Keeps page state alive when the chrome changes (e.g. a desktop window
  /// resized across a breakpoint moves the stack to a different parent).
  final GlobalKey _stackKey = GlobalKey();

  Widget _body(BuildContext context) {
    _visited.add(widget.currentIndex);
    return IndexedStack(
      key: _stackKey,
      index: widget.currentIndex,
      children: [
        for (var i = 0; i < widget.pages.length; i++)
          TickerMode(
            enabled: i == widget.currentIndex,
            child: _visited.contains(i)
                ? Builder(builder: widget.pages[i])
                : const SizedBox.shrink(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    if (context.isCompact) {
      return Scaffold(
        backgroundColor: c.background,
        extendBody: true,
        body: _body(context),
        bottomNavigationBar: AppBottomNav(
          currentIndex: widget.currentIndex,
          onChanged: widget.onNavigationChanged,
        ),
      );
    }

    final Widget nav = context.isMedium
        ? _NavRail(
            currentIndex: widget.currentIndex,
            onChanged: widget.onNavigationChanged,
          )
        : _Sidebar(
            currentIndex: widget.currentIndex,
            onChanged: widget.onNavigationChanged,
            onStartDebate: widget.onStartDebate,
          );

    return Scaffold(
      backgroundColor: c.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          nav,
          Expanded(child: _body(context)),
        ],
      ),
    );
  }
}

/// Legacy name kept for call sites; delegates to [AppShell].
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

  /// Width above which other screens use their desktop layout. Aligned with
  /// [AppBreakpoints.medium] so `width > desktopBreakpoint` matches the
  /// shell's sidebar (`width >= 900`).
  static const double desktopBreakpoint = AppBreakpoints.medium - 1;

  /// Width from which other screens use their widest layout
  /// (`width >= wideDesktopBreakpoint`).
  static const double wideDesktopBreakpoint = AppBreakpoints.expanded;

  static const List<AppNavDestination> destinations = AppShell.destinations;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: currentIndex,
      onNavigationChanged: onNavigationChanged,
      pages: [for (final s in screens) (_) => s],
    );
  }
}

// ── Compact: blurred bottom bar ──────────────────────────────────────────────

/// Frosted bottom navigation for phones. The scaffold uses `extendBody`, so
/// content scrolls underneath the blur. A pill in accent-soft slides between
/// the four items; the selected icon switches to its heavier stroke.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  static const double _height = 68;
  static const double _pillWidth = 64;
  static const double _pillHeight = 32;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final items = AppShell.destinations;
    final n = items.length;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: GlassBar(
        bottomBorder: false,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: _height,
          child: LayoutBuilder(
            builder: (context, box) {
              final slot = box.maxWidth / n;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: AppDurations.normal,
                    curve: Curves.easeOutCubic,
                    left: slot * currentIndex + (slot - _pillWidth) / 2,
                    top: AppSpacing.sm,
                    width: _pillWidth,
                    height: _pillHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.accentSoft,
                        borderRadius: AppRadius.pillAll,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < n; i++)
                        Expanded(
                          child: _BottomNavItem(
                            destination: items[i],
                            selected: i == currentIndex,
                            onTap: () => onChanged(i),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final AppNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = selected ? c.textPrimary : c.textHint;
    return Pressable(
      onTap: onTap,
      pressedScale: 0.94,
      semanticLabel: destination.label,
      child: Semantics(
        selected: selected,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: AppBottomNav._pillHeight,
              child: Center(
                child: Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  size: 22,
                  color: selected ? c.accent : fg,
                ),
              ),
            ),
            AppSpacing.vXs,
            AnimatedDefaultTextStyle(
              duration: AppDurations.fast,
              style: context.text.labelMedium!.copyWith(color: fg),
              child: Text(destination.label, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Medium: navigation rail ──────────────────────────────────────────────────

class _NavRail extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _NavRail({required this.currentIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final provider = context.watch<ThemeProvider>();
    final items = AppShell.destinations;

    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(right: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: AppLogoWidget(size: 32),
            ),
            AppSpacing.vSm,
            for (var i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _RailItem(
                  destination: items[i],
                  selected: i == currentIndex,
                  onTap: () => onChanged(i),
                ),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: AppIconButton(
                icon: provider.isDark ? AppIcons.sun : AppIcons.moon,
                tooltip: provider.isDark ? 'Light mode' : 'Dark mode',
                filled: true,
                onPressed: () => context.read<ThemeProvider>().toggle(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  final AppNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  const _RailItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      pressedScale: 0.95,
      semanticLabel: destination.label,
      child: HoverBuilder(
        builder: (context, hovered) => SizedBox(
          width: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: AppDurations.fast,
                curve: Curves.easeOutCubic,
                width: 56,
                height: 32,
                decoration: BoxDecoration(
                  color: selected
                      ? c.accentSoft
                      : hovered
                          ? c.accent.withValues(alpha: 0.06)
                          : c.accent.withValues(alpha: 0),
                  borderRadius: AppRadius.pillAll,
                ),
                alignment: Alignment.center,
                child: Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  size: 22,
                  color: selected ? c.accent : c.textHint,
                ),
              ),
              AppSpacing.vXs,
              Text(
                destination.label,
                style: context.text.labelSmall?.copyWith(
                  color: selected ? c.textPrimary : c.textHint,
                ),
              ),
              AppSpacing.vSm,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Expanded: sidebar ────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback? onStartDebate;

  const _Sidebar({
    required this.currentIndex,
    required this.onChanged,
    required this.onStartDebate,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // The sidebar's theme row is the desktop counterpart of the Settings
    // control, so it may read the ThemeProvider.
    final provider = context.watch<ThemeProvider>();
    final items = AppShell.destinations;

    return Container(
      width: 264,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(right: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xxl,
                AppSpacing.xl,
                AppSpacing.xxl,
              ),
              child: Row(
                children: [
                  const AppLogoWidget(size: 28),
                  AppSpacing.hMd,
                  Text('ClashChat', style: context.text.titleMedium),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < items.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: _SidebarRow(
                        icon: i == currentIndex
                            ? items[i].selectedIcon
                            : items[i].icon,
                        label: items[i].label,
                        selected: i == currentIndex,
                        onTap: () => onChanged(i),
                      ),
                    ),
                ],
              ),
            ),
            const Spacer(),
            if (onStartDebate != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: AppButton.primary(
                  label: 'Start a debate',
                  icon: AppIcons.casual,
                  size: AppButtonSize.small,
                  onPressed: onStartDebate,
                ),
              ),
            Divider(height: 1, thickness: 1, color: c.border),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _SidebarRow(
                icon: provider.isDark ? AppIcons.sun : AppIcons.moon,
                label: provider.isDark ? 'Light mode' : 'Dark mode',
                selected: false,
                onTap: () => context.read<ThemeProvider>().toggle(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      semanticLabel: label,
      child: HoverBuilder(
        builder: (context, hovered) => AnimatedContainer(
          duration: AppDurations.fast,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: selected
                ? c.accentSoft
                : hovered
                    ? c.accent.withValues(alpha: 0.06)
                    : c.accent.withValues(alpha: 0),
            borderRadius: AppRadius.pillAll,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: selected ? c.accent : c.textSecondary),
              AppSpacing.hMd,
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelLarge?.copyWith(
                    color: selected ? c.textPrimary : c.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
