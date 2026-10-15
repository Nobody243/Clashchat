import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../ui/ui.dart';

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
        const SnackBar(content: Text('Password created successfully')),
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

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        leading: Center(
          child: AppIconButton(
            icon: AppIcons.back,
            tooltip: 'Back',
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.gutter,
                        AppSpacing.sm,
                        AppSpacing.gutter,
                        AppSpacing.xxl,
                      ),
                      child: StaggeredColumn(
                        children: [
                          Text(
                            'Create a password',
                            style: context.text.headlineSmall,
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.md,
                      AppSpacing.gutter,
                      AppSpacing.xl,
                    ),
                    child: AppReveal(
                      index: 5,
                      child: AppButton.primary(
                        label: 'Create password',
                        loading: _isLoading,
                        onPressed: _handleSubmit,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
          child: Icon(
            satisfied ? AppIcons.checkCircle : AppIcons.check,
            key: ValueKey(satisfied),
            size: 18,
            color: satisfied ? c.positiveText : c.textHint,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: context.text.bodySmall?.copyWith(
            color: satisfied ? c.textPrimary : c.textSecondary,
          ),
        ),
      ],
    );
  }
}
