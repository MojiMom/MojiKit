import 'package:flutter_test/flutter_test.dart';
import 'package:mojikit/mojikit.dart';
import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:signals/signals_flutter_extended.dart';

void main() {
  setUpAll(() async {
    R.m = Realm(Configuration.local([Moji.schema], path: await U.newTestRealm()));
    R.p = Realm(Configuration.local([Preferences.schema], path: await U.newTestRealm()));
    R.online = false;
  });

  group('MojiPicker widget tests', () {
    testWidgets('MojiPicker initializes correctly with provided parameters', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MojiPicker(
              id: 'testMojiId',
              dye: Dyes.green.untrackedValue,
              shouldAddChildMoji: false,
            ),
          ),
        ),
      );

      // Verify that MojiPicker widget is displayed
      expect(find.byType(MojiPicker), findsOneWidget);
    });

    testWidgets('MojiPicker responds to icon press', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MojiPicker(
              id: 'testMojiId',
              dye: Dyes.green.untrackedValue,
              shouldAddChildMoji: false,
            ),
          ),
        ),
      );

      // Verify that MojiPicker widget is displayed
      expect(find.byType(MojiPicker), findsOneWidget);

      // Simulate typing in the search field
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pumpAndSettle();

      // Verify that search updates the filtered list (you can add more detailed checks here if needed)
      expect(find.byType(IconButton), findsWidgets);

      // Simulate tapping an icon
      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();

      // Verify the state or action after the tap (you can add more detailed checks here if needed)
      expect(S.shouldShowMojiPicker.value, isFalse);
    });

    testWidgets('MojiPicker adds child moji when shouldAddChildMoji is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MojiPicker(
              id: 'testMojiId',
              dye: Dyes.green.untrackedValue,
              shouldAddChildMoji: true,
            ),
          ),
        ),
      );

      // Verify that MojiPicker widget is displayed
      expect(find.byType(MojiPicker), findsOneWidget);

      // Simulate tapping an icon
      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();
    });
  });
}
