import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/responsive_layout.dart';
import '../models/rank_model.dart';
import '../services/auth_service.dart';
import '../ui/ui.dart';
import '../widgets/desktop_page_shell.dart';
import '../widgets/user_avatar.dart';
import 'avatar_picker_screen.dart';
import 'change_password_screen.dart';
import 'create_password_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const double _maxWidth = 640;

  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  bool _editMode = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final data = doc.data();
    if (data != null && mounted) {
      setState(() {
        _nameCtrl.text = data['displayName'] ?? 'Debater';
        _bioCtrl.text =
            data['bio'] ?? 'Passionate about ideas and the art of debate.';
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    final uid = AuthService.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'displayName': _nameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
      });
    }
    if (mounted) {
      setState(() {
        _saving = false;
        _editMode = false;
      });
    }
  }

  void _cancelEdit() {
    setState(() => _editMode = false);
    _loadUserData();
  }

  Future<void> _signOut() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _pickAvatar(String? currentSeed) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => AvatarPickerScreen(initialSeed: currentSeed),
      ),
    );
    if (result != null && mounted) {
      final uid = AuthService.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'avatarSeed': result,
          'photoUrl': FieldValue.delete(),
        });
      }
    }
  }

  /// Google accounts have no password yet, so they create one instead.
  Future<void> _changePassword() async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final isGoogleSignIn =
          userDoc.data()?['isGoogleSignIn'] as bool? ?? false;

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => isGoogleSignIn
              ? const CreatePasswordScreen()
              : const ChangePasswordScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final uid = AuthService.currentUser?.uid ?? '';
    final email = AuthService.currentUser?.email ?? '';

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > ResponsiveLayout.desktopBreakpoint;
    final isWideDesktop =
        screenWidth >= ResponsiveLayout.wideDesktopBreakpoint;

    return ColoredBox(
      color: c.background,
      child: SafeArea(
        top: !isDesktop,
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),
          builder: (context, userSnap) {
            final loading =
                userSnap.connectionState == ConnectionState.waiting &&
                !userSnap.hasData;
            final userData =
                userSnap.data?.data() as Map<String, dynamic>? ?? {};
            final rankPoints = (userData['rankPoints'] as num?)?.toInt() ?? 0;
            final rank = RankModel.getRankFromPoints(rankPoints);
            final rankData = RankModel.rankData[rank]!;
            final rankColor = Color(rankData['color'] as int);
            final displayName = userData['displayName'] as String? ?? 'Debater';
            final bio = userData['bio'] as String? ?? '';
            final avatarSeed = userData['avatarSeed'] as String? ??
                userData['photoUrl'] as String?;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('debates')
                  .doc(uid)
                  .collection('history')
                  .snapshots(),
              builder: (context, debatesSnap) {
                final debates = debatesSnap.data?.docs ?? [];
                final totalDebates = debates.length;
                final wins = debates.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return (data['score'] ?? 0) >= 50;
                }).length;
                final avgScore = totalDebates == 0
                    ? 0
                    : (debates.fold<int>(0, (acc, d) {
                              final data = d.data() as Map<String, dynamic>;
                              return acc + ((data['score'] ?? 0) as int);
                            }) /
                            totalDebates)
                        .round();

                final content = loading
                    ? const _ProfileSkeleton()
                    : StaggeredColumn(
                        children: [
                          _ProfileHeader(
                            displayName: displayName,
                            email: email,
                            rank: rank,
                            rankColor: rankColor,
                            avatarSeed: avatarSeed,
                            onTapAvatar: () => _pickAvatar(avatarSeed),
                          ),
                          AppSpacing.vLg,
                          _RankProgress(points: rankPoints),
                          if (!_editMode && bio.isNotEmpty) ...[
                            AppSpacing.vLg,
                            Text(bio, style: context.text.bodyMedium),
                          ],
                          AppSpacing.vXxl,
                          if (_editMode)
                            _EditForm(
                              nameCtrl: _nameCtrl,
                              bioCtrl: _bioCtrl,
                              saving: _saving,
                              onSave: _saveProfile,
                              onCancel: _cancelEdit,
                            )
                          else ...[
                            Row(
                              children: [
                                _StatTile(
                                  value: '$totalDebates',
                                  caption: 'Debates',
                                ),
                                AppSpacing.hMd,
                                _StatTile(
                                  value: '$avgScore',
                                  caption: 'Avg score',
                                ),
                                AppSpacing.hMd,
                                _StatTile(value: '$wins', caption: 'Wins'),
                              ],
                            ),
                            AppSpacing.vXxl,
                            const AppSectionHeader(title: 'Account'),
                            AppListGroup(
                              children: [
                                _ActionRow(
                                  icon: AppIcons.edit,
                                  label: 'Edit profile',
                                  onTap: () =>
                                      setState(() => _editMode = true),
                                ),
                                _ActionRow(
                                  icon: AppIcons.lock,
                                  label: 'Change password',
                                  onTap: _changePassword,
                                ),
                                _ActionRow(
                                  icon: AppIcons.signOut,
                                  label: 'Sign out',
                                  color: c.negativeText,
                                  showChevron: false,
                                  onTap: _signOut,
                                ),
                              ],
                            ),
                          ],
                        ],
                      );

                if (isWideDesktop) {
                  return DesktopPageShell(
                    maxWidth: _maxWidth,
                    child: SingleChildScrollView(child: content),
                  );
                }

                return Align(
                  alignment: Alignment.topCenter,
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
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String displayName;
  final String email;
  final DebateRank rank;
  final Color rankColor;
  final String? avatarSeed;
  final VoidCallback onTapAvatar;

  const _ProfileHeader({
    required this.displayName,
    required this.email,
    required this.rank,
    required this.rankColor,
    required this.avatarSeed,
    required this.onTapAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final rankName = RankModel.rankData[rank]!['name'] as String;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Pressable(
          onTap: onTapAvatar,
          pressedScale: 0.96,
          semanticLabel: 'Change avatar',
          child: UserAvatar(
            seed: avatarSeed ?? 'Debater',
            size: 72,
            ringColor: rankColor,
          ),
        ),
        AppSpacing.hLg,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.headlineSmall,
              ),
              if (email.isNotEmpty) ...[
                AppSpacing.vXs,
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall,
                ),
              ],
              AppSpacing.vSm,
              AppPill(
                label: rankName,
                icon: AppIcons.forRank(rank),
                tone: AppPillTone.rank,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Rank progress ────────────────────────────────────────────────────────────

class _RankProgress extends StatelessWidget {
  final int points;

  const _RankProgress({required this.points});

  String _nextRankLabel(DebateRank rank) {
    final ranks = DebateRank.values;
    final idx = ranks.indexOf(rank);
    if (idx >= ranks.length - 1) return 'Top rank';
    final next = RankModel.rankData[ranks[idx + 1]]!;
    final remaining = (next['minPoints'] as int) - points;
    return '$remaining pts to ${next['name']}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final rank = RankModel.getRankFromPoints(points);
    final rankColor = Color(RankModel.rankData[rank]!['color'] as int);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('$points pts', style: context.mono(size: 14)),
            const Spacer(),
            Text(
              _nextRankLabel(rank),
              style: context.text.labelSmall?.copyWith(color: c.textSecondary),
            ),
          ],
        ),
        AppSpacing.vSm,
        AppProgressBar(
          value: RankModel.getRankProgress(points),
          color: rankColor,
        ),
      ],
    );
  }
}

