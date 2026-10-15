import 'dart:async';
import 'dart:convert';
import 'dart:math' show min;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/chat_message.dart';

class AiService {
  static const String _apiEndpoint =
      'https://clashchat-proxy.clashchat-proxy-2026.workers.dev/';
  static final String _appSecret = dotenv.env['APP_SHARED_SECRET']!;
  
  static const List<String> _models = [
    'openai/gpt-oss-120b',
    'openai/gpt-oss-20b',
    'groq/compound',
  ];

  /// Headers for every proxy call.
  ///
  /// `X-App-Secret` is a cheap abuse deterrent (it ships inside the client).
  /// The real identity check is the Firebase ID token: the proxy verifies it
  /// and uses the uid for per-user rate limiting.
  static Future<Map<String, String>> _authHeaders() async {
    final headers = <String, String>{
      'X-App-Secret': _appSecret,
      'Content-Type': 'application/json',
    };
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken != null && idToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $idToken';
      }
    } catch (e) {
      debugPrint('AiService: could not fetch ID token: $e');
    }
    return headers;
  }

  static Future<http.Response?> _postWithFallback(
    List<Map<String, String>> messages, {
    int maxTokens = 500,
    double temperature = 0.7,
    bool jsonMode = false,
  }) async {
    for (final model in _models) {
      try {
        final Map<String, dynamic> requestBody = {
          'model': model,
          'messages': messages,
          'max_tokens': maxTokens,
          'temperature': temperature,
        };

        if (jsonMode) {
          requestBody['response_format'] = {'type': 'json_object'};
        }

        final response = await http
            .post(
              Uri.parse(_apiEndpoint),
              headers: await _authHeaders(),
              body: jsonEncode(requestBody),
            )
            .timeout(
              const Duration(seconds: 8),
              onTimeout: () => throw TimeoutException('$model timed out'),
            );

        if (response.statusCode == 200) {
          return response;
        } else {
          debugPrint('GROQ ERROR ($model): ${response.statusCode} - ${response.body}');
        }
      } on TimeoutException catch (e) {
        debugPrint('GROQ TIMEOUT ($model): $e');
      } catch (e) {
        debugPrint('GROQ REQUEST ERROR ($model): $e');
      }
    }
    return null;
  }

  static String _cleanAiText(String text) {
    // Remove thinking tags if present
    final cleaned = text
        .replaceAll(RegExp(r'<think>[\s\S]*?<\/think>', caseSensitive: false), '')
        .trim();
    return cleaned.isNotEmpty ? cleaned : text.trim();
  }

  static List<Map<String, String>> _buildDebateMessages({
    required String topic,
    required String userStance,
    required List<ChatMessage> history,
    required String userMessage,
    required String difficulty,
    bool isLearningMode = false,
  }) {
    final isStanceFor = userStance.trim().toLowerCase() == 'for';
    final aiStance = isStanceFor ? 'Against' : 'For';
    final userStanceLabel = isStanceFor ? 'FOR' : 'AGAINST';
    final aiStanceLabel = isStanceFor ? 'AGAINST' : 'FOR';

    String toneGuide;
    switch (difficulty.toLowerCase()) {
      case 'easy':
      case 'newcomer':
        toneGuide =
            'Style: Casual, friendly, and approachable opponent for beginners.\n'
            '- Approach: Portray your counter-argument with clear, simple points and relatable everyday examples (e.g., daily habits, routine chores, simple life analogies).\n'
            '- Language: Simple everyday words only, never intimidating or overly complex.\n'
            '- Length: Maximum 2 short sentences.';
        break;
      case 'medium':
      case 'challenger':
      case 'debater':
        toneGuide =
            'Style: Articulate, evidence-driven, and engaging debate opponent.\n'
            '- Approach: Formulate strong counter-arguments reinforced with concrete statistics, empirical metrics, real-world data points, and studies.\n'
            '- Language: Refined, persuasive vocabulary and structured logical reasoning.\n'
            '- Length: Maximum 2-3 sentences.';
        break;
      case 'hard':
      case 'orator':
      case 'grandmaster':
        toneGuide =
            'Style: Master-level competitive debater (world-class tournament standard).\n'
            '- Approach: Surgically tackle the user\'s exact response by dissecting their specific premises, unstated assumptions, causal leaps, or logical fallacies with razor-sharp analytical precision.\n'
            '- Language: Cutting, sophisticated rhetoric and flawless counter-logic that directly dismantles the user\'s claim.\n'
            '- Length: Maximum 3 sentences.';
        break;
      default:
        toneGuide =
            'Style: Balanced, articulate debate opponent with strong reasoning. Maximum 2-3 sentences.';
    }

    final String systemPrompt;
    if (isLearningMode) {
      systemPrompt = '''You are ClashBot, an interactive debate opponent and coach in a live debate duel.
Debate Topic: "$topic"
User's Position: $userStanceLabel ($userStance)
Your Position: $aiStanceLabel ($aiStance)
Difficulty Level: $difficulty
$toneGuide

CORE INSTRUCTIONS:
1. DIRECT REBUTTAL: You MUST directly tackle and respond to the user's EXACT latest words and claims. Dissect their specific statements and defend your position with precision!
2. HANDLING OFF-TOPIC REMARKS: If the user goes off-topic (talking about unrelated subjects, random questions, or tangents), politely and smoothly acknowledge their remark without being dismissive or rude, then steer the argument back to the debate topic of "$topic". In your "coach_tip", constructively remind them to stay focused on the topic to score debate points.
3. HANDLING RUDE OR HOSTILE REMARKS: If the user makes rude remarks, insults, hostile comments, or uses foul language, respond in a completely calm, composed, dignified, and respectful manner. Never retaliate or insult them back; calmly de-escalate and challenge them to focus on the actual merits of "$topic". In your "coach_tip", gently advise that ad hominem attacks weaken a debate argument.
4. NO SCRIPTED MONOLOGUES: Never ignore what the user said just to deliver a generic speech about the topic. Every reply must be an organic, real-time rebuttal.
5. CONVERSATIONAL CONTINUITY: Build dynamically on the debate back-and-forth. Never repeat previous arguments or phrasing.
6. STRICT JSON FORMAT: You MUST return strictly valid JSON with exactly two keys:
   - "coach_tip": 1-2 sentence constructive tip analyzing the user's latest debate technique, logical strength, or how they can improve.
   - "argument": Your in-character rebuttal arguing $aiStanceLabel on "$topic" matching the difficulty style above.
Do NOT output any text, markdown backticks, or preamble outside the JSON object.''';
    } else {
      systemPrompt = '''You are ClashBot, an intelligent, sharp, and interactive AI debate opponent in a live 1-on-1 debate duel.
Debate Topic: "$topic"
User's Position: $userStanceLabel ($userStance)
Your Position: $aiStanceLabel ($aiStance)
Difficulty Level: $difficulty
$toneGuide

CORE DEBATE RULES:
1. ALWAYS DIRECTLY ADDRESS THE USER: You MUST directly respond to, rebut, and confront the user's EXACT words, claims, challenges, or questions in their latest message. Rebut their exact premise directly!
2. HANDLING OFF-TOPIC REMARKS: If the user goes off-topic (talking about unrelated subjects, random questions, or tangents), politely acknowledge their remark without being dismissive or rude, then smoothly steer the discussion back to the core debate topic of "$topic".
3. HANDLING RUDE OR HOSTILE REMARKS: If the user makes rude remarks, insults, personal attacks, or uses aggressive language, respond in a calm, poised, dignified, and respectful manner. Never retaliate or get defensive; calmly rise above the hostility and invite them to focus on substantiating their actual arguments on "$topic".
4. NO CANNED OR SCRIPTED STATEMENTS: Never ignore what the user said just to deliver a generic monologue about the topic. Every response must be an organic, real-time rebuttal to the user's specific point.
5. CONVERSATIONAL PROGRESSION: Build dynamically on the debate history. Never repeat points, examples, or sentences you used in earlier turns.
6. STAY IN CHARACTER & CONCISE: Speak directly to the user in second person ("you"), passionately defend your stance ($aiStanceLabel), and keep your response punchy and engaging (strictly adhering to the sentence limits). Never include conversational filler like "As an AI" or generic greetings.''';
    }

    final List<Map<String, String>> messages = [
      {'role': 'system', 'content': systemPrompt},
    ];

    final isOpeningRequest = history.isEmpty ||
        userMessage == 'Start the debate with a strong opening challenge.';

    if (isOpeningRequest) {
      messages.add({
        'role': 'user',
        'content':
            'Deliver a bold, provocative opening challenge arguing $aiStanceLabel on the topic of "$topic" against someone who is $userStanceLabel.',
      });
    } else {
      // Trim history to the last 10 entries if longer
      final trimmedHistory =
          history.length > 10 ? history.sublist(history.length - 10) : history;

      for (final msg in trimmedHistory) {
        if (msg.isUser) {
          messages.add({'role': 'user', 'content': msg.text});
        } else {
          messages.add({
            'role': 'assistant',
            'content': isLearningMode && msg.coachTip != null
                ? jsonEncode({
                    'coach_tip': msg.coachTip,
                    'argument': msg.text,
                  })
                : msg.text,
          });
        }
      }

      // Always append userMessage as the final user message
      messages.add({'role': 'user', 'content': userMessage});
    }

    return messages;
  }

  static Future<ChatMessage> sendDebateMessage({
    required String topic,
    required String userStance,
    required List<ChatMessage> history,
    required String userMessage,
    required String difficulty,
    bool isLearningMode = false,
  }) async {
    try {
      final messages = _buildDebateMessages(
        topic: topic,
        userStance: userStance,
        history: history,
        userMessage: userMessage,
        difficulty: difficulty,
        isLearningMode: isLearningMode,
      );

      final response = await _postWithFallback(
        messages,
        maxTokens: isLearningMode ? 650 : 600,
        temperature: 0.6,
        jsonMode: isLearningMode,
      );

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawContent = data['choices']?[0]?['message']?['content'] as String?;

        if (rawContent == null || rawContent.isEmpty) {
          return ChatMessage(
            text: 'Let me think about that...',
            isUser: false,
            timestamp: DateTime.now(),
          );
        }

        final content = _cleanAiText(rawContent);

        if (isLearningMode) {
          try {
            Map<String, dynamic>? parsed;
            try {
              parsed = jsonDecode(content) as Map<String, dynamic>;
            } catch (_) {
              final jsonStart = content.indexOf('{');
              final jsonEnd = content.lastIndexOf('}') + 1;
              if (jsonStart >= 0 && jsonEnd > jsonStart) {
                final jsonStr = content.substring(jsonStart, jsonEnd);
                parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
              }
            }

            if (parsed != null) {
              return ChatMessage(
                text: parsed['argument']?.toString() ?? content,
                isUser: false,
                timestamp: DateTime.now(),
                coachTip: parsed['coach_tip']?.toString(),
              );
            }
          } catch (e) {
            debugPrint('JSON Parse error in learning mode: $e');
          }
        }

        return ChatMessage(
          text: content,
          isUser: false,
          timestamp: DateTime.now(),
        );
      } else {
        return ChatMessage(
          text: 'Connection error. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('AI Service Error: $e');
      return ChatMessage(
        text: 'Connection error. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Streams debate opponent replies token by token via Server-Sent Events (SSE).
  /// The proxy passes Groq's SSE body straight through when `stream: true`.
  static Stream<String> sendDebateMessageStream({
    required String topic,
    required String userStance,
    required List<ChatMessage> history,
    required String userMessage,
    required String difficulty,
    bool isLearningMode = false,
  }) async* {
    // Learning mode requires full JSON parsing for coach_tip and argument, so
    // fall back to non-streaming sendDebateMessage.
    if (isLearningMode) {
      final msg = await sendDebateMessage(
        topic: topic,
        userStance: userStance,
        history: history,
        userMessage: userMessage,
        difficulty: difficulty,
        isLearningMode: isLearningMode,
      );
      yield msg.text;
      return;
    }

    final messages = _buildDebateMessages(
      topic: topic,
      userStance: userStance,
      history: history,
      userMessage: userMessage,
      difficulty: difficulty,
      isLearningMode: false,
    );

    for (final model in _models) {
      final client = http.Client();
      var hasYieldedAny = false;
      var accumulatedText = '';

      try {
        final request = http.Request('POST', Uri.parse(_apiEndpoint))
          ..headers.addAll(await _authHeaders())
          ..body = jsonEncode({
            'model': model,
            'messages': messages,
            'max_tokens': 600,
            'temperature': 0.6,
            'stream': true,
          });

        final streamedResponse = await client
            .send(request)
            .timeout(
              const Duration(seconds: 8),
              onTimeout: () => throw TimeoutException('$model stream timed out'),
            );

        if (streamedResponse.statusCode == 200) {
          final lineStream = streamedResponse.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter());

          await for (final line in lineStream) {
            final trimmed = line.trim();
            if (trimmed.isEmpty) continue;
            if (trimmed.startsWith('data: ')) {
              final data = trimmed.substring(6).trim();
              if (data == '[DONE]') break;
              try {
                final json = jsonDecode(data) as Map<String, dynamic>;
                final delta = json['choices']?[0]?['delta']?['content'] as String?;
                if (delta != null && delta.isNotEmpty) {
                  hasYieldedAny = true;
                  accumulatedText += delta;
                  yield accumulatedText;
                }
              } catch (_) {
                // Ignore malformed intermediate chunk
              }
            }
          }

          if (hasYieldedAny) {
            client.close();
            return;
          }
        } else {
          debugPrint('GROQ STREAM ERROR ($model): ${streamedResponse.statusCode}');
        }
      } on TimeoutException catch (e) {
        debugPrint('GROQ STREAM TIMEOUT ($model): $e');
      } catch (e) {
        debugPrint('GROQ STREAM REQUEST ERROR ($model): $e');
      } finally {
        client.close();
      }

      if (hasYieldedAny) {
        return;
      }
    }

    final fallbackMsg = await sendDebateMessage(
      topic: topic,
      userStance: userStance,
      history: history,
      userMessage: userMessage,
      difficulty: difficulty,
      isLearningMode: false,
    );
    yield fallbackMsg.text;
  }

  static Future<Map<String, dynamic>> scoreDebate({
    required String topic,
    required String userStance,
    required List<ChatMessage> messages,
    required String difficulty,
  }) async {
    try {
      final userMessages = messages
          .map((m) => '${m.isUser ? "User" : "ClashBot"}: ${m.text}')
          .join('\n');

      final userMessageCount = messages.where((m) => m.isUser).length;

      debugPrint('SCORING SESSION:');
      debugPrint('   Topic: $topic');
      debugPrint('   User stance: $userStance');
      debugPrint('   Difficulty: $difficulty');
      debugPrint('   User messages count: $userMessageCount');
      debugPrint('   Total messages: ${messages.length}');
      debugPrint('   Messages:');
      for (var i = 0; i < messages.length; i++) {
        final m = messages[i];
        debugPrint(
          '      [$i] ${m.isUser ? "USER" : "BOT"}: ${m.text.substring(0, min(m.text.length, 100))}...',
        );
      }

      final prompt =
          '''You are a debate judge. Evaluate the user's debate performance using the guidelines below.

USER DETAILS:
- Topic: "$topic"
- User stance: $userStance
- Difficulty Level: $difficulty
- User made: $userMessageCount arguments/responses
- Total exchanges: ${messages.length}

CONVERSATION TO EVALUATE:
$userMessages

DIFFICULTY-BASED SCORING CRITERIA:

${(difficulty.toLowerCase() == 'easy' || difficulty.toLowerCase() == 'newcomer')
              ? '''EASY MODE (Beginner Level):
- 10-25: Gave up or no real responses
- 26-40: Minimal effort, vague answers
- 41-55: Some good points but inconsistent
- 56-70: Held your ground against a basic opponent
- 71-85: Strong arguments despite easy difficulty
- 86-100: Dominated with excellent logic

Expectations: At least 2-3 arguments shown. Clarity valued over complexity.
Min messages for score tiers: 2+ for 40+, 3+ for 70+
'''
              : (difficulty.toLowerCase() == 'medium' || difficulty.toLowerCase() == 'challenger' || difficulty.toLowerCase() == 'debater')
              ? '''MEDIUM MODE (Standard Level):
- 10-25: Couldn't respond or got crushed
- 26-40: Weak arguments, easily countered
- 41-55: Fair points but missed opportunities
- 56-70: Good defense of your stance
- 71-85: Strong logical chains and examples
- 86-100: Exceptional reasoning and strategy

Expectations: At least 3-4 arguments with clear reasoning.
Min messages for score tiers: 3+ for 40+, 4+ for 70+, 5+ for 85+
'''
              : '''HARD MODE (Advanced Level):
- 10-25: Major logical flaws or surrender
- 26-40: Basic arguments only, no depth
- 41-55: Decent points but weak against advanced opponent
- 56-70: Held ground with reasonable rebuttals
- 71-85: Strong logic with good counter-arguments
- 86-100: Expert-level reasoning, evidence, and strategy

Expectations: At least 4-5 arguments with sophisticated reasoning. Examples/evidence required.
Min messages for score tiers: 4+ for 40+, 5+ for 70+, 6+ for 85+
'''}

STRICT RULES (apply these):
- Score between 10-100 only
- Penalize if message count is below difficulty minimum for that score tier
- Give bonus +5 if concrete examples or statistics provided
- Factor argument quality + quantity + consistency
- Consider how well user responded to opponent's counter-arguments

RETURN VALID JSON ONLY (no other text):
{
  "score": 72,
  "strengths": ["specific thing user did well"],
  "weaknesses": ["specific gap or mistake"],
  "summary": "brief honest assessment"
}

Judge fairly for this difficulty level. Score now with ONLY the JSON object.
''';

      final response = await _postWithFallback(
        [
          {'role': 'user', 'content': prompt},
        ],
        maxTokens: 500,
        temperature: 0.4,
        jsonMode: true,
      );

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawText = data['choices']?[0]?['message']?['content'] as String?;
        debugPrint('API RESPONSE TEXT: "$rawText"');

        if (rawText != null && rawText.isNotEmpty) {
          final text = _cleanAiText(rawText);
          try {
            Map<String, dynamic>? parsed;
            try {
              parsed = jsonDecode(text) as Map<String, dynamic>;
            } catch (_) {
              final jsonStart = text.indexOf('{');
              final jsonEnd = text.lastIndexOf('}') + 1;
              if (jsonStart >= 0 && jsonEnd > jsonStart) {
                final jsonStr = text.substring(jsonStart, jsonEnd);
                parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
              }
            }

            if (parsed != null) {
              debugPrint('PARSED JSON: $parsed');

              final rawScore = parsed['score'];
              debugPrint(
                'RAW SCORE VALUE: "$rawScore" (Type: ${rawScore.runtimeType})',
              );

              int? score;
              if (rawScore is int) {
                score = rawScore;
                debugPrint('  Score is int: $score');
              } else if (rawScore is double) {
                score = rawScore.toInt();
                debugPrint('  Score is double, converted: $score');
              } else if (rawScore is String) {
                score = int.tryParse(rawScore);
                debugPrint('  Score is string, parsed: $score');
              } else {
                debugPrint('  Score is unexpected type: ${rawScore.runtimeType}');
              }

              if (score != null && score >= 10 && score <= 100) {
                debugPrint('SCORE IS VALID (10-100): $score');
                parsed['score'] = score;
                parsed['strengths'] = _normalizeStringList(parsed['strengths']);
                parsed['weaknesses'] = _normalizeStringList(parsed['weaknesses']);
                parsed['summary'] = parsed['summary']?.toString() ?? 'Debate completed';
                debugPrint('RETURNING SCORE: $score from parseDebate()');
                return parsed;
              } else {
                debugPrint('SCORE OUT OF VALID RANGE: $score (must be 10-100)');
              }
            } else {
              debugPrint('Could not parse JSON from response text: $text');
            }
          } catch (parseError) {
            debugPrint('JSON PARSE ERROR: $parseError');
            debugPrint('   Stack: ${StackTrace.current}');
          }
        } else {
          debugPrint('Empty API response text');
        }
      }

      debugPrint('FALLING BACK TO HARDCODED SCORE: 65');
      return {
        'score': 65,
        'strengths': ['Good effort'],
        'weaknesses': ['Could not evaluate'],
        'summary': 'Debate completed',
      };
    } catch (e, stackTrace) {
      debugPrint('CRITICAL GROQ ERROR: $e');
      debugPrint('   Stack: $stackTrace');
      debugPrint('FALLING BACK (ERROR): score 65');
      return {
        'score': 65,
        'strengths': ['Good effort'],
        'weaknesses': ['Could not evaluate'],
        'summary': 'Debate completed',
      };
    }
  }

  static List<String> _normalizeStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).where((item) => item.isNotEmpty).toList();
    }
    if (value is String && value.isNotEmpty) {
      return [value];
    }
    return const <String>[];
  }
}
