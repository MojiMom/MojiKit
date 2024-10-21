import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mojikit/mojikit.dart';
import 'package:realm/realm.dart';
import 'package:signals/signals.dart';

void main() {
  setUpAll(() async {
    R.m = Realm(Configuration.local([Moji.schema], path: await U.newTestRealm()));
    R.p = Realm(Configuration.local([Preferences.schema], path: await U.newTestRealm()));
    R.online = false;
  });

  group('MojiCalendar Widget Tests', () {
    testWidgets('should render MojiCalendar correctly', (WidgetTester tester) async {
      final dye = untracked(() => Dyes.green.value);
      final relativeDay = DateTime.now();
      final mid = U.fid();
      final mojiR = untracked(() => S.mojiSignal(mid).value);
      final fCalendarController = FCalendarController.date();
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: MojiCalendar(
            dye: dye,
            fCalendarController: fCalendarController,
            relativeDay: relativeDay,
            mojiR: mojiR,
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(FCalendar), findsOneWidget);
    });

    testWidgets('should call R.changeMojiDay when a date is pressed', (WidgetTester tester) async {
      final dye = untracked(() => Dyes.green.value);
      final relativeDay = DateTime.now();
      final mid = U.fid();
      final mojiR = untracked(() => S.mojiSignal(mid).value);
      final fCalendarController = FCalendarController.date();
      // Arrange

      await tester.pumpWidget(
        MaterialApp(
          home: MojiCalendar(
            dye: dye,
            fCalendarController: fCalendarController,
            relativeDay: relativeDay,
            mojiR: mojiR,
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(FCalendar));
      await tester.pumpAndSettle();

      await tester.tap(find.text(relativeDay.day.toString()));
      await tester.pumpAndSettle();

      await tester.pumpAndSettle();
    });

    testWidgets('should render calendar style correctly', (WidgetTester tester) async {
      final dye = untracked(() => Dyes.green.value);
      final relativeDay = DateTime.now();
      final mid = U.fid();
      final mojiR = untracked(() => S.mojiSignal(mid).value);
      final fCalendarController = FCalendarController.date();
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(),
          home: MojiCalendar(
            dye: dye,
            fCalendarController: fCalendarController,
            relativeDay: relativeDay,
            mojiR: mojiR,
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      final dayPickerStyle = find.byWidgetPredicate(
        (widget) => widget is FCalendar && widget.style != null,
      );
      expect(dayPickerStyle, findsOneWidget);
    });
  });
}
