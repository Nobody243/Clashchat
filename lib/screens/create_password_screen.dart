import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../ui/ui.dart';

/// Google users add a password so they can also sign in with email.
///
/// Form column on the atmospheric backdrop; the CTA is pinned to the bottom
/// and rides above the keyboard.
class CreatePasswordScreen extends StatefulWidget {
  const CreatePasswordScreen({super.key});

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _isLoading = false;
  bool _showErrors = false;

  @override
  void dispose() {
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  String? _validateNewPassword(String? value) {
    if (!_showErrors) return null;
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (!_showErrors) return null;
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _newPassCtrl.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    setState(() => _showErrors = true);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not found');

      // Update password for Google sign-in users
      await user.updatePassword(_newPassCtrl.text);
      await user.reload();

      // Update Firestore to mark that user now has a password
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'isGoogleSignIn': false},
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        _successSnackBar(context, 'Password created successfully'),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final password = _newPassCtrl.text;
    final gutter = context.pageGutter;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: c.background,
      // The body keeps its size; the CTA lifts by the keyboard inset below,
      // so the backdrop never re-lays out while typing.
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: c.background.withValues(alpha: 0),
        leading: Center(
          child: AppIconButton(
            icon: AppIcons.back,
            tooltip: 'Back',
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
      ),
      body: AppPage(
        width: AppPageWidth.form,
        scroll: false,
        padding: EdgeInsets.zero,
        bottomSafe: false,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    gutter,
                    AppSpacing.sm,
                    gutter,
                    AppSpacing.xxl,
                  ),
                  child: StaggeredColumn(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: AppIconTile(
                          icon: AppIcons.key,
                          size: 56,
                          iconSize: 26,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Create a password',
                        style: context.text.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'You signed in with Google. Add a password so you '
                        'can also sign in with your email.',
                        style: context.text.bodyMedium?.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      AppTextField(
                        label: 'Password',
                        hint: 'Enter password',
                        controller: _newPassCtrl,
                        obscure: true,
                        enabled: !_isLoading,
                        validator: _validateNewPassword,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _StrengthMeter(password: password),
                      const SizedBox(height: AppSpacing.lg),
                      _PasswordChecklist(password: password),
                      const SizedBox(height: AppSpacing.xxl),
                      AppTextField(
                        label: 'Confirm password',
                        hint: 'Confirm password',
                        controller: _confirmPassCtrl,
                        obscure: true,
                        enabled: !_isLoading,
                        validator: _validateConfirmPassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        onSubmitted: (_) =>
                            _isLoading ? null : _handleSubmit(),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom CTA: rides above the keyboard and the home indicator.
              Padding(
                padding: EdgeInsets.only(bottom: keyboard),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      gutter,
                      AppSpacing.md,
                      gutter,
                      AppSpacing.xl,
                    ),
                    child: AppReveal(
                      index: 7,
                      child: AppButton.primary(
                        label: 'Create password',
                        loading: _isLoading,
                        onPressed: _handleSubmit,
                      ),
                    ),
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

/// Themed success toast: check-circle in sage beside the message. Shown just
/// before the screen pops, so it reads on the screen underneath.
SnackBar _successSnackBar(BuildContext context, String message) {
  final c = context.colors;
  return SnackBar(
    content: Row(
      children: [
        Icon(AppIcons.checkCircle, size: 20, color: c.positiveText),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(message)),
      ],
    ),
  );
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
    const hint = 'Add a symbol for a strong password';

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

/// Live checklist mirroring the password validator's rules.
class _PasswordChecklist extends StatelessWidget {
  const _PasswordChecklist({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final rules = <(String, bool)>[
      ('At least 8 characters', password.length >= 8),
      ('One uppercase letter', RegExp(r'[A-Z]').hasMatch(password)),
      ('One number', RegExp(r'[0-9]').hasMatch(password)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < rules.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _RequirementRow(label: rules[i].$1, satisfied: rules[i].$2),
        ],
      ],
    );
  }
}

/// One rule: the icon crossfades (150 ms) from a hint-coloured check to a
/// sage check-circle when the rule is met; the label brightens with it.
class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.label, required this.satisfied});

  final String label;
  final bool satisfied;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        AnimatedSwitcher(
          duration: AppDurations.fast,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: anim.drive(Tween<double>(begin: 0.7, end: 1)),
              child: child,
            ),
          ),
          child: Icon(
            satisfied ? AppIcons.checkCircle : AppIcons.check,
            key: ValueKey(satisfied),
            size: 18,
            color: satisfied ? c.positiveText : c.textHint,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: AnimatedDefaultTextStyle(
            duration: AppDurations.fast,
            style: context.text.bodySmall!.copyWith(
              color: satisfied ? c.textPrimary : c.textSecondary,
            ),
            child: Text(label),
          ),
        ),
      ],
    );
  }
}
