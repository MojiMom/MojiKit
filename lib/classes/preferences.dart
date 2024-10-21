import 'package:realm/realm.dart';
part 'preferences.realm.dart';

@RealmModel()
class _Preferences {
  @PrimaryKey()
  late String id;
  bool? darkness;
  String? sub;
  String? authToken;
  String? loggedInEmail;
  String? projectId;
  String? serviceAccountData;
  String? selectedMojiDockTileName;
  int? mojiSyncInterval;
  double? mojiPlannerWidth;
  DateTime? lastSuccessfulSyncTime;
}
