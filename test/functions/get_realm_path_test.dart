import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:mojikit/mojikit.dart';
import 'package:flutter/services.dart';
import 'package:mocktail/mocktail.dart';

class MockDirectory extends Mock implements Directory {}

void main() {
  const MethodChannel appGroupChannel = MethodChannel('flutter_app_group_directory');
  const MethodChannel pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(appGroupChannel,
        (MethodCall methodCall) async {
      if (methodCall.method == 'getAppGroupDirectory') {
        return '/mocked/app/group/directory';
      }
      return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(pathProviderChannel,
        (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        if (defaultTargetPlatform == TargetPlatform.android) {
          return '/data/user/0/$kMojiKitPackageName/flutter_app';
        }
        return '/mocked/application/documents/directory';
      }
      return null;
    });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(appGroupChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(pathProviderChannel, null);
  });

  group('getRealmPath tests', () {
    test('getRealmPath returns correct path for iOS and macOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final path = await getRealmPath();
      expect(path, contains('Library/Application Support'));

      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      final macPath = await getRealmPath();
      expect(macPath, contains('Library/Application Support'));

      debugDefaultTargetPlatformOverride = null; // Reset the platform override
    });

    test('getRealmPath returns correct path for other platforms', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      final mockDirectory = MockDirectory();
      when(() => mockDirectory.existsSync()).thenReturn(true);
      when(() => mockDirectory.listSync()).thenReturn([]);

      final androidPathMojiMom = await getRealmPath(directory: mockDirectory);
      expect(androidPathMojiMom, isNotEmpty);
      expect(androidPathMojiMom, contains(kMojiMomPackageName));

      final androidPath = await getRealmPath();
      expect(androidPath, isNotEmpty);
      expect(androidPath, contains(kMojiKitPackageName));

      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final linuxPath = await getRealmPath();
      expect(linuxPath, isNotEmpty);
      expect(linuxPath, isA<String>());

      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      final windowsPath = await getRealmPath();
      expect(windowsPath, isNotEmpty);
      expect(windowsPath, isA<String>());

      debugDefaultTargetPlatformOverride = null; // Reset the platform override
    });
  });
}
