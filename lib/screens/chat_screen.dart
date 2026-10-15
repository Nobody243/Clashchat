import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'results_screen.dart';
import 'home_screen.dart';
import '../core/responsive_layout.dart';
import '../models/chat_message.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/chat_input_bar.dart';
import '../services/ai_service.dart';
import '../services/auth_service.dart';
import '../services/timer_service.dart';
import '../services/usage_quota_service.dart';
import '../widgets/debate_timer_widget.dart';
import '../models/rank_model.dart';
import '../models/debate_mode.dart';
import '../ui/ui.dart';

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
  final ScrollController _scrollCtrl = ScrollController();
  bool _isAiTyping = false;
  bool _isSending = false;
  bool _isEnding = false;

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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Time's up. Scoring your debate..."),
        duration: Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _scoreAndEndDebate();
    });
  }

  @override
  void dispose() {
    _timerService.dispose();
    _inputCtrl.dispose();
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _ScoringOverlay(),
    );

    final result = await AiService.scoreDebate(
      topic: widget.topic,
      userStance: widget.stance,
      messages: _messages,
      difficulty: widget.difficulty,
    );

    if (!mounted) return;
    Navigator.of(context).pop(); // close loading

    debugPrint(
      'SCORE RESULT: ${result['score']} (Type: ${result['score'].runtimeType})',
    );
    debugPrint('FULL RESULT: $result');

    final finalScore = result['score'] is int
        ? result['score'] as int
        : int.tryParse(result['score'].toString()) ?? 65;
    final strengths = (result['strengths'] as List?)
            ?.map((item) => item.toString())
            .toList() ??
        const <String>[];
    final weaknesses = (result['weaknesses'] as List?)
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
        final userDocRef =
            FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(userDocRef);
          if (!snapshot.exists) return;
          final currentPoints =
              (snapshot.data()?['rankPoints'] as num?)?.toInt() ?? 0;
          // Get rank at time BEFORE points update
          final rankAtTime = RankModel.getRankFromPoints(currentPoints);
          currentRank = RankModel.rankData[rankAtTime]!['name'] as String;
          final newPoints = currentPoints + pointsEarned;
          transaction.update(
            userDocRef,
            {'rankPoints': newPoints < 0 ? 0 : newPoints},
          );
        });
      } catch (e) {
        debugPrint('Error updating rank points: $e');
      }
    }

    await _completeDebateSession();

    // Calculate duration: use elapsed time if timer was running, otherwise estimate from messages
    final int durationMinutes = widget.timerMinutes != null
        ? _timerService.elapsedMinutes
        : ((_messages.length * 2) / 60).ceil(); // estimate 2 seconds per message

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

    if (widget.mode == DebateMode.learning) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
        (_) => false,
      );
      return;
    }

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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth > ResponsiveLayout.desktopBreakpoint;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _showExitDialog(context);
      },
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: isDesktop ? _buildDesktopBody() : _buildMobileBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final text = context.text;
    const barHeight = 76.0;

    return PreferredSize(
      preferredSize: const Size.fromHeight(barHeight),
      child: AppReveal(
        child: AppBar(
          toolbarHeight: barHeight,
          titleSpacing: 0,
          leadingWidth: 56,
          leading: Center(
            child: AppIconButton(
              icon: AppIcons.back,
              tooltip: 'End debate',
              onPressed: () => _showExitDialog(context),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
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
          actions: [
            if (widget.timerMinutes != null) ...[
              DebateTimerWidget(
                timerService: _timerService,
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
            const SizedBox(width: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList({required EdgeInsets padding}) {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: padding,
      itemCount: _messages.length + (_isAiTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isAiTyping) {
          return const TypingIndicator();
        }
        final message = _messages[index];
        final prevMsg = index > 0 ? _messages[index - 1] : null;
        final nextMsg =
            index + 1 < _messages.length ? _messages[index + 1] : null;
        return MessageBubble(
          message: message,
          isGrouped: prevMsg?.isUser == message.isUser,
          isLastInGroup: nextMsg == null || nextMsg.isUser != message.isUser,
        );
      },
    );
  }

  Widget _buildMobileBody() {
    return Container(
      color: context.colors.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Expanded(
                child: _buildMessageList(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gutter,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
              AppReveal(
                index: 2,
                child: ChatInputBar(
                  controller: _inputCtrl,
                  onSend: _sendMessage,
                  enabled: !_isEnding,
                  isSending: _isSending || _isAiTyping,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopBody() {
    final c = context.colors;
    return Container(
      color: c.background,
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    Expanded(
                      child: _buildMessageList(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxl,
                          vertical: AppSpacing.lg,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.sm,
                      ),
                      child: ChatInputBar(
                        controller: _inputCtrl,
                        onSend: _sendMessage,
                        enabled: !_isEnding,
                        isSending: _isSending || _isAiTyping,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(left: BorderSide(color: c.border)),
            ),
            child: _buildDebateStatsPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildDebateStatsPanel() {
    final c = context.colors;
    final text = context.text;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: StaggeredColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: 'This debate'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppOverline('Topic'),
                const SizedBox(height: AppSpacing.sm),
                Text(widget.topic, style: text.titleSmall),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    AppPill.stance(widget.stance),
                    AppPill.difficulty(widget.difficulty),
                    AppPill.mode(widget.mode),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppOverline('Progress'),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Icon(AppIcons.messages, size: 18, color: c.textHint),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Messages',
                      style: text.bodySmall?.copyWith(color: c.textSecondary),
                    ),
                    const Spacer(),
                    Text(
                      '${_messages.length}',
                      style: context.mono(size: 16),
                    ),
                  ],
                ),
                if (widget.timerMinutes != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Icon(AppIcons.timer, size: 18, color: c.textHint),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Time left',
                        style:
                            text.bodySmall?.copyWith(color: c.textSecondary),
                      ),
                      const Spacer(),
                      DebateTimerWidget(
                        timerService: _timerService,
                        onTap: _toggleTimer,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// Scoring overlay (shown while AiService.scoreDebate runs)
// ══════════════════════════════════════════════════════════
class _ScoringOverlay extends StatelessWidget {
  const _ScoringOverlay();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;

    return Dialog.fullscreen(
      backgroundColor: c.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
          child: StaggeredColumn(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const AppSkeleton.circle(size: 120),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Scoring your debate',
                textAlign: TextAlign.center,
                style: text.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Reading every exchange…',
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: c.textSecondary),
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

    return Dialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
        side: BorderSide(color: c.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.titleMedium),
              const SizedBox(height: AppSpacing.md),
              Text(
                content,
                style: text.bodyMedium?.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton.secondary(
                    label: cancelLabel,
                    size: AppButtonSize.small,
                    expand: false,
                    onPressed: onCancel,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  AppButton.danger(
                    label: confirmLabel,
                    size: AppButtonSize.small,
                    expand: false,
                    icon: AppIcons.endDebate,
                    onPressed: () => onConfirm(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
