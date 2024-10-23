import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexicographical_order/lexicographical_order.dart';
import 'package:mojikit/mojikit.dart';
import 'package:flutter/foundation.dart';
import 'package:realm/realm.dart';
import 'package:file/memory.dart';
import 'package:signals/signals_flutter.dart';

void main() {
  const MethodChannel deviceInfoChannel = MethodChannel('dev.fluttercommunity.plus/device_info');

  setUpAll(() async {
    R.m = Realm(Configuration.local([Moji.schema], path: await U.newTestRealm()));
    R.p = Realm(Configuration.local([Preferences.schema], path: await U.newTestRealm()));
    R.online = false;
    TestWidgetsFlutterBinding.ensureInitialized();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(deviceInfoChannel,
        (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getDeviceInfo':
          switch (defaultTargetPlatform) {
            case TargetPlatform.iOS:
              return {
                'name': 'name',
                'model': 'model',
                'utsname': {'release': 'release', 'version': 'version', 'machine': 'machine', 'sysname': 'sysname', 'nodename': 'nodename'},
                'systemName': 'systemName',
                'isPhysicalDevice': true,
                'systemVersion': 'systemVersion',
                'localizedModel': 'localizedModel',
                'identifierForVendor': 'identifierForVendor'
              };
            case TargetPlatform.android:
              return {
                'id': 'id',
                'host': 'host',
                'tags': 'tags',
                'type': 'type',
                'model': 'model',
                'board': 'board',
                'brand': 'Google',
                'device': 'device',
                'product': 'product',
                'display': 'display',
                'hardware': 'hardware',
                'isPhysicalDevice': true,
                'bootloader': 'bootloader',
                'fingerprint': 'fingerprint',
                'manufacturer': 'manufacturer',
                'supportedAbis': ['arm64-v8a', 'x86', 'x86_64'],
                'systemFeatures': ['FEATURE_AUDIO_PRO', 'FEATURE_AUDIO_OUTPUT'],
                'version': {
                  'sdkInt': 16,
                  'baseOS': 'baseOS',
                  'previewSdkInt': 30,
                  'release': 'release',
                  'codename': 'codename',
                  'incremental': 'incremental',
                  'securityPatch': 'securityPatch'
                },
                'supported64BitAbis': ['x86-64', 'MMX', 'SSSE3'],
                'supported32BitAbis': ['x86 (IA-32)', 'MMX'],
                'serialNumber': 'SERIAL',
                'isLowRamDevice': false
              };
            case TargetPlatform.macOS:
              return {
                'arch': 'mock_arch',
                'model': 'mock_model',
                'activeCPUs': 4,
                'memorySize': 16,
                'cpuFrequency': 2,
                'hostName': 'mock_hostName',
                'osRelease': 'mock_osRelease',
                'majorVersion': 10,
                'minorVersion': 9,
                'patchVersion': 3,
                'computerName': 'mock_computerName',
                'kernelVersion': 'mock_kernelVersion',
                'systemGUID': 'mock_mac_id'
              };
            case TargetPlatform.windows:
              return {
                'computerName': 'computerName',
                'numberOfCores': 4,
                'systemMemoryInMegabytes': 16,
                'userName': 'userName',
                'majorVersion': 10,
                'minorVersion': 0,
                'buildNumber': 10240,
                'platformId': 1,
                'csdVersion': 'csdVersion',
                'servicePackMajor': 1,
                'servicePackMinor': 0,
                'suitMask': 1,
                'productType': 1,
                'reserved': 1,
                'buildLab': '22000.co_release.210604-1628',
                'buildLabEx': '22000.1.amd64fre.co_release.210604-1628',
                'digitalProductId': Uint8List.fromList([]),
                'displayVersion': '21H2',
                'editionId': 'Pro',
                'installDate': DateTime(2022, 04, 02).millisecondsSinceEpoch,
                'productId': '00000-00000-0000-AAAAA',
                'productName': 'Windows 10 Pro',
                'registeredOwner': 'registeredOwner',
                'releaseId': 'releaseId',
                'deviceId': 'deviceId'
              };
            case TargetPlatform.linux:
              final fs = MemoryFileSystem.test();
              final file = fs.file('/etc/machine-id')..createSync(recursive: true);
              file.writeAsStringSync('machine-id');

              final deviceInfo = DeviceInfoPlusLinuxPlugin(fileSystem: fs);
              final linuxInfo = await deviceInfo.linuxInfo();
              return linuxInfo;
            case TargetPlatform.fuchsia:
              return {
                'device': 'fuchsia_device',
                'model': 'fuchsia_model',
                'serialNumber': 'fuchsia_serial_number',
                'systemId': 'fuchsia_system_id',
              };
            default:
              return <String, dynamic>{};
          }
        default:
          return <String, dynamic>{};
      }
    });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(deviceInfoChannel, null);
  });

  group('Utility Functions Tests', () {
    test('getFlexibleMojiEventsForDay returns correct events', () {
      final day = DateTime.now();
      final mojiPlannerWidth = 300.0;

      // Mock the signals and realm to test functionality
      final (did, flexibleEvents) = U.getFlexibleMojiEventsForDay(day, mojiPlannerWidth);

      expect(did, isA<String>());
      expect(flexibleEvents, isA<Map<String, FlexibleMojiEvent>>());
    });

    test('getFlexibleMojiEventsForDay processes event IDs correctly', () async {
      final day = DateTime(2019, 1, 1);
      final mojiPlannerWidth = 300.0;
      final eid1 = U.fid();
      final eid2 = U.fid();
      final eid3 = U.fid();

      final yid = U.did(DateTime(day.year, day.month, day.day - 1));
      final did = U.did(day);
      final tid = U.did(DateTime(day.year, day.month, day.day + 1));

      final yidMojiR = untracked(() => S.mojiSignal(yid).value);
      final didMojiR = untracked(() => S.mojiSignal(did).value);
      final tidMojiR = untracked(() => S.mojiSignal(tid).value);

      final event1MojiR = untracked(() => S.mojiSignal(eid1).value);
      final event2MojiR = untracked(() => S.mojiSignal(eid2).value);
      final event3MojiR = untracked(() => S.mojiSignal(eid3).value);

      R.m.write(() {
        yidMojiR.l[eid1] = day;
        didMojiR.l[eid2] = day;
        tidMojiR.l[eid3] = day;
        event1MojiR.s = day;
        event1MojiR.e = day.add(Duration(hours: 1));
        event2MojiR.s = day;
        event3MojiR.s = day;
        event3MojiR.e = day.add(Duration(hours: 1));
      });

      final (_, flexibleEvents) = U.getFlexibleMojiEventsForDay(day, mojiPlannerWidth);
      expect(flexibleEvents.keys, containsAll([eid1, eid2, eid3]));
    });

    test('fid() generates a valid fid of correct length', () {
      final fid = U.fid();
      expect(fid.length, 20);
      expect(RegExp(r'^[A-Za-z0-9]+').hasMatch(fid), true);
    });

    test('did() formats DateTime correctly', () {
      final date = DateTime(2024, 10, 15);
      final formattedDate = U.did(date);
      expect(formattedDate, '15-10-2024');
    });

    test('roundToDay rounds DateTime to day', () {
      final date = DateTime(2024, 10, 15, 13, 45);
      final roundedDate = U.roundToDay(date);
      expect(roundedDate, DateTime(2024, 10, 15));
    });

    test('mojiHasExternalOrigin identifies external origin correctly', () {
      final eomid = U.fid();
      final weomid = U.fid();
      final mojiWithExternalOriginR = untracked(() => S.mojiSignal(eomid).value);
      final mojiWithoutExternalOriginR = untracked(() => S.mojiSignal(weomid).value);
      final calendars = untracked(() => S.mojiSignal(kMojiCalendars).value);
      final email = 'example@domain.com';
      final encodedEmail = base64.encode(utf8.encode(email));
      final orderKeys = generateOrderKeys(1);
      R.m.write(() {
        calendars.c[encodedEmail] = orderKeys.first;
        mojiWithExternalOriginR.p = encodedEmail;
        mojiWithoutExternalOriginR.p = 'internal';
      });

      expect(U.mojiHasExternalOrigin(mojiWithExternalOriginR), isTrue);
      expect(U.mojiHasExternalOrigin(mojiWithoutExternalOriginR), isFalse);
    });

    test('ultraLightBackground returns correct color based on darkness setting', () {
      final dye = Dyes.blue.value;

      expect(U.ultraLightBackground(dye), dye.ultraLight);
    });

    test('setAuthor sets correct author id for different platforms', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await U.setAuthor();
      expect(U.author, 'identifierForVendor');

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await U.setAuthor();
      expect(U.author, 'id');

      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      await U.setAuthor();
      expect(U.author, 'mock_mac_id');

      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      DeviceInfoPlusLinuxPlugin.registerWith();
      final fs = MemoryFileSystem.test();
      final file = fs.file('/etc/machine-id')..createSync(recursive: true);
      file.writeAsStringSync('machine-id');

      final deviceInfo = DeviceInfoPlusLinuxPlugin(fileSystem: fs);
      final linuxInfo = await deviceInfo.linuxInfo();
      await U.setAuthor(linuxInfo: linuxInfo);
      expect(U.author, 'machine-id');

      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      final windowsDeviceInfo = WindowsDeviceInfo(
        computerName: 'computerName',
        numberOfCores: 4,
        systemMemoryInMegabytes: 16,
        userName: 'userName',
        majorVersion: 10,
        minorVersion: 0,
        buildNumber: 10240,
        platformId: 1,
        csdVersion: 'csdVersion',
        servicePackMajor: 1,
        servicePackMinor: 0,
        suitMask: 1,
        productType: 1,
        reserved: 1,
        buildLab: '22000.co_release.210604-1628',
        buildLabEx: '22000.1.amd64fre.co_release.210604-1628',
        digitalProductId: Uint8List.fromList([]),
        displayVersion: '21H2',
        editionId: 'Pro',
        installDate: DateTime(2022, 04, 02),
        productId: '00000-00000-0000-AAAAA',
        productName: 'Windows 10 Pro',
        registeredOwner: 'registeredOwner',
        releaseId: 'releaseId',
        deviceId: 'windows_device',
      );
      await U.setAuthor(windowsInfo: windowsDeviceInfo);
      expect(U.author, 'windows_device');

      debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
      await U.setAuthor();
      expect(U.author, kFuchsiaDevice);

      debugDefaultTargetPlatformOverride = null;
    });

    test('daysSince1970 calculates correct days', () {
      final date = DateTime(2024, 10, 15);
      final days = U.daysSince1970(date);
      final expectedDays = date.toUtc().difference(U.zeroDateTime).inDays;
      expect(days, expectedDays);
    });

    test('roundTo5min rounds correctly', () {
      final value = 13.0;
      final roundedValue = value.roundTo5min();
      expect(roundedValue, 15);
    });

    test('calendarAutoRefreshingAuthClients initializes empty', () {
      expect(U.calendarAutoRefreshingAuthClients, isEmpty);
    });

    test('mojiDockTileASC initializes without clients', () {
      expect(U.mojiDockTileASC.hasClients, isFalse);
    });
  });
}
