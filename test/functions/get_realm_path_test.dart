import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:mojikit/mojikit.dart';
import 'package:flutter/services.dart';

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
      final path = await getRealmPath();
      expect(path, isNotEmpty);
      expect(path, isA<String>());

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
