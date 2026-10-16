import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/rank_model.dart';
import '../services/auth_service.dart';
import '../services/avatar_preferences.dart';
import '../ui/ui.dart';
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
      // Keep the local copy (used by the chat screen) in step.
      await AvatarPreferences.saveAvatar(result);
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
    final uid = AuthService.currentUser?.uid ?? '';
    final email = AuthService.currentUser?.email ?? '';
    final compact = context.isCompact;
    final twoColumn = context.isExpanded || context.isLarge;
    final gutter = context.pageGutter;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AppPage(
      width: compact ? AppPageWidth.form : AppPageWidth.wide,
      bottomSafe: false,
      padding: EdgeInsets.fromLTRB(
        gutter,
        compact ? AppSpacing.xl : AppSpacing.xxl,
        gutter,
        AppSpacing.xxxl + bottomInset,
      ),
      child: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
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

              if (loading) {
                return compact
                    ? const _PhoneProfileSkeleton()
                    : _ProfileSkeleton(twoColumn: twoColumn);
              }

              if (compact) {
                return _PhoneProfile(
                  displayName: displayName,
                  email: email,
                  bio: _editMode ? '' : bio,
                  rank: rank,
                  rankColor: rankColor,
                  points: rankPoints,
                  avatarSeed: avatarSeed,
                  onTapAvatar: () => _pickAvatar(avatarSeed),
                  debates: totalDebates,
                  avgScore: avgScore,
                  wins: wins,
                  editMode: _editMode,
                  nameCtrl: _nameCtrl,
                  bioCtrl: _bioCtrl,
                  saving: _saving,
                  onSave: _saveProfile,
                  onCancel: _cancelEdit,
                  onEdit: () => setState(() => _editMode = true),
                  onChangePassword: _changePassword,
                  onSignOut: _signOut,
                );
              }

              final hero = _ProfileHero(
                displayName: displayName,
                email: email,
                bio: _editMode ? '' : bio,
                rank: rank,
                rankColor: rankColor,
                points: rankPoints,
                avatarSeed: avatarSeed,
                onTapAvatar: () => _pickAvatar(avatarSeed),
              );

              final stats = _StatsRow(
                debates: totalDebates,
                avgScore: avgScore,
                wins: wins,
              );

              final Widget actions = _editMode
                  ? _EditForm(
                      nameCtrl: _nameCtrl,
                      bioCtrl: _bioCtrl,
                      saving: _saving,
                      onSave: _saveProfile,
                      onCancel: _cancelEdit,
                    )
                  : _AccountGroup(
                      onEdit: () => setState(() => _editMode = true),
                      onChangePassword: _changePassword,
                      onSignOut: _signOut,
                    );

              if (twoColumn) {
                return StaggeredColumn(
                  children: [
                    Text('Profile', style: context.text.headlineMedium),
                    AppSpacing.vXxl,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [hero, AppSpacing.vLg, stats],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xxl),
                        Expanded(flex: 2, child: actions),
                      ],
                    ),
                  ],
                );
              }

              return StaggeredColumn(
                children: [
                  hero,
                  AppSpacing.vLg,
                  stats,
                  AppSpacing.vXxl,
                  actions,
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ── Hero ─────────────────────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  final String displayName;
  final String email;
  final String bio;
  final DebateRank rank;
  final Color rankColor;
  final int points;
  final String? avatarSeed;
  final VoidCallback onTapAvatar;

  const _ProfileHero({
    required this.displayName,
    required this.email,
    required this.bio,
    required this.rank,
    required this.rankColor,
    required this.points,
    required this.avatarSeed,
    required this.onTapAvatar,
  });

  String _nextRankLabel() {
    final ranks = DebateRank.values;
    final idx = ranks.indexOf(rank);
    if (idx >= ranks.length - 1) return 'Top rank reached';
    final next = RankModel.rankData[ranks[idx + 1]]!;
    final remaining = (next['minPoints'] as int) - points;
    return '$remaining pts to ${next['name']}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final rankName = RankModel.rankData[rank]!['name'] as String;
    final stackIdentity = context.isCompact;

    final avatar = UserAvatar(
      seed: avatarSeed ?? 'Debater',
      size: 88,
      ringColor: rankColor,
      onTap: onTapAvatar,
      semanticLabel: 'Change avatar',
    );

    final identity = Column(
      crossAxisAlignment:
          stackIdentity ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: stackIdentity ? TextAlign.center : TextAlign.start,
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
        AppSpacing.vMd,
        AppPill(
          label: rankName,
          icon: AppIcons.forRank(rank),
          tone: AppPillTone.rank,
        ),
      ],
    );

    return AppCard(
      clip: true,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Hero wash (DESIGN.md §9): the one allowed radial gradient here.
          Positioned(
            top: -100,
            right: -80,
            child: IgnorePointer(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [c.accentSoft, c.accentSoft.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (stackIdentity)
                  Column(
                    children: [avatar, AppSpacing.vLg, identity],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      avatar,
                      AppSpacing.hXl,
                      Expanded(child: identity),
                    ],
                  ),
                if (bio.isNotEmpty) ...[
                  AppSpacing.vLg,
                  Text(
                    bio,
                    textAlign:
                        stackIdentity ? TextAlign.center : TextAlign.start,
                    style: context.text.bodyMedium
                        ?.copyWith(color: c.textSecondary),
                  ),
                ],
                AppSpacing.vXl,
                Divider(height: 1, thickness: 1, color: c.border),
                AppSpacing.vLg,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    AnimatedNumber(value: points, size: 20),
                    AppSpacing.hXs,
                    Text(
                      'pts',
                      style: context.text.labelMedium
                          ?.copyWith(color: c.textSecondary),
                    ),
                    const Spacer(),
                    Text(
                      _nextRankLabel(),
                      style: context.text.labelSmall
                          ?.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
                AppSpacing.vSm,
                AppProgressBar(
                  value: RankModel.getRankProgress(points),
                  color: rankColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats ────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int debates;
  final int avgScore;
  final int wins;

  const _StatsRow({
    required this.debates,
    required this.avgScore,
    required this.wins,
  });

  @override
  Widget build(BuildContext context) {
    return Bento(
      gap: AppSpacing.md,
      // Three small numbers stay side by side even on phones.
      collapseBelow: 0,
      rows: [
        [
          BentoTile(
            child: _StatTile(
              value: debates,
              caption: 'Debates',
              icon: AppIcons.messages,
            ),
          ),
          BentoTile(
            child: _StatTile(
              value: avgScore,
              caption: 'Avg score',
              icon: AppIcons.score,
            ),
          ),
          BentoTile(
            child: _StatTile(
              value: wins,
              caption: 'Wins',
              icon: AppIcons.ranked,
            ),
          ),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final int value;
  final String caption;
  final IconData icon;

  const _StatTile({
    required this.value,
    required this.caption,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: c.textHint),
          AppSpacing.vMd,
          AnimatedNumber(value: value, size: 24),
          AppSpacing.vXs,
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelSmall?.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Account actions ──────────────────────────────────────────────────────────

class _AccountGroup extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onChangePassword;
  final VoidCallback onSignOut;

  const _AccountGroup({
    required this.onEdit,
    required this.onChangePassword,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSectionHeader(title: 'Account'),
        AppListGroup(
          children: [
            AppListRow(
              title: 'Edit profile',
              subtitle: 'Display name and bio',
              leading: AppIconTile(
                icon: AppIcons.edit,
                color: c.textSecondary,
                background: c.surfaceRaised,
                size: 36,
                iconSize: 18,
                radius: AppRadius.smAll,
              ),
              onTap: onEdit,
            ),
            AppListRow(
              title: 'Change password',
              leading: AppIconTile(
                icon: AppIcons.lock,
                color: c.textSecondary,
                background: c.surfaceRaised,
                size: 36,
                iconSize: 18,
                radius: AppRadius.smAll,
              ),
              onTap: onChangePassword,
            ),
            AppListRow(
              title: 'Sign out',
              titleColor: c.negativeText,
              leading: AppIconTile(
                icon: AppIcons.signOut,
                color: c.negativeText,
                background: c.negativeBg,
                size: 36,
                iconSize: 18,
                radius: AppRadius.smAll,
              ),
              showChevron: false,
              onTap: onSignOut,
            ),
          ],
        ),
      ],
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
                prefixIcon: AppIcons.user,
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

// ── Skeleton ─────────────────────────────────────────────────────────────────

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton({required this.twoColumn});

  final bool twoColumn;

  @override
  Widget build(BuildContext context) {
    Widget block(double h) =>
        AppSkeleton.block(height: h, radius: AppRadius.lgAll);

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        block(236),
        AppSpacing.vLg,
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              Expanded(child: block(104)),
              if (i < 2) AppSpacing.hMd,
            ],
          ],
        ),
      ],
    );

    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSkeleton.line(width: 96, height: 16),
        AppSpacing.vMd,
        block(188),
      ],
    );

    if (twoColumn) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSkeleton.line(width: 140, height: 28),
          AppSpacing.vXxl,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: left),
              const SizedBox(width: AppSpacing.xxl),
              Expanded(flex: 2, child: right),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [left, AppSpacing.vXxl, right],
    );
  }
}

// ── Phone composition (DESIGN.md §10) ────────────────────────────────────────

/// Phones: centered avatar, name, email, rank line and a thin progress bar,
/// one row of three numbers, then plain account rows. No cards, no tiles.
class _PhoneProfile extends StatelessWidget {
  final String displayName;
  final String email;
  final String bio;
  final DebateRank rank;
  final Color rankColor;
  final int points;
  final String? avatarSeed;
  final VoidCallback onTapAvatar;
  final int debates;
  final int avgScore;
  final int wins;
  final bool editMode;
  final TextEditingController nameCtrl;
  final TextEditingController bioCtrl;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final VoidCallback onEdit;
  final VoidCallback onChangePassword;
  final VoidCallback onSignOut;

  const _PhoneProfile({
    required this.displayName,
    required this.email,
    required this.bio,
    required this.rank,
    required this.rankColor,
    required this.points,
    required this.avatarSeed,
    required this.onTapAvatar,
    required this.debates,
    required this.avgScore,
    required this.wins,
    required this.editMode,
    required this.nameCtrl,
    required this.bioCtrl,
    required this.saving,
    required this.onSave,
    required this.onCancel,
    required this.onEdit,
    required this.onChangePassword,
    required this.onSignOut,
  });

  String _rankLine() {
    final name = (RankModel.rankData[rank]!['name'] as String).toUpperCase();
    final ranks = DebateRank.values;
    final idx = ranks.indexOf(rank);
    final String next;
    if (idx >= ranks.length - 1) {
      next = 'Top rank reached';
    } else {
      final data = RankModel.rankData[ranks[idx + 1]]!;
      final remaining = (data['minPoints'] as int) - points;
      next = '$remaining to ${data['name']}';
    }
    return '$name · $points pts · $next';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return StaggeredColumn(
      children: [
        Center(
          child: UserAvatar(
            seed: avatarSeed ?? 'Debater',
            size: 88,
            ringColor: rankColor,
            onTap: onTapAvatar,
            semanticLabel: 'Change avatar',
          ),
        ),
        AppSpacing.vLg,
        Text(
          displayName,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.headlineSmall,
        ),
        if (email.isNotEmpty) ...[
          AppSpacing.vXs,
          Text(
            email,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall,
          ),
        ],
        if (bio.isNotEmpty) ...[
          AppSpacing.vMd,
          Text(
            bio,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodyMedium?.copyWith(color: c.textSecondary),
          ),
        ],
        AppSpacing.vLg,
        Text(
          _rankLine(),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.labelSmall?.copyWith(
            color: c.rankText,
            fontWeight: FontWeight.w700,
          ),
        ),
        AppSpacing.vSm,
        AppProgressBar(
          value: RankModel.getRankProgress(points),
          height: 4,
          color: rankColor,
        ),
        AppSpacing.vXxl,
        Row(
          children: [
            Expanded(child: _Number(value: debates, caption: 'Debates')),
            Expanded(child: _Number(value: avgScore, caption: 'Avg score')),
            Expanded(child: _Number(value: wins, caption: 'Wins')),
          ],
        ),
        if (editMode) ...[
          const AppSectionLabel('Edit profile'),
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
        ] else ...[
          const AppSectionLabel('Account'),
          AppRows(
            children: [
              AppPlainRow(
                title: 'Edit profile',
                subtitle: 'Display name and bio',
                chevron: true,
                onTap: onEdit,
              ),
              AppPlainRow(
                title: 'Change password',
                chevron: true,
                onTap: onChangePassword,
              ),
              AppPlainRow(
                title: 'Sign out',
                titleColor: c.negativeText,
                onTap: onSignOut,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A mono number over a small-caps caption. No card.
class _Number extends StatelessWidget {
  final int value;
  final String caption;

  const _Number({required this.value, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedNumber(value: value, size: 22),
        AppSpacing.vXs,
        AppOverline(caption),
      ],
    );
  }
}

/// Loading placeholder shaped like the phone composition.
class _PhoneProfileSkeleton extends StatelessWidget {
  const _PhoneProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget row() => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: AppSkeleton.line(width: 150, height: 14),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: AppSkeleton.circle(size: 88)),
        AppSpacing.vLg,
        const Center(child: AppSkeleton.line(width: 160, height: 22)),
        AppSpacing.vSm,
        const Center(child: AppSkeleton.line(width: 200, height: 12)),
        AppSpacing.vLg,
        const Center(child: AppSkeleton.line(width: 220, height: 11)),
        AppSpacing.vSm,
        const AppSkeleton.line(height: 4),
        AppSpacing.vXxl,
        Row(
          children: [
            for (var i = 0; i < 3; i++)
              Expanded(
                child: Column(
                  children: const [
                    AppSkeleton.line(width: 40, height: 22),
                    SizedBox(height: AppSpacing.xs),
                    AppSkeleton.line(width: 56, height: 11),
                  ],
                ),
              ),
          ],
        ),
        AppSpacing.vXxxl,
        const AppSkeleton.line(width: 72, height: 11),
        AppSpacing.vSm,
        row(),
        row(),
        row(),
      ],
    );
  }
}
