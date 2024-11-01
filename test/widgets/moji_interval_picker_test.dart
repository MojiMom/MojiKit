import 'package:duration_picker/duration_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mojikit/mojikit.dart';
import 'package:realm/realm.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

void main() {
  setUpAll(() async {
    R.m = Realm(Configuration.local([Moji.schema], path: await U.newTestRealm()));
    R.p = Realm(Configuration.local([Preferences.schema], path: await U.newTestRealm()));
    R.online = false;
  });

  group('MojiIntervalPicker widget tests', () {
    testWidgets('MojiIntervalPicker updates interval correctly on duration change', (WidgetTester tester) async {
      final mid = U.fid();
      final mojiR = untracked(() => S.mojiSignal(mid).value);
      final sTime = DateTime(2023, 1, 1).toUtc();
      final did = U.did(sTime);
      U.mojiPlannersNotifiers = {
        did: FlutterSignal((Map<String, FlexibleMojiEvent>.from({did: FlexibleMojiEvent(mojiR)}), 0))
      };
      R.m.write(() {
        mojiR.s = sTime;
        mojiR.e = sTime.add(Duration(minutes: 1));
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MojiIntervalPicker(
              mid: mid,
              mojiPlannerWidth: 100.0,
              dye: untracked(() => Dyes.green.value),
            ),
          ),
        ),
      );

      // Verify that MojiIntervalPicker widget is displayed
      expect(find.byType(MojiIntervalPicker), findsOneWidget);

      // Simulate changing the duration in DurationPicker
      await tester.fling(find.byType(DurationPicker), const Offset(0.0, 100.0), 1000.0);
      await tester.pumpAndSettle();

      U.mojiChanges.undo();
    });
  });
}
