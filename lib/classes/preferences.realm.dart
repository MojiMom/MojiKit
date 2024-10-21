// coverage:ignore-file

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preferences.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// ignore_for_file: type=lint
class Preferences extends _Preferences
    with RealmEntity, RealmObjectBase, RealmObject {
  Preferences(
    String id, {
    bool? darkness,
    String? sub,
    String? authToken,
    String? loggedInEmail,
    String? projectId,
    String? serviceAccountData,
    String? selectedMojiDockTileName,
    int? mojiSyncInterval,
    double? mojiPlannerWidth,
    DateTime? lastSuccessfulSyncTime,
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'darkness', darkness);
    RealmObjectBase.set(this, 'sub', sub);
    RealmObjectBase.set(this, 'authToken', authToken);
    RealmObjectBase.set(this, 'loggedInEmail', loggedInEmail);
    RealmObjectBase.set(this, 'projectId', projectId);
    RealmObjectBase.set(this, 'serviceAccountData', serviceAccountData);
    RealmObjectBase.set(
        this, 'selectedMojiDockTileName', selectedMojiDockTileName);
    RealmObjectBase.set(this, 'mojiSyncInterval', mojiSyncInterval);
    RealmObjectBase.set(this, 'mojiPlannerWidth', mojiPlannerWidth);
    RealmObjectBase.set(this, 'lastSuccessfulSyncTime', lastSuccessfulSyncTime);
  }

  Preferences._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  bool? get darkness => RealmObjectBase.get<bool>(this, 'darkness') as bool?;
  @override
  set darkness(bool? value) => RealmObjectBase.set(this, 'darkness', value);

  @override
  String? get sub => RealmObjectBase.get<String>(this, 'sub') as String?;
  @override
  set sub(String? value) => RealmObjectBase.set(this, 'sub', value);

  @override
  String? get authToken =>
      RealmObjectBase.get<String>(this, 'authToken') as String?;
  @override
  set authToken(String? value) => RealmObjectBase.set(this, 'authToken', value);

  @override
  String? get loggedInEmail =>
      RealmObjectBase.get<String>(this, 'loggedInEmail') as String?;
  @override
  set loggedInEmail(String? value) =>
      RealmObjectBase.set(this, 'loggedInEmail', value);

  @override
  String? get projectId =>
      RealmObjectBase.get<String>(this, 'projectId') as String?;
  @override
  set projectId(String? value) => RealmObjectBase.set(this, 'projectId', value);

  @override
  String? get serviceAccountData =>
      RealmObjectBase.get<String>(this, 'serviceAccountData') as String?;
  @override
  set serviceAccountData(String? value) =>
      RealmObjectBase.set(this, 'serviceAccountData', value);

  @override
  String? get selectedMojiDockTileName =>
      RealmObjectBase.get<String>(this, 'selectedMojiDockTileName') as String?;
  @override
  set selectedMojiDockTileName(String? value) =>
      RealmObjectBase.set(this, 'selectedMojiDockTileName', value);

  @override
  int? get mojiSyncInterval =>
      RealmObjectBase.get<int>(this, 'mojiSyncInterval') as int?;
  @override
  set mojiSyncInterval(int? value) =>
      RealmObjectBase.set(this, 'mojiSyncInterval', value);

  @override
  double? get mojiPlannerWidth =>
      RealmObjectBase.get<double>(this, 'mojiPlannerWidth') as double?;
  @override
  set mojiPlannerWidth(double? value) =>
      RealmObjectBase.set(this, 'mojiPlannerWidth', value);

  @override
  DateTime? get lastSuccessfulSyncTime =>
      RealmObjectBase.get<DateTime>(this, 'lastSuccessfulSyncTime')
          as DateTime?;
  @override
  set lastSuccessfulSyncTime(DateTime? value) =>
      RealmObjectBase.set(this, 'lastSuccessfulSyncTime', value);

  @override
  Stream<RealmObjectChanges<Preferences>> get changes =>
      RealmObjectBase.getChanges<Preferences>(this);

  @override
  Stream<RealmObjectChanges<Preferences>> changesFor(
          [List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<Preferences>(this, keyPaths);

  @override
  Preferences freeze() => RealmObjectBase.freezeObject<Preferences>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'darkness': darkness.toEJson(),
      'sub': sub.toEJson(),
      'authToken': authToken.toEJson(),
      'loggedInEmail': loggedInEmail.toEJson(),
      'projectId': projectId.toEJson(),
      'serviceAccountData': serviceAccountData.toEJson(),
      'selectedMojiDockTileName': selectedMojiDockTileName.toEJson(),
      'mojiSyncInterval': mojiSyncInterval.toEJson(),
      'mojiPlannerWidth': mojiPlannerWidth.toEJson(),
      'lastSuccessfulSyncTime': lastSuccessfulSyncTime.toEJson(),
    };
  }

  static EJsonValue _toEJson(Preferences value) => value.toEJson();
  static Preferences _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
      } =>
        Preferences(
          fromEJson(id),
          darkness: fromEJson(ejson['darkness']),
          sub: fromEJson(ejson['sub']),
          authToken: fromEJson(ejson['authToken']),
          loggedInEmail: fromEJson(ejson['loggedInEmail']),
          projectId: fromEJson(ejson['projectId']),
          serviceAccountData: fromEJson(ejson['serviceAccountData']),
          selectedMojiDockTileName:
              fromEJson(ejson['selectedMojiDockTileName']),
          mojiSyncInterval: fromEJson(ejson['mojiSyncInterval']),
          mojiPlannerWidth: fromEJson(ejson['mojiPlannerWidth']),
          lastSuccessfulSyncTime: fromEJson(ejson['lastSuccessfulSyncTime']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(Preferences._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
        ObjectType.realmObject, Preferences, 'Preferences', [
      SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
      SchemaProperty('darkness', RealmPropertyType.bool, optional: true),
      SchemaProperty('sub', RealmPropertyType.string, optional: true),
      SchemaProperty('authToken', RealmPropertyType.string, optional: true),
      SchemaProperty('loggedInEmail', RealmPropertyType.string, optional: true),
      SchemaProperty('projectId', RealmPropertyType.string, optional: true),
      SchemaProperty('serviceAccountData', RealmPropertyType.string,
          optional: true),
      SchemaProperty('selectedMojiDockTileName', RealmPropertyType.string,
          optional: true),
      SchemaProperty('mojiSyncInterval', RealmPropertyType.int, optional: true),
      SchemaProperty('mojiPlannerWidth', RealmPropertyType.double,
          optional: true),
      SchemaProperty('lastSuccessfulSyncTime', RealmPropertyType.timestamp,
          optional: true),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
