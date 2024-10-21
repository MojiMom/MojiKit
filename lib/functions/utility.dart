import 'dart:io';
import 'dart:math';
import 'package:dart_firebase_admin/dart_firebase_admin.dart';
import 'package:dart_firebase_admin/firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:intl/intl.dart';
import 'package:mojikit/mojikit.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:undo/undo.dart';
import 'package:infinite_carousel/infinite_carousel.dart';
import 'package:signals/signals.dart';
import 'package:flutter/material.dart';

extension RoundTo5Min on double {
  int roundTo5min() {
    return (this / 5).round() * 5;
  }
}

class U {
  static Map<String, FlexibleMojiEvent> getFlexibleMojiEventsForDay(DateTime day, double mojiPlannerWidth) {
    // Since the moji planners are based on the local time use the local time here
    day = day.toLocal();
    final yid = U.did(DateTime(day.year, day.month, day.day - 1));
    final did = U.did(day);
    final tid = U.did(DateTime(day.year, day.month, day.day + 1));
    final mojiPlannerY = untracked(() => S.mojiSignal(yid).value);
    final mojiPlannerD = untracked(() => S.mojiSignal(did).value);
    final mojiPlannerT = untracked(() => S.mojiSignal(tid).value);
    final mojiEventIds = <String>[];
    for (final entries in [mojiPlannerY.l.entries, mojiPlannerD.l.entries, mojiPlannerT.l.entries]) {
      for (final entry in entries) {
        if (U.did(entry.value.toLocal()) == did) {
          mojiEventIds.add(entry.key);
        }
      }
    }
    // Get the mojis belonging to the moji planner from realm
    final dayMojisR = R.getAllMojis(mojiEventIds);
    // Calculate the flexibility of the moji events
    final fMojiEvents = calculateFlexibility(dayMojisR, mojiPlannerWidth);
    // Return a map of the flexible moji events
    return fMojiEvents.fold<Map<String, FlexibleMojiEvent>>({}, (map, event) {
      map[event.moji.id] = event;
      return map;
    });
  }

  static String fid() {
    const int fidLength = 20;
    final int maxMultiple = (256 / _chars.length).floor() * _chars.length;

    Uint8List bytes = Uint8List(fidLength * 2);
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = _random.nextInt(256);
    }

    StringBuffer fidBuffer = StringBuffer();
    for (int i = 0; i < bytes.length && fidBuffer.length < fidLength; i++) {
      if (bytes[i] < maxMultiple) {
        fidBuffer.write(_chars[bytes[i] % _chars.length]);
      }
    }

    assert(fidBuffer.length == fidLength, 'Invalid fid: ${fidBuffer.toString()}');
    return fidBuffer.toString();
  }

  static String did(DateTime day) {
    return DateFormat('dd-MM-yyyy').format(day);
  }

  static int daysSince1970(DateTime time) {
    final rDay = roundToDay(time);
    final rDays = rDay.difference(U.zeroDateTime).inDays;
    return rDays;
  }

  static DateTime roundToDay(DateTime time) {
    return DateTime(time.year, time.month, time.day);
  }

  static bool mojiHasExternalOrigin(Moji moji) {
    return untracked(() => S.mojiSignal(kMojiCalendars).value.c.containsKey(moji.p));
  }

  static Color ultraLightBackground(Dye dye) {
    return untracked(() => S.darkness.value) == true ? Colors.white : dye.ultraLight;
  }

  static final zeroDateTime = DateTime.fromMillisecondsSinceEpoch(0).toUtc();

  static final mojiChanges = ChangeStack();

  static final mojiPlannerScrollController = InfiniteScrollController(initialItem: untracked(() => S.currentMojiPlannerIndex.value));

  static String? author;

  static Future<void> setAuthor({LinuxDeviceInfo? linuxInfo, WindowsDeviceInfo? windowsInfo}) async {
    final deviceInfo = DeviceInfoPlugin();
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        U.author = (await deviceInfo.iosInfo).identifierForVendor;
        break;
      case TargetPlatform.android:
        U.author = (await deviceInfo.androidInfo).id;
        break;
      case TargetPlatform.macOS:
        U.author = (await deviceInfo.macOsInfo).systemGUID;
        break;
      case TargetPlatform.windows:
        U.author = windowsInfo?.deviceId ?? (await deviceInfo.windowsInfo).deviceId;
        break;
      case TargetPlatform.linux:
        U.author = linuxInfo?.machineId ?? (await deviceInfo.linuxInfo).machineId;
        break;
      case TargetPlatform.fuchsia:
        U.author = kFuchsiaDevice;
        break;
    }
  }

  static (Node?, TreeController<Node>?)? activeTreeController;
  static final Map<String, AutoRefreshingAuthClient> calendarAutoRefreshingAuthClients = {};
  static Map<String, ValueNotifier<(Map<String, FlexibleMojiEvent>, int)>> mojiPlannersNotifiers = {};

  static final mojiDockTileASC = AutoScrollController();
  static final emptyMoji = Moji(kEmptyString);
  static Future<String> newTestRealm() async {
    return '${(await Directory.systemTemp.createTemp()).path}/$kTestRealmFileName';
  }

  static Firestore createFirestoreEmulator([Settings? settings]) {
    final credential = Credential.fromApplicationDefaultCredentials();
    final app = FirebaseAdminApp.initializeApp('dart-firebase-admin', credential)..useEmulator();
    final firestore = Firestore(app, settings: settings);
    return firestore;
  }
}

const String _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
final Random _random = Random.secure();
