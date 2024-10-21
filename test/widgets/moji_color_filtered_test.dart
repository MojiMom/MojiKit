import 'package:flutter_test/flutter_test.dart';
import 'package:mojikit/mojikit.dart';
import 'package:realm/realm.dart';
import 'package:flutter/material.dart';

void main() {
  setUpAll(() async {
    R.m = Realm(Configuration.local([Moji.schema], path: await U.newTestRealm()));
    R.p = Realm(Configuration.local([Preferences.schema], path: await U.newTestRealm()));
    R.online = false;
  });

  group('MojiColorFiltered widget tests', () {
    testWidgets('MojiColorFiltered applies correct color filter based on darkness', (WidgetTester tester) async {
      // Test with darkness = true
      await tester.pumpWidget(
        MaterialApp(
          home: MojiColorFiltered(
            darkness: true,
            child: Container(key: Key('darkContainer')),
          ),
        ),
      );

      // Verify that the ColorFiltered widget is applied
      final colorFilteredFinder = find.byType(ColorFiltered);
      expect(colorFilteredFinder, findsOneWidget);
      final colorFilteredWidget = tester.widget<ColorFiltered>(colorFilteredFinder);
      expect(colorFilteredWidget.colorFilter, darkFilter);

      // Test with darkness = false
      await tester.pumpWidget(
        MaterialApp(
          home: MojiColorFiltered(
            darkness: false,
            child: Container(key: Key('brightContainer')),
          ),
        ),
      );

      // Verify that the ColorFiltered widget is applied with bright filter
      final brightColorFilteredWidget = tester.widget<ColorFiltered>(colorFilteredFinder);
      expect(brightColorFilteredWidget.colorFilter, brightFilter);
    });
  });
}
