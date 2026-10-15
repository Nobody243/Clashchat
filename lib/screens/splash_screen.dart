import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../ui/ui.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Splash: the two bubbles of the mark fly in from either side and clash; a
/// shockwave ring and a few sparks mark the impact; the wordmark cascades in
/// letter by letter, the brass rule draws, the tagline settles. Then the app
/// routes by auth state. ~3.4 s. Honors reduce-motion (static, routes at
/// once).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _total = Duration(milliseconds: 3400);
  static const _word = 'ClashChat';

  late final AnimationController _ctrl;

  // Timeline (fractions of _total).
  late final Animation<double> _bubbles = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.04, 0.38, curve: Curves.easeOutBack),
  );
  late final Animation<double> _impact = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.36, 0.72, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _rule = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.62, 0.78, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _tagline = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.74, 0.90, curve: Curves.easeOutCubic),
  );

  Animation<double> _letter(int i) => CurvedAnimation(
        parent: _ctrl,
        curve: Interval(
          0.42 + i * 0.03,
          (0.60 + i * 0.03).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      );

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _total);
    _ctrl.addStatusListener(_onStatus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.reduceMotion) {
        _ctrl.value = 1;
      } else {
        _ctrl.forward();
      }
    });
  }

  Future<void> _onStatus(AnimationStatus status) async {
    if (status != AnimationStatus.completed || !mounted) return;

    final isLoggedIn = AuthService.isLoggedIn;
    final currentUser = AuthService.currentUser;
    bool shouldNavigateToHome = false;

    if (isLoggedIn && currentUser != null) {
      final isSessionValid = await SessionService.isSessionValid();
      if (!isSessionValid) {
        await AuthService.logout();
        await SessionService.clearSession();
      } else {
        final accountExists =
            await AuthService.userAccountExists(currentUser.uid);
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
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, _, _) =>
            shouldNavigateToHome ? const HomeScreen() : const LoginScreen(),
        transitionsBuilder: (_, anim, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final wordStyle = context.text.displaySmall;
    final markSize = context.isCompact ? 128.0 : 160.0;

    return Scaffold(
      backgroundColor: c.background,
      body: AppBackdrop(
        intensity: 1.2,
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: markSize * 2.2,
                    height: markSize * 1.3,
                    child: CustomPaint(
                      painter: _ClashMarkPainter(
                        approach: _bubbles.value,
                        impact: _impact.value,
                        ink: c.textPrimary,
                        accent: c.accent,
                        background: c.background,
                        markSize: markSize,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Wordmark, one letter at a time.
                  Semantics(
                    label: _word,
                    excludeSemantics: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < _word.length; i++)
                          _Letter(
                            _word[i],
                            progress: _letter(i).value,
                            style: wordStyle?.copyWith(
                              color: i < 5 ? c.textPrimary : c.accent,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: 64,
                    height: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 64 * _rule.value,
                        height: 2,
                        color: c.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Opacity(
                    opacity: _tagline.value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - _tagline.value) * 6),
                      child: Text(
                        'Argue better.',
                        style: context.text.bodyMedium?.copyWith(
                          color: c.textSecondary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
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

class _Letter extends StatelessWidget {
  const _Letter(this.char, {required this.progress, required this.style});
  final String char;
  final double progress;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset(0, (1 - progress) * 14),
        child: Text(char, style: style),
      ),
    );
  }
}

/// Draws the mark's two bubbles converging from off-centre, then the impact:
/// a brief scale pulse, an expanding ring and a handful of sparks.
class _ClashMarkPainter extends CustomPainter {
  _ClashMarkPainter({
    required this.approach,
    required this.impact,
    required this.ink,
    required this.accent,
    required this.background,
    required this.markSize,
  });

  final double approach; // 0..1 (easeOutBack, may overshoot slightly)
  final double impact; // 0..1
  final Color ink;
  final Color accent;
  final Color background;
  final double markSize;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final s = markSize / 160.0;

    // Impact pulse: 1.0 -> 1.08 -> 1.0 over the first third of `impact`.
    final pulse = impact < 0.33
        ? 1 + 0.08 * math.sin(impact / 0.33 * math.pi)
        : 1.0;

    // Shockwave ring.
    if (impact > 0 && impact < 1) {
      final r = markSize * (0.35 + impact * 0.9);
      final a = (1 - impact) * 0.55;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = accent.withValues(alpha: a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * (1 - impact) + 0.5,
      );
      // Sparks.
      final rnd = math.Random(3);
      for (var i = 0; i < 10; i++) {
        final ang = rnd.nextDouble() * math.pi * 2;
        final dist = markSize * (0.3 + impact * (0.6 + rnd.nextDouble() * 0.5));
        final p = center + Offset(math.cos(ang), math.sin(ang)) * dist;
        canvas.drawCircle(
          p,
          (2.5 - impact * 2).clamp(0.4, 2.5),
          Paint()..color = (i.isEven ? accent : ink).withValues(alpha: (1 - impact) * 0.9),
        );
      }
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(pulse * s, pulse * s);
    canvas.translate(-80, -80); // 160-space origin

    // Bubble resting positions (160-space) and their fly-in offsets.
    final slide = (1 - approach) * 140;
    final back = RRect.fromRectAndRadius(
      Rect.fromLTWH(28 - slide, 36, 80, 60),
      const Radius.circular(18),
    );
    final front = RRect.fromRectAndRadius(
      Rect.fromLTWH(56 + slide, 68, 76, 56),
      const Radius.circular(18),
    );

    canvas.saveLayer(const Rect.fromLTWH(-200, -200, 560, 560), Paint());
    canvas.drawRRect(
      back,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeJoin = StrokeJoin.round,
    );
    // Clear a gap so the brass bubble reads in front once they overlap.
    canvas.drawRRect(front.inflate(8), Paint()..blendMode = BlendMode.clear);
    canvas.drawRRect(front, Paint()..color = accent);
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ClashMarkPainter old) =>
      old.approach != approach ||
      old.impact != impact ||
      old.ink != ink ||
      old.accent != accent ||
      old.markSize != markSize;
}
