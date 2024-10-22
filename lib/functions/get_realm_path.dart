import 'dart:io';
import 'package:mojikit/mojikit.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_app_group_directory/flutter_app_group_directory.dart';

Future<String> getRealmPath({Directory? directory}) async {
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      final appGroupDirectory = await FlutterAppGroupDirectory.getAppGroupDirectory(kMojiAppGroup);
      return '${appGroupDirectory?.path}/Library/Application Support';
    case TargetPlatform.android:
      final path = (await getApplicationDocumentsDirectory()).path;
      final mojiMomPath = path.replaceAll(kMojiKitPackageName, kMojiMomPackageName);
      final dir = directory ?? Directory(mojiMomPath);
      if (dir.existsSync()) {
        try {
          dir.listSync();
          return mojiMomPath;
        } catch (e) {
          return path;
        }
      }
      return path;
    default:
      return (await getApplicationDocumentsDirectory()).path;
  }
}
