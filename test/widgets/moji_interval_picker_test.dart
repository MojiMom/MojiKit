import 'package:duration_picker/duration_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mojikit/mojikit.dart';
import 'package:realm/realm.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:signals/signals_flutter_extended.dart';

void main() {
  setUpAll(() async {
    R.m = Realm(Configuration.local([Moji.schema], path: await U.newTestRealm()));
    R.p = Realm(Configuration.local([Preferences.schema], path: await U.newTestRealm()));
    R.online = false;
  });

  group('MojiIntervalPicker widget tests', () {
    testWidgets('updates interval correctly on duration change when handing a moji tile', (WidgetTester tester) async {
      final mid = U.fid();
      final mojiR = S.mojiSignal(mid).untrackedValue;
      final sTime = DateTime(2023, 1, 1).toUtc();
      final did = U.did(sTime);
      S.intervalPickerState.set(IntervalPickerState.duration);
      U.mojiPlannersNotifiers = {
        did: FlutterSignal((Map<String, FlexibleMojiEvent>.from({did: FlexibleMojiEvent(mojiR)}), 0))
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 500,
              width: 500,
              child: MojiIntervalPicker(
                key: ValueKey(MojiIntervalPicker),
                mid: mid,
                mojiPlannerWidth: 500,
                dye: Dyes.green.untrackedValue,
              ),
            ),
          ),
        ),
      );

      // Verify that MojiIntervalPicker widget is displayed
      expect(find.byType(MojiIntervalPicker), findsOneWidget);
      final Offset topRight = tester.getTopRight(find.byKey(ValueKey(MojiIntervalPicker)));
      final Offset firstLocation = Offset(topRight.dx - 200, topRight.dy + 100);
      await tester.fling(find.byType(DurationPicker), const Offset(-200, 50), 1000.0, initialOffset: firstLocation);
      await tester.pumpAndSettle();
      U.mojiChanges.undo();
    });

    testWidgets('updates interval correctly on duration change when handing a moji event', (WidgetTester tester) async {
      final mid = U.fid();
      final mojiR = S.mojiSignal(mid).untrackedValue;
      final sTime = DateTime(2023, 1, 1).toUtc();
      final did = U.did(sTime);
      S.intervalPickerState.set(IntervalPickerState.duration);
      U.mojiPlannersNotifiers = {
        did: FlutterSignal((Map<String, FlexibleMojiEvent>.from({did: FlexibleMojiEvent(mojiR)}), 0))
      };

      R.m.write(() {
        mojiR.s = sTime;
        mojiR.e = sTime.add(Duration(minutes: 15));
        mojiR.i = 15;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 500,
              width: 500,
              child: MojiIntervalPicker(
                key: ValueKey(MojiIntervalPicker),
                mid: mid,
                mojiPlannerWidth: 500,
                dye: Dyes.green.untrackedValue,
              ),
            ),
          ),
        ),
      );

      // Verify that MojiIntervalPicker widget is displayed
      expect(find.byType(MojiIntervalPicker), findsOneWidget);
      final Offset topRight = tester.getTopRight(find.byKey(ValueKey(MojiIntervalPicker)));
      final Offset firstLocation = Offset(topRight.dx - 200, topRight.dy + 100);
      await tester.fling(find.byType(DurationPicker), const Offset(-200, 50), 1000.0, initialOffset: firstLocation);
      await tester.pumpAndSettle();
      U.mojiChanges.undo();
    });

    testWidgets('updates start time correctly on duration change', (WidgetTester tester) async {
      final mid = U.fid();
      final mojiR = S.mojiSignal(mid).untrackedValue;
      final sTime = DateTime(2023, 1, 1, 1, 15);
      final did = U.did(sTime);
      S.intervalPickerState.set(IntervalPickerState.start);
      U.mojiPlannersNotifiers = {
        did: FlutterSignal((Map<String, FlexibleMojiEvent>.from({did: FlexibleMojiEvent(mojiR)}), 0))
      };
      R.m.write(() {
        mojiR.s = sTime;
        mojiR.e = sTime.add(Duration(minutes: 15));
        mojiR.i = 15;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: ValueKey(MojiIntervalPicker),
              height: 500,
              width: 500,
              child: MojiIntervalPicker(
                mid: mid,
                mojiPlannerWidth: 500.0,
                dye: Dyes.green.untrackedValue,
              ),
            ),
          ),
        ),
      );

      // Verify that MojiIntervalPicker widget is displayed
      expect(find.byType(MojiIntervalPicker), findsOneWidget);
      final Offset topRight = tester.getTopRight(find.byKey(ValueKey(MojiIntervalPicker)));
      final Offset firstLocation = Offset(topRight.dx - 200, topRight.dy + 100);
      await tester.fling(find.byType(DurationPicker), const Offset(-200, 50), 1000.0, initialOffset: firstLocation);
      await tester.pumpAndSettle();
      U.mojiChanges.undo();
    });

    testWidgets('updates end time correctly on duration change', (WidgetTester tester) async {
      final mid = U.fid();
      final mojiR = S.mojiSignal(mid).untrackedValue;
      final sTime = DateTime(2023, 1, 1, 1);
      final did = U.did(sTime);
      S.intervalPickerState.set(IntervalPickerState.end);
      U.mojiPlannersNotifiers = {
        did: FlutterSignal((Map<String, FlexibleMojiEvent>.from({did: FlexibleMojiEvent(mojiR)}), 0))
      };
      R.m.write(() {
        mojiR.s = sTime;
        mojiR.e = sTime.add(Duration(minutes: 15));
        mojiR.i = 15;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: ValueKey(MojiIntervalPicker),
              height: 500,
              width: 500,
              child: MojiIntervalPicker(
                mid: mid,
                mojiPlannerWidth: 500,
                dye: Dyes.green.untrackedValue,
              ),
            ),
          ),
        ),
      );

      // Verify that MojiIntervalPicker widget is displayed
      expect(find.byType(MojiIntervalPicker), findsOneWidget);
      final Offset bottomRight = tester.getBottomRight(find.byKey(ValueKey(MojiIntervalPicker)));
      final Offset firstLocation = Offset(bottomRight.dx - 200, bottomRight.dy - 200);
      await tester.fling(find.byType(DurationPicker), const Offset(-200, -100.0), 1000.0, initialOffset: firstLocation);
      await tester.pumpAndSettle();
      U.mojiChanges.undo();
    });

    testWidgets('removes event from planner when remove button is pressed', (WidgetTester tester) async {
      final mid = U.fid();
      final mojiR = S.mojiSignal(mid).untrackedValue;
      final sTime = DateTime(2023, 1, 1, 1);
      final did = U.did(sTime);
      S.intervalPickerState.set(IntervalPickerState.end);
      U.mojiPlannersNotifiers = {
        did: FlutterSignal((Map<String, FlexibleMojiEvent>.from({did: FlexibleMojiEvent(mojiR)}), 0))
      };
      R.m.write(() {
        mojiR.s = sTime;
        mojiR.e = sTime.add(Duration(minutes: 15));
        mojiR.i = 15;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: ValueKey(MojiIntervalPicker),
              height: 500,
              width: 500,
              child: MojiIntervalPicker(
                mid: mid,
                mojiPlannerWidth: 500,
                dye: Dyes.green.untrackedValue,
              ),
            ),
          ),
        ),
      );

      // Verify that MojiIntervalPicker widget is displayed
      expect(find.byType(MojiIntervalPicker), findsOneWidget);
      final Offset bottomRight = tester.getBottomRight(find.byKey(ValueKey(MojiIntervalPicker)));
      await tester.tapAt(Offset(bottomRight.dx - 10, bottomRight.dy - 10));
    });
  });
}
