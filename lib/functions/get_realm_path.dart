import 'package:mojikit/mojikit.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_app_group_directory/flutter_app_group_directory.dart';

Future<String> getRealmPath() async {
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      final appGroupDirectory = await FlutterAppGroupDirectory.getAppGroupDirectory(kMojiAppGroup);
      return '${appGroupDirectory?.path}/Library/Application Support';
    default:
      return (await getApplicationDocumentsDirectory()).path;
  }
}
