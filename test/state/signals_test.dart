import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lexicographical_order/lexicographical_order.dart';
import 'package:signals/signals.dart';
import 'package:mojikit/mojikit.dart';
import 'package:realm/realm.dart';

void main() {
  SignalsObserver.instance = null;
  setUpAll(() async {
    R.m = Realm(Configuration.local([Moji.schema], path: await U.newTestRealm()));
    R.p = Realm(Configuration.local([Preferences.schema], path: await U.newTestRealm()));
    R.online = false;
  });

  group('S class tests', () {
    test('preferencesSignal returns a signal with initial preferences', () async {
      final id = kLocalPreferences;
      final preferences = Preferences(id);

      R.p.write(() {
        R.p.add(preferences, update: true);
      });

      final signal = S.preferencesSignal(id);
      final stream = signal.toStream();

      await expectLater(stream, emitsInOrder([isA<Preferences>(), isA<Preferences>()]));
    });

    test('mojiSignal returns a signal with initial Moji', () async {
      final mid = U.fid();
      final signal = S.mojiSignal(mid);

      final stream = signal.toStream();

      await expectLater(stream, emitsInOrder([untracked(() => signal.value)]));
    });

    test('mojiSignal returns a empty moji when the id is empty', () async {
      final signal = S.mojiSignal(kEmptyString);
      final stream = signal.toStream();
      await expectLater(stream, emitsInOrder([U.emptyMoji]));
    });

    test('mojiSignal updates the moji code point and the dye when the id is a valid dock tile id', () async {
      final id = MojiDockTile.g.name;

      final signal = S.mojiSignal(id);
      final stream = signal.toStream();
      final moji = await stream.first;

      expect(moji.id, equals(id));
      expect(moji.m, equals(MojiDockTile.g.mcp));
      expect(moji.d, equals(MojiDockTile.g.name));
    });

    test('mojiSignal creates a new Moji if not found', () async {
      final id = kLocalPreferences;

      final signal = S.mojiSignal(id);
      final stream = signal.toStream();

      await expectLater(stream, emitsInOrder([isA<Moji>()]));
    });

    test('mojiPlannerWidth returns correct value from preferences', () async {
      final preferences = untracked(() => S.preferencesSignal(kLocalPreferences).value);

      expect(preferences.mojiPlannerWidth, isNot(350.0));

      R.p.write(() {
        preferences.mojiPlannerWidth = 350.0;
      });

      final signal = S.mojiPlannerWidth;
      final stream = signal.toStream();

      await expectLater(stream, emitsInOrder([350.0]));
    });

    test('darkness returns correct value from preferences', () async {
      final preferences = untracked(() => S.preferencesSignal(kLocalPreferences).value);

      expect(preferences.darkness, isNot(true));

      R.p.write(() {
        preferences.darkness = true;
      });

      final signal = S.darkness;
      final stream = signal.toStream();

      await expectLater(stream, emitsInOrder([true]));
    });

    test('initialMojiDockTile returns correct value from preferences', () {
      final id = kLocalPreferences;
      final preferences = Preferences(id)..selectedMojiDockTileName = MojiDockTile.g.name;

      R.p.write(() {
        R.p.add(preferences, update: true);
      });

      final dockTile = S.initialMojiDockTile;

      expect(dockTile, isA<MojiDockTile>());
    });

    test('now stream signal updates every second', () async {
      final calendars = untracked(() => S.mojiSignal(kMojiCalendars).value);
      final order = generateOrderKeys(1);
      final calendarId = base64Encode(utf8.encode('test@example.com'));
      R.m.write(() {
        calendars.c[calendarId] = order.first;
      });
      final nowStream = S.now.toStream();
      final nowValues = <DateTime?>[];

      final subscription = nowStream.listen((value) {
        nowValues.add(value.value);
      });

      await Future.delayed(Duration(seconds: 3));
      await subscription.cancel();

      expect(nowValues.length, greaterThanOrEqualTo(2));
    });
    test('selectedMID returns correct initial value', () {
      final selectedMID = S.selectedMID.value;

      expect(selectedMID, equals(S.initialMojiDockTile.name));
    });

    test('selectedPID returns correct initial value', () {
      final selectedPID = S.selectedPID.value;

      expect(selectedPID, equals(S.initialMojiDockTile.name));
    });

    test('pinnedMID returns correct initial value', () {
      final pinnedMID = S.pinnedMID.value;

      expect(pinnedMID, equals(kEmptyString));
    });

    test('implicitMojiDockTile returns correct initial value', () {
      final implicitMojiDockTile = S.implicitMojiDockTile.value;

      expect(implicitMojiDockTile, equals(S.initialMojiDockTile));
    });

    test('selectedMojiDockTile returns correct initial value', () {
      final selectedMojiDockTile = S.selectedMojiDockTile.value;

      expect(selectedMojiDockTile, equals(S.initialMojiDockTile));
    });

    test('intervalPickerState returns correct initial value', () {
      final intervalPickerState = S.intervalPickerState.value;

      expect(intervalPickerState, IntervalPickerState.none);
    });

    test('shouldShowMojiPicker returns correct initial value', () {
      final shouldShowMojiPicker = S.shouldShowMojiPicker.value;

      expect(shouldShowMojiPicker, isFalse);
    });

    test('selectedHeaderView returns correct initial value', () {
      final selectedHeaderView = S.selectedHeaderView.value;

      expect(selectedHeaderView, equals(MMHeaderView.plan));
    });

    test('fCalendarController returns correct initial value', () {
      final fCalendarController = S.fCalendarController.value;

      expect(fCalendarController, isNull);
    });

    test('currentMojiText returns correct initial value', () {
      final currentMojiText = S.currentMojiText.value;

      expect(currentMojiText, equals(kEmptyString));
    });

    test('shouldTraverseFocus returns correct initial value', () {
      final shouldTraverseFocus = S.shouldTraverseFocus.value;

      expect(shouldTraverseFocus, isFalse);
    });

    test('shouldAddChildMoji returns correct initial value', () {
      final shouldAddChildMoji = S.shouldAddChildMoji.value;

      expect(shouldAddChildMoji, isFalse);
    });

    test('flyingOverMojiPlanner returns correct initial value', () {
      final flyingOverMojiPlanner = S.flyingOverMojiPlanner.value;

      expect(flyingOverMojiPlanner, isFalse);
    });

    test('softwareKeyboardHeight returns correct initial value', () {
      final softwareKeyboardHeight = S.softwareKeyboardHeight.value;

      expect(softwareKeyboardHeight, equals(0.0));
    });

    test('flyingMoji returns correct initial value', () {
      final flyingMoji = S.flyingMoji.value;

      expect(flyingMoji, equals(U.emptyMoji));
    });

    test('flyingMojiEvent returns correct initial value', () {
      final flyingMojiEvent = S.flyingMojiEvent.value;

      expect(flyingMojiEvent, equals(U.emptyMoji));
    });

    test('flyingMojiDragTarget returns correct initial value', () {
      final flyingMojiDragTarget = S.flyingMojiDragTarget.value;

      expect(flyingMojiDragTarget, equals(U.emptyMoji));
    });

    test('additionalTopOffsetFromHandle returns correct initial value', () {
      final additionalTopOffsetFromHandle = S.additionalTopOffsetFromHandle.value;

      expect(additionalTopOffsetFromHandle, equals(0.0));
    });

    test('lastInteractionAt returns correct initial value', () {
      final lastInteractionAt = S.lastInteractionAt.value;

      expect(lastInteractionAt.difference(DateTime.now()).inSeconds.abs(), lessThan(1));
    });

    test('linkingCalendar returns correct initial value', () {
      final linkingCalendar = S.linkingCalendar.value;

      expect(linkingCalendar, equals(kEmptyString));
    });

    test('shouldShowPerformanceOverlay returns correct initial value', () {
      final shouldShowPerformanceOverlay = S.shouldShowPerformanceOverlay.value;

      expect(shouldShowPerformanceOverlay, isFalse);
    });

    test('eventDragHandleMID returns correct initial value', () {
      final eventDragHandleMID = S.eventDragHandleMID.value;

      expect(eventDragHandleMID, equals(kEmptyString));
    });
  });
}
