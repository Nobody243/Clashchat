import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../ui/ui.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _isLoading = false;
  bool _showErrors = false;

  @override
  void dispose() {
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  // Validators
  String? _validateCurrentPassword(String? value) {
    if (!_showErrors) return null;
    if (value == null || value.isEmpty) {
      return 'Current password is required';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (!_showErrors) return null;
    if (value == null || value.isEmpty) {
      return 'New password is required';
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
      final success = await updatePassword(
        _currentPassCtrl.text,
        _newPassCtrl.text,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Current password is incorrect')),
        );
      }
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
                            'Change password',
                            style: context.text.headlineSmall,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Confirm your current password, then choose a '
                            'new one.',
                            style: context.text.bodyMedium?.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          AppTextField(
                            label: 'Current password',
                            hint: 'Enter current password',
                            controller: _currentPassCtrl,
                            obscure: true,
                            enabled: !_isLoading,
                            validator: _validateCurrentPassword,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.password],
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          AppTextField(
                            label: 'New password',
                            hint: 'Enter new password',
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
                            label: 'Confirm new password',
                            hint: 'Confirm new password',
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
                      index: 6,
                      child: AppButton.primary(
                        label: 'Update password',
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

/// Live checklist mirroring the new-password validator's rules.
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

// TODO: connect to your backend
Future<bool> updatePassword(String currentPassword, String newPassword) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      throw Exception('User not found');
    }

    // Reauthenticate with current password
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);

    // Update to new password
    await user.updatePassword(newPassword);

    return true;
  } on FirebaseAuthException catch (e) {
    debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
    if (e.code == 'wrong-password') {
      return false;
    }
    rethrow;
  } catch (e) {
    debugPrint('Update Password Error: $e');
    rethrow;
  }
}
