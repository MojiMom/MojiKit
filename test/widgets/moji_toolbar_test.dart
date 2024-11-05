import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:lexicographical_order/lexicographical_order.dart';
import 'package:mojikit/mojikit.dart';
import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:signals/signals.dart';

void main() {
  setUpAll(() async {
    R.m = Realm(Configuration.local([Moji.schema], path: await U.newTestRealm()));
    R.p = Realm(Configuration.local([Preferences.schema], path: await U.newTestRealm()));
    R.online = false;
  });

  group('MojiToolbar widget tests', () {
    testWidgets('MojiToolbar initializes correctly with mojiId', (WidgetTester tester) async {
      final mid = U.fid();
      final pid = U.fid();
      final pMojiR = untracked(() => S.mojiSignal(pid).value);
      final mojiR = untracked(() => S.mojiSignal(mid).value);
      final sTime = DateTime(2023, 1, 1).toUtc();
      R.m.write(() {
        pMojiR.m = 124;
        pMojiR.p = MojiDockTile.g.name;
        mojiR.m = 123;
        mojiR.p = pid;
        mojiR.s = sTime;
        mojiR.e = sTime.add(Duration(hours: 1));
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MojiToolbar(
              mojiId: mid,
            ),
          ),
        ),
      );

      // Verify that MojiToolbar widget is displayed
      expect(find.byType(MojiToolbar), findsOneWidget);
      expect(find.text(DateFormat('MMM d').format(sTime)), findsOneWidget);
    });

    testWidgets('MojiToolbar responds to tap actions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MojiToolbar(
              mojiId: 'testMojiId',
            ),
          ),
        ),
      );

      // Verify that MojiToolbar widget is displayed
      expect(find.byType(MojiToolbar), findsOneWidget);

      // Simulate tapping the first GestureDetector (e.g., shouldShowMojiPicker)
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      // Verify the state after the tap (you can add more detailed checks here if needed)
      expect(S.shouldShowMojiPicker.value, isTrue);
    });

    testWidgets('MojiToolbar displays HugeIcon correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MojiToolbar(
              mojiId: 'testMojiId',
            ),
          ),
        ),
      );

      // Verify that HugeIcon is displayed
      expect(find.byType(HugeIcon), findsWidgets);
    });

    testWidgets('MojiToolbar updates interval picker state to duraton on tap', (WidgetTester tester) async {
      final mid = U.fid();
      final mojiR = untracked(() => S.mojiSignal(mid).value);
      R.m.write(() {
        mojiR.s = DateTime(2023, 1, 1).toUtc();
        mojiR.e = mojiR.s?.add(Duration(minutes: 5));
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MojiToolbar(
              mojiId: mid,
            ),
          ),
        ),
      );

      // Simulate tapping
      await tester.tap(find.byKey(ValueKey(IntervalPickerState.duration)));
      await tester.pumpAndSettle();

      // Verify the state after the tap
      expect(S.intervalPickerState.value, IntervalPickerState.duration);

      // Toggle it
      await tester.tap(find.byKey(ValueKey(IntervalPickerState.duration)));

      // Verify the state after the tap
      expect(S.intervalPickerState.value, IntervalPickerState.none);
    });

    testWidgets('MojiToolbar updates interval picker state to start on tap', (WidgetTester tester) async {
      final mid = U.fid();
      final mojiR = untracked(() => S.mojiSignal(mid).value);
      R.m.write(() {
        mojiR.s = DateTime(2023, 1, 1).toUtc();
        mojiR.e = mojiR.s?.add(Duration(minutes: 5));
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MojiToolbar(
              mojiId: mid,
            ),
          ),
        ),
      );

      // Simulate tapping
      await tester.tap(find.byKey(ValueKey(IntervalPickerState.start)));
      await tester.pumpAndSettle();

      // Verify the state after the tap
      expect(S.intervalPickerState.value, IntervalPickerState.start);

      // Toggle it
      await tester.tap(find.byKey(ValueKey(IntervalPickerState.start)));

      // Verify the state after the tap
      expect(S.intervalPickerState.value, IntervalPickerState.none);
    });

    testWidgets('MojiToolbar updates interval picker state to end on tap', (WidgetTester tester) async {
      final mid = U.fid();
      final mojiR = untracked(() => S.mojiSignal(mid).value);
      R.m.write(() {
        mojiR.s = DateTime(2023, 1, 1).toUtc();
        mojiR.e = mojiR.s?.add(Duration(minutes: 5));
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MojiToolbar(
              mojiId: mid,
            ),
          ),
        ),
      );
      // Simulate tapping
      await tester.tap(find.byKey(ValueKey(IntervalPickerState.end)));
      await tester.pumpAndSettle();

      // Verify the state after the tap
      expect(S.intervalPickerState.value, IntervalPickerState.end);

      // Toggle it
      await tester.tap(find.byKey(ValueKey(IntervalPickerState.end)));

      expect(S.intervalPickerState.value, IntervalPickerState.none);
    });

    testWidgets('MojiToolbar shows calendar on tap', (WidgetTester tester) async {
      final mid = U.fid();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MojiToolbar(
              mojiId: mid,
            ),
          ),
        ),
      );

      // Simulate tapping the finish GestureDetector
      await tester.tap(find.byType(GestureDetector).at(2));
      await tester.pumpAndSettle();
    });

    testWidgets('MojiToolbar shows calendar on taps', (WidgetTester tester) async {
      final mid = U.fid();
      final day = DateTime.now().toUtc();
      S.fCalendarController.set(FCalendarController.date(initialSelection: day, selectable: (dateTime) => true));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MojiToolbar(
              mojiId: mid,
            ),
          ),
        ),
      );

      // Simulate tapping the finish GestureDetector
      await tester.tap(find.byType(GestureDetector).at(2));
      await tester.pumpAndSettle();
    });

    testWidgets('MojiToolbar handles delete action correctly', (WidgetTester tester) async {
      final cid = U.fid();
      final pid = U.fid();
      final pMojiR = untracked(() => S.mojiSignal(pid).value);
      final cMojiR = untracked(() => S.mojiSignal(cid).value);

      R.m.write(() {
        cMojiR.p = pid;
        pMojiR.c[cid] = generateOrderKeys(1).first;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MojiToolbar(
              mojiId: cid,
            ),
          ),
        ),
      );

      // Simulate tapping the delete GestureDetector
      await tester.tap(find.byType(GestureDetector).at(3));
      await tester.pumpAndSettle();

      // Verify that the moji was deleted (you can add more detailed checks here if needed)
      expect(S.selectedMID.value, equals(kEmptyString));
      expect(S.pinnedMID.value, equals(kEmptyString));
      expect(pMojiR.j.length, 1);
    });

    testWidgets('MojiToolbar handles finish action correctly', (WidgetTester tester) async {
      final mid = U.fid();
      final mojiR = untracked(() => S.mojiSignal(mid).value);
      R.m.write(() {
        mojiR.p = MojiDockTile.g.name;
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MojiToolbar(
              mojiId: mid,
            ),
          ),
        ),
      );

      // Simulate tapping the finish GestureDetector
      await tester.tap(find.byType(GestureDetector).last);
      await tester.pumpAndSettle();

      // Verify that the moji was finished (you can add more detailed checks here if needed)
      // This part assumes you have a way to verify that R.finishMoji was called, such as a mock or spy
    });
  });
}