// ── Stats ────────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String value;
  final String caption;

  const _StatTile({required this.value, required this.caption});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: context.mono(size: 20)),
            AppSpacing.vXs,
            Text(
              caption,
              style: context.text.labelSmall?.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Edit form ────────────────────────────────────────────────────────────────

class _EditForm extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController bioCtrl;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _EditForm({
    required this.nameCtrl,
    required this.bioCtrl,
    required this.saving,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSectionHeader(title: 'Edit profile'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Display name',
                hint: 'Your name',
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                enabled: !saving,
              ),
              AppSpacing.vLg,
              AppTextField(
                label: 'Bio',
                hint: 'Write something about yourself',
                controller: bioCtrl,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                enabled: !saving,
              ),
              AppSpacing.vXl,
              Row(
                children: [
                  Expanded(
                    child: AppButton.primary(
                      label: 'Save',
                      icon: AppIcons.check,
                      loading: saving,
                      onPressed: onSave,
                    ),
                  ),
                  AppSpacing.hMd,
                  AppButton.ghost(
                    label: 'Cancel',
                    onPressed: saving ? null : onCancel,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Action rows ──────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final bool showChevron;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = color ?? c.textPrimary;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            AppIconTile(
              icon: icon,
              color: color ?? c.textSecondary,
              background: color == null ? c.surfaceRaised : c.negativeBg,
              size: 36,
              iconSize: 18,
              radius: AppRadius.smAll,
            ),
            AppSpacing.hMd,
            Expanded(
              child: Text(
                label,
                style: context.text.titleSmall?.copyWith(color: fg),
              ),
            ),
            if (showChevron)
              Icon(AppIcons.forward, size: 18, color: c.textHint),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton ─────────────────────────────────────────────────────────────────

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const AppSkeleton.circle(size: 72),
            AppSpacing.hLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AppSkeleton.line(width: 160, height: 24),
                  SizedBox(height: AppSpacing.sm),
                  AppSkeleton.line(width: 200, height: 13),
                  SizedBox(height: AppSpacing.sm),
                  AppSkeleton(width: 96, height: 28),
                ],
              ),
            ),
          ],
        ),
        AppSpacing.vLg,
        const AppSkeleton.line(height: 6),
        AppSpacing.vXxl,
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              Expanded(
                child: AppSkeleton.block(height: 76, radius: AppRadius.lgAll),
              ),
              if (i < 2) AppSpacing.hMd,
            ],
          ],
        ),
        AppSpacing.vXxl,
        const AppSkeleton.line(width: 96, height: 16),
        AppSpacing.vMd,
        AppSkeleton.block(height: 180, radius: AppRadius.lgAll),
      ],
    );
  }
}
