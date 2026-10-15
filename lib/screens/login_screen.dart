import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/responsive_layout.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../ui/ui.dart';
import '../widgets/app_logo.dart';
import 'home_screen.dart';

/// Sign in / sign up. Calm and editorial: wordmark, one headline, a
/// segmented control, labelled fields and a single primary action.
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
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width > ResponsiveLayout.desktopBreakpoint;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).appBarTheme.systemOverlayStyle ??
          SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: context.colors.background,
        resizeToAvoidBottomInset: true,
        body: isDesktop ? _buildDesktop(context) : _buildPhone(context),
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

  Widget _buildPhone(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                40,
                AppSpacing.gutter,
                AppSpacing.xxl,
              ),
              child: StaggeredColumn(
                children: [
                  const _WordmarkRow(),
                  const SizedBox(height: AppSpacing.xxxl),
                  _Heading(isSignup: _isSignup),
                  const SizedBox(height: AppSpacing.xxl),
                  _SegmentedControl(
                    index: _tab,
                    labels: const ['Login', 'Sign up'],
                    enabled: !_isLoading,
                    onChanged: _switchTab,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _buildFields(),
                  const SizedBox(height: AppSpacing.xxl),
                  _buildActions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            color: c.inset,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.huge,
              vertical: AppSpacing.huge,
            ),
            child: const _BrandPanel(),
          ),
        ),
        Expanded(
          flex: 6,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                  vertical: AppSpacing.huge,
                ),
                child: StaggeredColumn(
                  children: [
                    _Heading(isSignup: _isSignup),
                    const SizedBox(height: AppSpacing.xxl),
                    _SegmentedControl(
                      index: _tab,
                      labels: const ['Login', 'Sign up'],
                      enabled: !_isLoading,
                      onChanged: _switchTab,
                    ),
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
      ],
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
                onSubmitted: (_) => _submit(),
              ),
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
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: AppButton.ghost(
                  label: 'Forgot password?',
                  size: AppButtonSize.small,
                  onPressed: enabled ? _forgotPassword : null,
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

// ── Pieces ──

class _WordmarkRow extends StatelessWidget {
  const _WordmarkRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppLogoWidget(size: 28),
        const SizedBox(width: AppSpacing.md),
        Text('ClashChat', style: context.text.titleMedium),
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

/// Two-option segmented control: raised card with a soft brass pill
/// indicator that slides under the selected label.
class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({
    required this.index,
    required this.labels,
    required this.onChanged,
    this.enabled = true,
  });

  final int index;
  final List<String> labels;
  final ValueChanged<int> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final count = labels.length;

    return AppCard(
      level: AppCardLevel.raised,
      padding: const EdgeInsets.all(AppSpacing.xs),
      radius: AppRadius.mdAll,
      child: SizedBox(
        height: 40,
        child: Stack(
          children: [
            AnimatedAlign(
              duration: AppDurations.fast,
              curve: Curves.easeOutCubic,
              alignment: Alignment(
                count == 1 ? 0 : -1 + (2 * index / (count - 1)),
                0,
              ),
              child: FractionallySizedBox(
                widthFactor: 1 / count,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.accentSoft,
                    borderRadius: AppRadius.smAll,
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < count; i++)
                  Expanded(
                    child: Pressable(
                      onTap: enabled ? () => onChanged(i) : null,
                      enabled: enabled,
                      pressedScale: 0.97,
                      semanticLabel: labels[i],
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: AppDurations.fast,
                          style: context.text.labelLarge!.copyWith(
                            color: i == index ? c.textPrimary : c.textSecondary,
                          ),
                          child: Text(labels[i]),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
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
/// 52 px, radius 14, 0.98 press scale).
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
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: Curves.easeOutCubic,
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        decoration: BoxDecoration(
          color: enabled ? c.surface : c.surfaceRaised,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: c.borderStrong),
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
    );
  }
}

/// Desktop-only left column: wordmark, statement and the three modes.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final display = context.text.displayMedium;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AppLogoWidget(size: 40),
            const SizedBox(width: AppSpacing.lg),
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
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(
            'Debate an opponent that pushes back, get scored on every '
            'argument, and watch your record climb.',
            style: context.text.bodyLarge?.copyWith(color: c.textSecondary),
          ),
        ),
        const SizedBox(height: AppSpacing.huge),
        StaggeredColumn(
          startIndex: 2,
          children: [
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
      ],
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
        AppIconTile(icon: icon, color: color, background: background),
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
