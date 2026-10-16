import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'results_screen.dart';
import '../models/chat_message.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/user_avatar.dart';
import '../services/ai_service.dart';
import '../services/auth_service.dart';
import '../services/avatar_preferences.dart';
import '../services/timer_service.dart';
import '../services/usage_quota_service.dart';
import '../widgets/debate_timer_widget.dart';
import '../models/rank_model.dart';
import '../models/debate_mode.dart';
import '../ui/ui.dart';

/// Argument prompts offered above the composer.
const List<String> _kArgumentPrompts = [
  'Give an example',
  'Cite a number',
  'Challenge their claim',
  'Concede, then pivot',
];

class ChatScreen extends StatefulWidget {
  final String topic;
  final String stance;
  final String difficulty;
  final int? timerMinutes;
  final DebateMode mode;

  const ChatScreen({
    super.key,
    required this.topic,
    required this.stance,
    required this.difficulty,
    this.timerMinutes,
    required this.mode,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputCtrl = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isAiTyping = false;
  bool _isSending = false;
  bool _isEnding = false;
  String _endTitle = 'Scoring your debate';

  /// Dicebear seed for the user's avatar column on wide layouts.
  String? _avatarSeed;

  /// Measured heights of the floating glass bars; the list scrolls under both.
  double _headerHeight = 0;
  double _composerHeight = 0;

  late DebateTimerService _timerService;

  @override
  void initState() {
    super.initState();

    _timerService = DebateTimerService();
    if (widget.timerMinutes != null) {
      _timerService.start(
        widget.timerMinutes!,
        onExpired: () => _onTimerExpired(),
      );
    }

    AvatarPreferences.loadAvatar().then((seed) {
      if (mounted) setState(() => _avatarSeed = seed);
    });

    Future.delayed(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      setState(() => _isAiTyping = true);

      final opener = await AiService.sendDebateMessage(
        topic: widget.topic,
        userStance: widget.stance,
        history: [],
        userMessage: 'Start the debate with a strong opening challenge.',
        difficulty: widget.difficulty,
        isLearningMode: widget.mode == DebateMode.learning,
      );

      if (!mounted) return;
      setState(() {
        _isAiTyping = false;
        _messages.add(opener);
      });
      _scrollToBottom();
    });
  }

  void _onTimerExpired() {
    if (!mounted) return;
    _endTitle = "Time's up";
    _scoreAndEndDebate();
  }

  @override
  void dispose() {
    _timerService.dispose();
    _inputCtrl.dispose();
    _inputFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    if (_timerService.isRunning) {
      _timerService.pause();
    } else {
      _timerService.resume();
    }
  }

  void _showExitDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _ConfirmDialog(
        title: 'End debate?',
        content: 'If you leave now the debate will be ended and scored.',
        cancelLabel: 'Cancel',
        confirmLabel: 'End debate',
        onCancel: () => Navigator.of(dialogContext).pop(false),
        onConfirm: () async {
          Navigator.of(dialogContext).pop();
          await _scoreAndEndDebate();
        },
      ),
    );
  }

  Future<void> _completeDebateSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final sessionDoc = FirebaseFirestore.instance
        .collection('debates')
        .doc(user.uid)
        .collection('session')
        .doc('active');

    await sessionDoc.set({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'topic': widget.topic,
      'stance': widget.stance,
      'difficulty': widget.difficulty,
      'mode': widget.mode.name,
    }, SetOptions(merge: true));
  }

  Future<void> _sendMessage() async {
    if (_isSending || _isAiTyping || _isEnding) return;

    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;

    final currentUser = AuthService.currentUser;
    if (currentUser == null) return;

    // Immediately clear input controller so subsequent taps/keystrokes cannot resend
    _inputCtrl.clear();

    // Optimistic UI update: show message immediately (0ms delay)
    final userMsg = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _isSending = true;
      _messages.add(userMsg);
      _isAiTyping = true;
    });
    _scrollToBottom();

    try {
      final quotaAvailable = await UsageQuotaService.consume(currentUser.uid);
      if (!quotaAvailable) {
        if (!mounted) return;
        setState(() {
          _messages.remove(userMsg);
          _isAiTyping = false;
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Daily usage exhausted. You have no debate uses left today.',
            ),
          ),
        );
        return;
      }

      final priorHistory = _messages.length > 1
          ? _messages.sublist(0, _messages.length - 1)
          : const <ChatMessage>[];

      // Call AI Service
      final aiReply = await AiService.sendDebateMessage(
        topic: widget.topic,
        userStance: widget.stance,
        history: priorHistory,
        userMessage: text,
        difficulty: widget.difficulty,
        isLearningMode: widget.mode == DebateMode.learning,
      );

      if (!mounted) return;
      setState(() {
        _isAiTyping = false;
        _messages.add(aiReply);
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        setState(() => _isAiTyping = false);
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _scoreAndEndDebate() async {
    if (_isEnding) return;
    setState(() => _isEnding = true);

    final currentUser = AuthService.currentUser;
    if (currentUser == null) {
      setState(() => _isEnding = false);
      return;
    }

    if (!await UsageQuotaService.consume(currentUser.uid)) {
      if (!mounted) return;
      setState(() => _isEnding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Daily usage exhausted. You cannot generate a score right now.',
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    // The chat is replaced by the scoring view (see build) until the
    // results route takes over, so the conversation never flashes back.

    final result = await AiService.scoreDebate(
      topic: widget.topic,
      userStance: widget.stance,
      messages: _messages,
      difficulty: widget.difficulty,
    );

    if (!mounted) return;

    debugPrint(
      'SCORE RESULT: ${result['score']} (Type: ${result['score'].runtimeType})',
    );
    debugPrint('FULL RESULT: $result');

    final finalScore = result['score'] is int
        ? result['score'] as int
        : int.tryParse(result['score'].toString()) ?? 65;
    final strengths =
        (result['strengths'] as List?)
            ?.map((item) => item.toString())
            .toList() ??
        const <String>[];
    final weaknesses =
        (result['weaknesses'] as List?)
            ?.map((item) => item.toString())
            .toList() ??
        const <String>[];
    final summary = result['summary']?.toString() ?? 'Debate completed';

    // Get current rank before updating points
    String currentRank = 'Newcomer';
    int pointsEarned = 0;
    if (widget.mode == DebateMode.ranked) {
      pointsEarned = RankModel.calculatePointsEarned(finalScore, true);
      try {
        final userDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(userDocRef);
          if (!snapshot.exists) return;
          final currentPoints =
              (snapshot.data()?['rankPoints'] as num?)?.toInt() ?? 0;
          // Get rank at time BEFORE points update
          final rankAtTime = RankModel.getRankFromPoints(currentPoints);
          currentRank = RankModel.rankData[rankAtTime]!['name'] as String;
          final newPoints = currentPoints + pointsEarned;
          transaction.update(userDocRef, {
            'rankPoints': newPoints < 0 ? 0 : newPoints,
          });
        });
      } catch (e) {
        debugPrint('Error updating rank points: $e');
      }
    }

    await _completeDebateSession();

    // Calculate duration: use elapsed time if timer was running, otherwise estimate from messages
    final int durationMinutes = widget.timerMinutes != null
        ? _timerService.elapsedMinutes
        : ((_messages.length * 2) / 60)
              .ceil(); // estimate 2 seconds per message

    debugPrint(
      'SAVING TO FIRESTORE - Score: $finalScore (Type: ${finalScore.runtimeType})',
    );
    debugPrint('TIMER DURATION: $durationMinutes minutes');
    await FirebaseFirestore.instance
        .collection('debates')
        .doc(currentUser.uid)
        .collection('history')
        .add({
          'topic': widget.topic,
          'stance': widget.stance,
          'difficulty': widget.difficulty,
          'score': finalScore,
          'mode': widget.mode.name,
          'summary': summary,
          'strengths': strengths,
          'weaknesses': weaknesses,
          'messageCount': _messages.length,
          'date': DateTime.now().toIso8601String(),
          'status': 'completed',
          'isRanked': widget.mode == DebateMode.ranked,
          'pointsEarned': pointsEarned,
          'timerMinutes': widget.timerMinutes,
          'durationMinutes': durationMinutes,
          'rankAtTime': currentRank,
          'messages': _messages
              .map(
                (m) => {
                  'text': m.text,
                  'isUser': m.isUser,
                  'timestamp': m.timestamp.toIso8601String(),
                  'coachTip': m.coachTip,
                },
              )
              .toList(),
        });

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) {
          debugPrint(
            'FINAL SCORE FOR RESULTS SCREEN: $finalScore (Type: ${finalScore.runtimeType})',
          );
          debugPrint(
            '  Raw result score was: ${result['score']} (Type: ${result['score'].runtimeType})',
          );
          // Create a copy of messages to prevent clearing issues
          final messagesCopy = List<ChatMessage>.from(_messages);
          return ResultsScreen(
            topic: widget.topic,
            stance: widget.stance,
            messages: messagesCopy,
            score: finalScore,
            strengths: List<String>.from(result['strengths'] ?? []),
            weaknesses: List<String>.from(result['weaknesses'] ?? []),
            summary: result['summary'] ?? '',
            difficulty: widget.difficulty,
            pointsEarned: pointsEarned,
            mode: widget.mode,
            isFromHistory: false,
            durationMinutes: durationMinutes,
          );
        },
      ),
    );
  }

  // ── UI ──────────────────────────────────────────────────────────────────

  /// Inserts `"<prompt>: "` at the cursor and focuses the field.
  void _insertPrompt(String prompt) {
    final insert = '$prompt: ';
    final value = _inputCtrl.value;
    final text = value.text;
    final sel = value.selection;
    final start = sel.isValid ? sel.start.clamp(0, text.length) : text.length;
    final end = sel.isValid ? sel.end.clamp(0, text.length) : text.length;
    _inputCtrl.value = TextEditingValue(
      text: text.replaceRange(start, end, insert),
      selection: TextSelection.collapsed(offset: start + insert.length),
    );
    _inputFocus.requestFocus();
  }

  String? get _latestCoachTip {
    for (var i = _messages.length - 1; i >= 0; i--) {
      final tip = _messages[i].coachTip;
      if (!_messages[i].isUser && tip != null && tip.trim().isNotEmpty) {
        return tip;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final twoPane = context.isExpanded || context.isLarge;

    if (_isEnding) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: context.colors.background,
          body: _ScoringOverlay(title: _endTitle),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _showExitDialog(context);
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: context.colors.background,
        body: AppBackdrop(
          intensity: 0.7,
          child: twoPane
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildChatPane()),
                    _buildSidePanel(),
                  ],
                )
              : _buildChatPane(),
        ),
      ),
    );
  }

  /// Scrolling list with the glass header and composer floating over it.
  Widget _buildChatPane() {
    final gutter = context.isCompact ? AppSpacing.gutter : AppSpacing.xxl;
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: _buildMessageList(
              padding: EdgeInsets.fromLTRB(
                gutter,
                _headerHeight + AppSpacing.md,
                gutter,
                _composerHeight + AppSpacing.md,
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _SizeReporter(
            onSize: (s) {
              if (s.height != _headerHeight) {
                setState(() => _headerHeight = s.height);
              }
            },
            child: AppReveal(child: _buildHeader(context)),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _SizeReporter(
            onSize: (s) {
              if (s.height != _composerHeight) {
                setState(() => _composerHeight = s.height);
              }
            },
            child: AppReveal(
              index: 2,
              child: ChatInputBar(
                controller: _inputCtrl,
                focusNode: _inputFocus,
                onSend: _sendMessage,
                enabled: !_isEnding,
                isSending: _isSending || _isAiTyping,
                prompts: _kArgumentPrompts,
                onPromptTap: _insertPrompt,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final text = context.text;
    final topInset = MediaQuery.paddingOf(context).top;
    final gutter = context.isCompact ? AppSpacing.gutter : AppSpacing.xxl;

    return GlassBar(
      padding: EdgeInsets.fromLTRB(
        gutter - AppSpacing.sm,
        topInset + AppSpacing.sm,
        gutter,
        AppSpacing.md,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppIconButton(
                icon: AppIcons.back,
                tooltip: 'End debate',
                onPressed: () => _showExitDialog(context),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.topic,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs + 2),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        AppPill.stance(widget.stance),
                        AppPill.mode(widget.mode),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (widget.timerMinutes != null) ...[
                DebateTimerWidget(
                  timerService: _timerService,
                  totalSeconds: widget.timerMinutes! * 60,
                  onTap: _toggleTimer,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              AppButton.danger(
                label: 'End',
                size: AppButtonSize.small,
                expand: false,
                icon: AppIcons.endDebate,
                onPressed: _isEnding ? null : () => _showExitDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aiAvatar() => const AppIconTile(
    icon: AppIcons.ai,
    size: 28,
    iconSize: 16,
    radius: BorderRadius.all(Radius.circular(14)),
  );

  Widget _userAvatar() {
    final seed = _avatarSeed;
    if (seed == null) {
      return AppIconTile(
        icon: AppIcons.user,
        size: 28,
        iconSize: 16,
        color: context.colors.textSecondary,
        background: context.colors.surfaceRaised,
        radius: const BorderRadius.all(Radius.circular(14)),
      );
    }
    return UserAvatar(seed: seed, size: 28);
  }

  Widget _buildMessageList({required EdgeInsets padding}) {
    final showAvatars = context.isWide;
    return ListView.builder(
      controller: _scrollCtrl,
      padding: padding,
      itemCount: _messages.length + (_isAiTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isAiTyping) {
          return TypingIndicator(
            reserveLeading: showAvatars,
            leading: showAvatars ? _aiAvatar() : null,
          );
        }
        final message = _messages[index];
        final prevMsg = index > 0 ? _messages[index - 1] : null;
        final nextMsg = index + 1 < _messages.length
            ? _messages[index + 1]
            : null;
        final isLast = nextMsg == null || nextMsg.isUser != message.isUser;
        return MessageBubble(
          message: message,
          isGrouped: prevMsg?.isUser == message.isUser,
          isLastInGroup: isLast,
          reserveLeading: showAvatars,
          leading: showAvatars && isLast
              ? (message.isUser ? _userAvatar() : _aiAvatar())
              : null,
        );
      },
    );
  }

  /// Sticky 320 px glass panel beside the chat on ≥ 900.
  Widget _buildSidePanel() {
    final c = context.colors;
    final text = context.text;
    final topInset = MediaQuery.paddingOf(context).top;
    final tip = _latestCoachTip;

    return SizedBox(
      width: 320 + AppSpacing.xxl,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          0,
          topInset + AppSpacing.lg,
          AppSpacing.xxl,
          AppSpacing.xxl,
        ),
        child: AppReveal(
          index: 1,
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppOverline('This debate'),
                const SizedBox(height: AppSpacing.sm),
                Text(widget.topic, style: text.titleSmall),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    AppPill.stance(widget.stance),
                    AppPill.mode(widget.mode),
                    AppPill.difficulty(widget.difficulty),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Divider(height: 1, thickness: 1, color: c.border),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Icon(
                      AppIcons.ai,
                      size: 16,
                      color: _isAiTyping ? c.accent : c.textHint,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: AppDurations.fast,
                        child: SizedBox(
                          key: ValueKey(_isAiTyping),
                          width: double.infinity,
                          child: Text(
                            _isAiTyping ? 'ClashBot is thinking' : 'Your turn',
                            style: text.bodySmall?.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Icon(AppIcons.messages, size: 16, color: c.textHint),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Messages',
                        style: text.bodySmall?.copyWith(color: c.textSecondary),
                      ),
                    ),
                    AnimatedNumber(value: _messages.length, size: 16),
                  ],
                ),
                if (widget.mode == DebateMode.learning && tip != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  const AppOverline('Latest coach tip'),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    level: AppCardLevel.raised,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    radius: AppRadius.mdAll,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Icon(
                            AppIcons.coachTipFilled,
                            size: 16,
                            color: c.infoText,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(tip, style: text.bodySmall)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// Size reporter: lets the list pad itself by the real height of the
// floating bars (which grow with the multiline field and safe areas).
// ══════════════════════════════════════════════════════════
class _SizeReporter extends StatefulWidget {
  const _SizeReporter({required this.child, required this.onSize});

  final Widget child;
  final ValueChanged<Size> onSize;

  @override
  State<_SizeReporter> createState() => _SizeReporterState();
}

class _SizeReporterState extends State<_SizeReporter> {
  final GlobalKey _key = GlobalKey();
  Size? _last;

  void _report() {
    if (!mounted) return;
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    if (_last == box.size) return;
    _last = box.size;
    widget.onSize(box.size);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _report());
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _report());
        return true;
      },
      child: SizeChangedLayoutNotifier(
        child: KeyedSubtree(key: _key, child: widget.child),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// Scoring overlay (shown while AiService.scoreDebate runs)
// ══════════════════════════════════════════════════════════
class _ScoringOverlay extends StatefulWidget {
  const _ScoringOverlay({this.title = 'Scoring your debate'});

  final String title;

  @override
  State<_ScoringOverlay> createState() => _ScoringOverlayState();
}

class _ScoringOverlayState extends State<_ScoringOverlay> {
  static const List<String> _steps = [
    'Reading every exchange…',
    'Weighing your evidence…',
    'Checking for fallacies…',
    'Writing your feedback…',
  ];

  Timer? _timer;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (!mounted) return;
      setState(() => _step = (_step + 1) % _steps.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;

    return AppBackdrop(
      intensity: 0.7,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
          child: StaggeredColumn(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const AppSkeleton.circle(size: 120),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: text.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              AnimatedSwitcher(
                duration: kRevealDuration,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: anim.drive(
                      Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ),
                    ),
                    child: child,
                  ),
                ),
                child: Text(
                  _steps[_step],
                  key: ValueKey(_step),
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(color: c.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// Confirm dialog
// ══════════════════════════════════════════════════════════
class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onCancel;
  final Future<void> Function() onConfirm;

  const _ConfirmDialog({
    required this.title,
    required this.content,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;

    return AlertDialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
        side: BorderSide(color: c.border),
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.md,
        AppSpacing.xxl,
        AppSpacing.sm,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.sm,
        AppSpacing.xxl,
        AppSpacing.xxl,
      ),
      title: Text(title, style: text.titleMedium),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Text(
          content,
          style: text.bodyMedium?.copyWith(color: c.textSecondary),
        ),
      ),
      actions: [
        AppButton.secondary(
          label: cancelLabel,
          size: AppButtonSize.small,
          expand: false,
          onPressed: onCancel,
        ),
        AppButton.danger(
          label: confirmLabel,
          size: AppButtonSize.small,
          expand: false,
          icon: AppIcons.endDebate,
          onPressed: () => onConfirm(),
        ),
      ],
    );
  }
}
