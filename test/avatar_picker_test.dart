import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:clashchat/core/app_theme.dart';
import 'package:clashchat/core/theme_provider.dart';
import 'package:clashchat/screens/avatar_picker_screen.dart';
import 'package:clashchat/ui/ui.dart';
import 'package:clashchat/widgets/avatar_card.dart';

void main() {
  AppBackdrop.animationsEnabled = false;
  AvatarCard.imageOverride = (url, size) => SizedBox(width: size, height: size);

  testWidgets('Use this avatar pops with the selected seed', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? result;
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    result = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const AvatarPickerScreen(initialSeed: 'Felix'),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Use this avatar'), findsOneWidget);

    // Pick a different avatar by its label, then confirm.
    await tester.tap(find.text('Luna'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Use this avatar'));
    await tester.pumpAndSettle();

    expect(result, 'Luna');
    expect(find.text('Use this avatar'), findsNothing);
  });
}
