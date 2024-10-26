import 'package:flutter/cupertino.dart';
import 'package:forui/forui.dart';
import 'package:mojikit/mojikit.dart';
import 'package:signals/signals.dart';

class S {
  static final preferencesSignal = readonlySignalContainer<Preferences, String>(
    (id) {
      // Start with an empty preferences
      Preferences preferences;
      // Attempt to find the preferences from realm
      final preferencesR = R.p.find<Preferences>(id);
      // If the preferences was found
      if (preferencesR != null) {
        // Use the preferences from realm
        preferences = preferencesR;
      } else {
        // Otherwise write a new preferences to realm and use the result
        preferences = R.p.write<Preferences>(() {
          // Add a new preferences to realm
          return R.p.add(Preferences(id), update: true);
          // Return the preferences
        });
        // If the preferences wasn't written
      }
      // Create a signal from the preferences
      final s = Signal<Preferences>(preferences);
      // Listen to the changes of the preferences
      preferences.changes.listen((changes) {
        // If the object wasn't deleted
        if (changes.isDeleted != true) {
          // Update the signal with the changes
          s.set(changes.object, force: true);
        }
      });
      return s;
    },
    cache: true,
  );

  static final mojiSignal = readonlySignalContainer<Moji, String>(
    (id) {
      if (id.isEmpty) {
        return Signal<Moji>(U.emptyMoji);
      }
      // Start with an empty moji
      Moji moji;
      // Attempt to find the moji from realm
      final mojiR = R.m.find<Moji>(id);
      // If the moji was found
      if (mojiR != null) {
        // Use the moji from realm
        moji = mojiR;
      } else {
        // Otherwise write a new moji to realm and use the result
        moji = R.m.write<Moji>(() {
          int? m;
          String? d, p;
          if (id.length == 1 && MojiDockTile.values.any((mdt) => mdt.name == id)) {
            final dMoji = MojiDockTile.fromString(id);
            m = dMoji.mcp;
            d = dMoji.name;
            p = '';
          }
          // Add a new moji to realm but set the write time so that it doesn't get synced
          return R.m.add(Moji(id, w: DateTime.fromMillisecondsSinceEpoch(1), m: m, d: d, p: p), update: true);
        });
      }

      // Create a signal from the moji
      final s = Signal<Moji>(moji);
      // Listen to the changes of the moji
      moji.changes.listen((changes) {
        // Update the signal with the changes
        s.set(changes.object, force: true);
      });
      return s;
    },
    cache: true,
  );

  static final mojiPlannerWidth = preferencesSignal(kLocalPreferences).select((p) => p().mojiPlannerWidth ?? kDefaultMojiPlannerWidth);

  static final darkness = preferencesSignal(kLocalPreferences).select((p) => p().darkness ?? false);

  static final recalculateMojiTilesAt = signal(0);

  static final initialMojiDockTile =
      MojiDockTile.fromString(untracked(() => preferencesSignal(kLocalPreferences).value.selectedMojiDockTileName));

  static final Signal<String?> implicitPID = signal(initialMojiDockTile.name);
  static final Signal<String?> selectedMID = signal(initialMojiDockTile.name);
  static final Signal<String?> selectedPID = signal(initialMojiDockTile.name);
  static final Signal<String?> pinnedMID = signal(kEmptyString);
  static final Signal<MojiDockTile?> implicitMojiDockTile = signal(initialMojiDockTile);
  static final Signal<MojiDockTile?> selectedMojiDockTile = signal(initialMojiDockTile);

  static final shouldShowIntervalPicker = signal(false);
  static final shouldShowMojiPicker = signal(false);
  static final selectedHeaderView = signal(MMHeaderView.plan);
  static final Signal<FCalendarController<DateTime?>?> fCalendarController = signal(null);

  static final currentMojiText = signal(kEmptyString);
  static final shouldTraverseFocus = signal(false);
  static final shouldAddChildMoji = signal(false);

  static final Signal<String> linkingCalendar = signal(kEmptyString);
  static final Signal<bool> flyingOverMojiPlanner = signal(false);
  static final Signal<double> softwareKeyboardHeight = signal(0.0);
  static final Signal<Moji> flyingMoji = signal(U.emptyMoji);
  static final Signal<Moji> flyingMojiEvent = signal(U.emptyMoji);
  static final Signal<Moji> flyingMojiDragTarget = signal(U.emptyMoji);
  static final Signal<double> additionalTopOffsetFromHandle = signal(0.0);

  // The current moji planner index
  static final currentMojiPlannerIndex = signal(() {
    final now = DateTime.now();
    return daysSinceStartOfYear(DateTime.utc(now.year, now.month, now.day));
  }());
  static final syncingMojis = signal(false);
  static final StreamSignal<DateTime> now = streamSignal(
    () => () async* {
      while (true) {
        await Future.delayed(const Duration(seconds: 1));
        // Get the current time
        final cDate = DateTime.now();
        final oDate = untracked(() => now.value.value);
        // If the current day has changed
        if (cDate.day != oDate?.day) {
          // Derive the current day
          final today = DateTime.utc(cDate.year, cDate.month, cDate.day);
          // Update the current moji planner index
          S.currentMojiPlannerIndex.set(daysSinceStartOfYear(today));
          // Update the moji planner scroll controller
          U.mojiPlannerScrollController.animateToItem(
            untracked(() => S.currentMojiPlannerIndex.value),
            duration: const Duration(milliseconds: 250),
            curve: Curves.ease,
          );
        }
        // If the current minute has changed
        if (cDate.minute != oDate?.minute) {
          // Create an async function in order to not delay the stream yield
          () async {
            // Get the existing syncing mojis status
            final syncingMojis = untracked(() => S.syncingMojis.value);
            // Update the now time and set the syncing mojis status to true
            S.syncingMojis.set(true);
            // If the mojis are not already syncing
            if (syncingMojis != true) {
              // Sync the unwritten mojis
              R.syncLocalUnwrittenMojis();
              // Get the calendar ids
              final calendarIds = untracked(() => S.mojiSignal(kMojiCalendars).value.c.keys);
              // For each calendar
              for (final calendarId in calendarIds) {
                // Get the modified calendar events
                R.getModifiedCalendarEvents(calendarId);
              }
            }
          }();
          yield cDate;
        }
      }
    }(),
  );
  static final lastInteractionAt = signal(DateTime.now());
}
