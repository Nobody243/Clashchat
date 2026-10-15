import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:clashchat/core/app_theme.dart';
import 'package:clashchat/core/theme_provider.dart';
import 'package:clashchat/models/chat_message.dart';
import 'package:clashchat/models/debate_mode.dart';
import 'package:clashchat/screens/results_screen.dart';

void main() {
  Widget host(Widget child) => ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: MaterialApp(theme: AppTheme.dark(), home: child),
      );

  final messages = [
    ChatMessage(text: 'Opening challenge.', isUser: false, timestamp: DateTime(2026, 1, 1, 10)),
    ChatMessage(text: 'My first argument.', isUser: true, timestamp: DateTime(2026, 1, 1, 10, 1)),
    ChatMessage(text: 'A rebuttal.', isUser: false, timestamp: DateTime(2026, 1, 1, 10, 2)),
  ];

  testWidgets('ResultsScreen renders every section in reading order',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 2200 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(host(ResultsScreen(
      topic: 'Technology',
      stance: 'For',
      messages: messages,
      score: 72,
      mode: DebateMode.ranked,
      pointsEarned: 25,
      strengths: const ['Clear thesis'],
      weaknesses: const ['Needed evidence'],
      summary: 'Solid showing.',
      difficulty: 'Hard',
      durationMinutes: 4,
    )));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final overline = find.text('FINAL SCORE');
    final worked = find.text('What worked');
    final sharpen = find.text('What to sharpen');
    final again = find.text('Debate again');
    final home = find.text('Back to home');

    for (final f in [overline, worked, sharpen, again, home]) {
      expect(f, findsOneWidget);
    }

    // Reading order top → bottom, nothing collapsed to the same offset.
    final yOverline = tester.getTopLeft(overline).dy;
    final yWorked = tester.getTopLeft(worked).dy;
    final ySharpen = tester.getTopLeft(sharpen).dy;
    final yAgain = tester.getTopLeft(again).dy;
    final yHome = tester.getTopLeft(home).dy;
    expect(yWorked, greaterThan(yOverline + 200));
    expect(ySharpen, greaterThan(yWorked + 40));
    expect(yAgain, greaterThan(ySharpen + 40));
    expect(yHome, greaterThan(yAgain + 40));

    // Fully revealed after settling.
    final fades = tester.widgetList<FadeTransition>(find.byType(FadeTransition));
    for (final f in fades) {
      expect(f.opacity.value, closeTo(1.0, 0.001));
    }

    expect(find.text('+25 pts'), findsOneWidget);
    expect(find.text('Hard'), findsOneWidget);
  });
}
