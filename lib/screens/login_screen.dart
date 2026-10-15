import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../ui/ui.dart';
import '../widgets/app_logo.dart';
import 'home_screen.dart';

/// Sign in / sign up.
///
/// * Phones (< 600): one scrolling column on the atmospheric backdrop: mark +
///   wordmark, headline, segmented control, fields, CTA.
/// * Medium (600–899): the same column, 560 wide, vertically centred.
/// * Expanded (≥ 900): brand panel on the left (45 %) with its own, brighter
///   backdrop and the three modes; the form in a glass card on the right.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _tab = 0;
  bool _isLoading = false;

  final _loginEmail = TextEditingController();
  final _loginPass = TextEditingController();
  final _signupName = TextEditingController();
  final _signupEmail = TextEditingController();
  final _signupPass = TextEditingController();

  bool get _isSignup => _tab == 1;

  @override
  void dispose() {
    _loginEmail.dispose();
    _loginPass.dispose();
    _signupName.dispose();
    _signupEmail.dispose();
    _signupPass.dispose();
    super.dispose();
  }

  // ── Auth handlers (unchanged behaviour) ──

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    final email = _loginEmail.text.trim();
    final pass = _loginPass.text;
    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final error = await AuthService.login(email, pass);
      if (!mounted) return;
      if (error == null) {
        // Create session on successful login
        await SessionService.createSession();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    }
  }

  Future<void> _handleSignup() async {
    if (_isLoading) return;

    // Validate inputs
    if (_signupEmail.text.trim().isEmpty ||
        _signupPass.text.trim().isEmpty ||
        _signupName.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final email = _signupEmail.text.trim();
    final password = _signupPass.text.trim();
    final name = _signupName.text.trim();

    setState(() => _isLoading = true);

    try {
      debugPrint('Starting signup for $email');
      final error = await AuthService.signUp(email, password, displayName: name);

      if (!mounted) return;

      debugPrint('Signup result: ${error ?? "Success"}');

      if (error == null) {
        debugPrint('Signup successful, navigating to HomeScreen');
        // Clear the form
        _signupEmail.clear();
        _signupPass.clear();
        _signupName.clear();

        // Create session on successful signup
        await SessionService.createSession();

        // Navigate using pushAndRemoveUntil to ensure clean navigation
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          _showErrorDialog(title: 'Signup failed', message: error);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog(title: 'Signup failed', message: e.toString());
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.signInWithGoogle();
      if (!mounted) return;

      if (result != null) {
        await SessionService.createSession();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign in failed. Try again.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign in error: $e')),
        );
      }
    }
  }

  void _showErrorDialog({required String title, required String message}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          AppButton.primary(
            label: 'OK',
            size: AppButtonSize.small,
            expand: false,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _forgotPassword() async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await AuthService.sendPasswordReset(_loginEmail.text);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error ??
              'If an account exists for that email, a reset link is on its way.',
        ),
      ),
    );
  }

  void _switchTab(int i) {
    if (i != _tab && !_isLoading) setState(() => _tab = i);
  }

  void _submit() {
    if (_isSignup) {
      _handleSignup();
    } else {
      _handleLogin();
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (context.isCompact) {
      body = _buildCompact(context);
    } else if (context.isMedium) {
      body = _buildMedium(context);
    } else {
      body = _buildExpanded(context);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).appBarTheme.systemOverlayStyle ??
          SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: context.colors.background,
        resizeToAvoidBottomInset: true,
        body: body,
      ),
    );
  }

  /// Phones: top-aligned scrolling column on the backdrop.
  Widget _buildCompact(BuildContext context) {
    return AppPage(
      width: AppPageWidth.form,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.xxxl,
        AppSpacing.gutter,
        AppSpacing.xxxl,
      ),
      child: StaggeredColumn(
        children: [
          const _WordmarkRow(markSize: 36),
          const SizedBox(height: AppSpacing.xxxl),
          _Heading(isSignup: _isSignup),
          const SizedBox(height: AppSpacing.xxl),
          _segmented(),
          const SizedBox(height: AppSpacing.xxl),
          _buildFields(),
          const SizedBox(height: AppSpacing.xxl),
          _buildActions(),
        ],
      ),
    );
  }

  /// 600–899: the same column, 560 wide and vertically centred.
  Widget _buildMedium(BuildContext context) {
    return AppPage(
      width: AppPageWidth.form,
      scroll: false,
      padding: EdgeInsets.zero,
      child: _CenteredScroll(
        padding: EdgeInsets.symmetric(
          horizontal: context.pageGutter,
          vertical: AppSpacing.huge,
        ),
        child: StaggeredColumn(
          children: [
            const _WordmarkRow(markSize: 44),
            const SizedBox(height: AppSpacing.xxxl),
            _Heading(isSignup: _isSignup),
            const SizedBox(height: AppSpacing.xxl),
            _segmented(),
            const SizedBox(height: AppSpacing.xxl),
            _buildFields(),
            const SizedBox(height: AppSpacing.xxl),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  /// ≥ 900: brand panel (45 %) beside the form in a glass card (55 %).
  Widget _buildExpanded(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 45,
          // The brand panel sits on the inset step. AppBackdrop paints the
          // theme's canvas, so the canvas token is remapped to `inset` for
          // this subtree only; every other token is untouched.
          child: Theme(
            data: theme.copyWith(
              extensions: <ThemeExtension<dynamic>>[
                c.copyWith(background: c.inset),
              ],
            ),
            child: AppBackdrop(
              intensity: 1.4,
              child: SafeArea(
                child: _CenteredScroll(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.huge,
                    vertical: AppSpacing.huge,
                  ),
                  child: const _BrandPanel(),
                ),
              ),
            ),
          ),
        ),
        Container(width: 1, color: c.border),
        Expanded(
          flex: 55,
          child: AppBackdrop(
            child: SafeArea(
              child: _CenteredScroll(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.huge,
                  vertical: AppSpacing.huge,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    // The card itself appears at once: a BackdropFilter
                    // inside a fading layer cannot sample the page behind
                    // it, so only the contents stagger in.
                    child: GlassCard(
                      padding: const EdgeInsets.all(AppSpacing.xxxl),
                      child: StaggeredColumn(
                        startIndex: 3,
                        children: [
                          _Heading(isSignup: _isSignup),
                          const SizedBox(height: AppSpacing.xxl),
                          _segmented(),
                          const SizedBox(height: AppSpacing.xxl),
                          _buildFields(),
                          const SizedBox(height: AppSpacing.xxl),
                          _buildActions(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _segmented() {
    return AppSegmented(
      labels: const ['Login', 'Sign up'],
      index: _tab,
      enabled: !_isLoading,
      onChanged: _switchTab,
    );
  }

  Widget _buildFields() {
    final enabled = !_isLoading;
    final child = _isSignup
        ? Column(
            key: const ValueKey('signup'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Display name',
                hint: 'How opponents will see you',
                controller: _signupName,
                enabled: enabled,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Email',
                hint: 'you@example.com',
                controller: _signupEmail,
                enabled: enabled,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Password',
                hint: 'At least 8 characters',
                controller: _signupPass,
                enabled: enabled,
                obscure: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.md),
              _StrengthMeter(password: _signupPass.text),
            ],
          )
        : Column(
            key: const ValueKey('login'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Email',
                hint: 'you@example.com',
                controller: _loginEmail,
                enabled: enabled,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Password',
                hint: 'Your password',
                controller: _loginPass,
                enabled: enabled,
                obscure: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                // 44 px hit target for the small text button.
                child: SizedBox(
                  height: 44,
                  child: AppButton.ghost(
                    label: 'Forgot password?',
                    size: AppButtonSize.small,
                    onPressed: enabled ? _forgotPassword : null,
                  ),
                ),
              ),
            ],
          );

    return AnimatedSize(
      duration: AppDurations.fast,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: AppDurations.fast,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, ?current],
        ),
        child: child,
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton.primary(
          label: 'Continue',
          loading: _isLoading,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.lg),
        const _OrDivider(),
        const SizedBox(height: AppSpacing.lg),
        _GoogleButton(
          label: 'Continue with Google',
          onPressed: _isLoading ? null : _handleGoogleSignIn,
        ),
      ],
    );
  }
}

// ── Layout helpers ──

/// Scroll view whose content is at least as tall as the viewport, so a
/// [Center] inside it truly centres on tall screens and scrolls on short
/// ones (and above the keyboard). Built privately: AppPage's `alignment`
/// cannot centre vertically inside its own scroll view.
class _CenteredScroll extends StatelessWidget {
  const _CenteredScroll({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (box.maxHeight - padding.vertical).clamp(0, double.infinity),
            ),
            child: Center(child: child),
          ),
        );
      },
    );
  }
}

// ── Pieces ──

class _WordmarkRow extends StatelessWidget {
  const _WordmarkRow({required this.markSize});

  final double markSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = context.text.titleLarge;
    return Row(
      children: [
        AppLogoWidget(size: markSize),
        const SizedBox(width: AppSpacing.md),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Clash', style: style?.copyWith(color: c.textPrimary)),
              TextSpan(text: 'Chat', style: style?.copyWith(color: c.accent)),
            ],
          ),
          semanticsLabel: 'ClashChat',
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.isSignup});

  final bool isSignup;

  static Widget _topLeft(Widget? current, List<Widget> previous) => Stack(
        alignment: Alignment.topLeft,
        children: [...previous, ?current],
      );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: AppDurations.fast,
          layoutBuilder: _topLeft,
          child: Text(
            isSignup ? 'Create your account' : 'Welcome back',
            key: ValueKey(isSignup),
            style: context.text.headlineLarge,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AnimatedSwitcher(
          duration: AppDurations.fast,
          layoutBuilder: _topLeft,
          child: Text(
            isSignup
                ? 'A name, an email and a password. Then pick a side.'
                : 'Sign in to pick up your record where you left it.',
            key: ValueKey(isSignup),
            style: context.text.bodyMedium?.copyWith(color: c.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// Four-segment password strength meter with a one-word caption.
///
/// Segments fill as these are met: length ≥ 8, an upper-case letter, a
/// number, a symbol. 0–1 reads terracotta "Weak", 2–3 amber "Okay", 4 sage
/// "Strong". Built privately: the kit has no segmented meter (AppProgressBar
/// is a single continuous track).
class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.password});

  final String password;

  static int scoreFor(String p) {
    var s = 0;
    if (p.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(p)) s++;
    if (RegExp(r'[0-9]').hasMatch(p)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final score = scoreFor(password);
    final empty = password.isEmpty;
    final (Color fill, String caption) = switch (score) {
      0 || 1 => (c.negativeText, 'Weak'),
      2 || 3 => (c.warningText, 'Okay'),
      _ => (c.positiveText, 'Strong'),
    };
    const hint = '8+ characters with a capital, a number and a symbol';

    return Semantics(
      label: empty ? 'Password strength' : 'Password strength: $caption',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    height: 4,
                    decoration: BoxDecoration(
                      color: i < score ? fill : c.inset,
                      borderRadius: AppRadius.pillAll,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm - 2),
          AnimatedSwitcher(
            duration: AppDurations.fast,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.centerLeft,
              children: [...previous, ?current],
            ),
            child: Text(
              empty ? hint : caption,
              key: ValueKey(empty ? hint : caption),
              style: context.text.labelSmall?.copyWith(
                color: empty ? c.textHint : fill,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(child: Divider(color: c.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'or',
            style: context.text.labelSmall?.copyWith(color: c.textHint),
          ),
        ),
        Expanded(child: Divider(color: c.border)),
      ],
    );
  }
}

/// Secondary-style button with an image as the leading element.
///
/// Built privately because [AppButton] only accepts an [IconData] leading
/// slot; this mirrors its secondary variant (surface, strong hairline,
/// 52 px, radius 14, 0.98 press scale) and adds the kit's hover lift.
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null;
    final fg = enabled ? c.textPrimary : c.textHint;

    return Pressable(
      onTap: onPressed,
      enabled: enabled,
      semanticLabel: label,
      child: HoverBuilder(
        enabled: enabled,
        builder: (context, hovered) => AnimatedContainer(
          duration: AppDurations.fast,
          curve: Curves.easeOutCubic,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          decoration: BoxDecoration(
            color: enabled
                ? (hovered ? c.surfaceRaised : c.surface)
                : c.surfaceRaised,
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: hovered ? c.textHint : c.borderStrong,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: enabled ? 1 : 0.5,
                child: Image.asset(
                  'assets/google_icon.png',
                  width: 18,
                  height: 18,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelLarge?.copyWith(color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Desktop-only left column: the mark at 96, display wordmark, one
/// statement and the three modes, revealed in sequence.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final display = context.text.displayMedium;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: StaggeredColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppLogoWidget(size: 96),
          const SizedBox(height: AppSpacing.xxl),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Clash',
                  style: display?.copyWith(color: c.textPrimary),
                ),
                TextSpan(
                  text: 'Chat',
                  style: display?.copyWith(color: c.accent),
                ),
              ],
            ),
            semanticsLabel: 'ClashChat',
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Debate an opponent that pushes back, get scored on every '
            'argument, and watch your record climb.',
            style: context.text.bodyLarge?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.huge),
          _ModeRow(
            icon: AppIcons.casualDuo,
            color: c.positiveText,
            background: c.positiveBg,
            title: 'Casual',
            body: 'Pick a topic and a side. No stakes, just practice.',
          ),
          const SizedBox(height: AppSpacing.xl),
          _ModeRow(
            icon: AppIcons.rankedDuo,
            color: c.rankText,
            background: c.rankBg,
            title: 'Ranked',
            body: 'Timed rounds that count toward your rank.',
          ),
          const SizedBox(height: AppSpacing.xl),
          _ModeRow(
            icon: AppIcons.learningDuo,
            color: c.infoText,
            background: c.infoBg,
            title: 'Learning',
            body: 'Coaching tips after every message you send.',
          ),
        ],
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  const _ModeRow({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIconTile(icon: icon, color: color, background: background, size: 44),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.text.titleSmall),
              const SizedBox(height: AppSpacing.xxs),
              Text(body, style: context.text.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
