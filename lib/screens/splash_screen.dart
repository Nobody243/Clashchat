import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../ui/ui.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Splash: wordmark, a brass rule that draws itself, one line of tagline.
/// Stays on screen for the same 4 s as before, then routes by auth state.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _total = Duration(milliseconds: 4000);
  static const _ruleWidth = 56.0;

  late final AnimationController _mainCtrl;

  // Timeline fractions of the 4000 ms controller.
  // Wordmark fades up over the first 600 ms; the rule draws over the next
  // 500 ms (0.15 -> 0.275); the tagline follows.
  late final Animation<double> _wordmark = CurvedAnimation(
    parent: _mainCtrl,
    curve: const Interval(0.0, 0.15, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _rule = CurvedAnimation(
    parent: _mainCtrl,
    curve: const Interval(0.15, 0.275, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _tagline = CurvedAnimation(
    parent: _mainCtrl,
    curve: const Interval(0.275, 0.40, curve: Curves.easeOutCubic),
  );

  @override
  void initState() {
    super.initState();
    _mainCtrl = AnimationController(vsync: this, duration: _total)..forward();

    _mainCtrl.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        if (!mounted) return;

        final isLoggedIn = AuthService.isLoggedIn;
        final currentUser = AuthService.currentUser;
        bool shouldNavigateToHome = false;

        if (isLoggedIn && currentUser != null) {
          final isSessionValid = await SessionService.isSessionValid();
          if (!isSessionValid) {
            await AuthService.logout();
            await SessionService.clearSession();
          } else {
            final accountExists = await AuthService.userAccountExists(
              currentUser.uid,
            );
            if (!accountExists) {
              await AuthService.logout();
              await SessionService.clearSession();
            } else {
              shouldNavigateToHome = true;
            }
          }
        }

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                shouldNavigateToHome ? const HomeScreen() : const LoginScreen(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduce = context.reduceMotion;
    final wordmarkStyle = context.text.displaySmall;

    return Scaffold(
      backgroundColor: c.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _mainCtrl,
          builder: (context, _) {
            final w = reduce ? 1.0 : _wordmark.value;
            final r = reduce ? 1.0 : _rule.value;
            final t = reduce ? 1.0 : _tagline.value;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: w,
                  child: Transform.translate(
                    offset: Offset(0, (1 - w) * 8),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Clash',
                            style: wordmarkStyle?.copyWith(color: c.textPrimary),
                          ),
                          TextSpan(
                            text: 'Chat',
                            style: wordmarkStyle?.copyWith(color: c.accent),
                          ),
                        ],
                      ),
                      semanticsLabel: 'ClashChat',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: _ruleWidth,
                  height: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: _ruleWidth * r,
                      height: 2,
                      color: c.accent,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * 8),
                    child: Text(
                      'Argue better.',
                      style: context.text.bodySmall?.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
