import 'dart:convert';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mojikit/mojikit.dart';
import 'package:realm/realm.dart';
import 'package:lexicographical_order/lexicographical_order.dart';
import 'package:signals/signals_flutter.dart';
import 'package:signals/signals_flutter_extended.dart';

void main() {
  setUpAll(() async {
    R.m = Realm(Configuration.local([Moji.schema], path: await U.newTestRealm()));
    R.p = Realm(Configuration.local([Preferences.schema], path: await U.newTestRealm()));
    R.online = false;
    return Future.value();
  });
  group('realm', () {
    test('getModifiedCalendarEvents returns an empty set if not set', () async {
      final result = await R.getModifiedCalendarEvents('test@example.com');
      expect(result, isEmpty);
    });
    test('syncServerWrittenMojis when offline', () async {
      final result = await R.syncServerWrittenMojis();
      expect(result, false);
    });

    test('syncServerWrittenMojis when online', () async {
      final fid = 'test_moji_id';
      final firestore = U.createFirestoreEmulator();
      final day = DateTime(2023, 1, 1).toUtc();
      final mojiR = S.mojiSignal(fid).untrackedValue;
      final did = U.did(day);
      U.mojiPlannersNotifiers = {
        did: FlutterSignal((Map<String, FlexibleMojiEvent>.from({did: FlexibleMojiEvent(mojiR)}), 0))
      };
      R.m.write(() {
        mojiR.w = day;
        mojiR.a = 'author';
        mojiR.s = day;
      });
      await firestore.collection('m').doc(fid).set(mojiR.toJson());
      R.online = true;
      final result = await R.syncServerWrittenMojis();
      R.online = false;
      expect(result, true);
    });

    test('syncLocalUnwrittenMojis when online', () async {
      final firestore = U.createFirestoreEmulator();
      final mid = U.fid();
      final mojiR = S.mojiSignal(mid).untrackedValue;
      R.m.write(() {
        mojiR.w = null;
        mojiR.t = 'test';
      });
      R.online = true;
      await R.syncLocalUnwrittenMojis();
      R.online = false;
      final moji = await firestore.collection('m').doc(mid).get();
      expect(moji.exists, isTrue);
      expect(moji.id, equals(mid));
      expect(moji.data()?['w'], isNotNull);
      expect(mojiR.w, isNot(U.zeroDateTime));
      expect(mojiR.w, isNot(null));
    });

    test('syncLocalUnwrittenMojis should zero out the write time of failed writes', () async {
      final mid = U.fid();
      final mojiR = S.mojiSignal(mid).untrackedValue;
      R.m.write(() {
        mojiR.w = null;
        mojiR.t = 'test';
      });
      R.online = true;
      try {
        await R.syncLocalUnwrittenMojis(closeFirestore: true);
      } catch (e) {
        expect(e, isNot(null));
      }
      expect(mojiR.id, mid);
      expect(mojiR.w, U.zeroDateTime);
    });

    test('syncLocalUnwrittenMojis when direcrly provided with moji ids', () async {
      final firestore = U.createFirestoreEmulator();
      final mid = U.fid();
      final mojiR = S.mojiSignal(mid).untrackedValue;
      R.m.write(() {
        mojiR.t = 'test';
      });
      R.online = true;
      await R.syncLocalUnwrittenMojis(mojiIDs: {mid});
      R.online = false;
      final moji = await firestore.collection('m').doc(mid).get();
      expect(moji.exists, isTrue);
      expect(moji.id, equals(mid));
      expect(moji.data()?['w'], isNotNull);
      expect(mojiR.w, isNot(U.zeroDateTime));
      expect(mojiR.w, isNot(null));
    });

    test('updateDarkness', () async {
      R.updateDarkness(true);

      final preferences = S.preferencesSignal(kLocalPreferences).untrackedValue;

      expect(preferences.darkness, true);
    });

    test('updateMojiPlannerWidth', () async {
      R.updateMojiPlannerWidth(200.0);

      final preferences = S.preferencesSignal(kLocalPreferences).untrackedValue;

      expect(preferences.mojiPlannerWidth, 200.0);
    });

    test('clear', () async {
      final mojiId = U.fid();
      final preferencesId = kLocalPreferences;
      S.mojiSignal(mojiId).untrackedValue;
      S.preferencesSignal(preferencesId).untrackedValue;

      final allMojis = R.m.all<Moji>();
      final allPreferences = R.p.all<Preferences>();

      expect(allMojis.isEmpty, false);
      expect(allPreferences.isEmpty, false);

      R.clear();

      expect(allMojis.isEmpty, true);
      expect(allPreferences.isEmpty, true);
    });

    test('addMojiCalendar when it doesnt exist', () async {
      final email = 'test@example.com';
      final refreshToken = 'refreshToken123';
      final calendarsR = S.mojiSignal(kMojiCalendars).untrackedValue;

      R.addMojiCalendar(email, refreshToken);

      final encodedEmail = base64Encode(utf8.encode(email));
      final mojiCalendar = S.mojiSignal(encodedEmail).untrackedValue;
      expect(calendarsR.c.length, 1);
      expect(calendarsR.c.keys.first, mojiCalendar.id);
      expect(mojiCalendar.x, {kGoogleCalendarTokenKey: refreshToken});
    });

    test('addMojiCalendar when it doesnt exist', () async {
      final email = 'test@example.com';
      final refreshToken = 'refreshToken123';
      final encodedEmail = base64Encode(utf8.encode(email));
      final calendarR = S.mojiSignal(encodedEmail).untrackedValue;

      R.m.write(() {
        calendarR.x[kGoogleCalendarTokenKey] = refreshToken;
      });

      R.addMojiCalendar(email, refreshToken);

      final mojiCalendarsR = S.mojiSignal(kMojiCalendars).untrackedValue;
      expect(mojiCalendarsR.c.length, 1);
      expect(mojiCalendarsR.c.keys.first, calendarR.id);
      expect(calendarR.x, {kGoogleCalendarTokenKey: refreshToken});
      expect(calendarR.w, U.zeroDateTime);
    });

    test('getFirestore', () async {
      final serviceAccountData = base64Encode(utf8.encode('''{
        "type": "service_account",
        "project_id": "test-project",
        "private_key_id": "some_key_id",
        "private_key": "-----BEGIN PRIVATE KEY-----\\nMIICXQIBAAKBgQCf4TCKxYQW5LVWkpx1vMdiCpXkrF+TNnQFlxLqapnEPoM5Xs+qBgMdAn4RCBO4IHFLaL9npaYv4PZ9U7qZDQKaKLZI5FiQodGd7co1VJdfl+7+Uy70FnOQMeaAFZ/FSvFsJgKZ0zNj7zhRLdZAhB+LCZ++EJvGnOpuA0j4BdJB1QIDAQABAoGAYqFbfuCmwjDJpeTAXOne3p7FJdMpCvo2zRQL+U1WGvitn4Db/3nCBe15tCwVbiuleO3f1qMcSMExjtNOdAjQpym47y+sELIO51FZljP2hfd2T0klrlnBKQ5KKod4Zh+PpPd2OEp/zKTGAiIbyF5aaCw6ikZ/w6iBbReTYpN8NukCQQDnrvBeeu4NNqGmx0jKfi1VVNjZqe+DmZqLMtULbp6fkmVhQdLj4L9vnm9vQdhkJA4/u0fMoXTH75EwxuBEp55fAkEAsKj4C7cCCjedtveHgo8PMas2aOLFiVgMbJ4b6kXvXdgw4a61EwJO9oxzzwfVt5bYKsQ3cjnab3JmO0X2u/6kSwJBALkhANF+SVolnWY3N+MWkALvmZfUQp9VzjgMllBcREQeJwRgJLQSkuYOI90zMEZUyU4DyIurODXLKKlhQTOa/OECQG6/bskBUKERHqk+YlBh2PedSv3T9FxWu2s4b22drCLbzkEdIl0pXFFJ2awXUE7InPmqisvsItktEZPlF3nheCMCQQDTILLV5bXTOSuOzGUdvcO0Qm/80Pkz2w0vaoJNiO2Wl2SdXJsk08l+4HvVdULAj30XZYV9LboRVhIL57lSUEFz\\n-----END PRIVATE KEY-----\\n",
        "client_email": "test@example.com",
        "client_id": "some_client_id",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/test%40example.com"
      }'''));
      final projectId = 'test-project';

      final firestore = R.getFirestore(projectId, serviceAccountData);
      expect(firestore, isNotNull);
    });

    test('deleteMojiFromPlanner', () async {
      final mojiId = U.fid();
      final startTime = DateTime(2018, 1, 1).toUtc();
      final plannerId = U.did(startTime);
      final plMoji = S.mojiSignal(plannerId).untrackedValue;
      final eMoji = S.mojiSignal(mojiId).untrackedValue;

      R.m.write(() {
        plMoji.l[mojiId] = startTime;
        eMoji.p = MojiDockTile.g.name;
        eMoji.s = startTime;
      });

      R.deleteMojiFromPlanner(mojiId);

      expect(plMoji.l.containsKey(mojiId), false);
    });

    test('getDockMojiTiles', () async {
      final dockTileIds = [MojiDockTile.r.name, MojiDockTile.o.name];
      S.mojiSignal(dockTileIds[0]).untrackedValue;
      S.mojiSignal(dockTileIds[1]).untrackedValue;
      final dockMojis = R.getDockMojiTiles();
      expect(dockMojis.map((m) => m.id).toList(), containsAll(dockTileIds));
    });

    test('updateDockMojiChildrenAndGetLastParent', () async {
      final dfid = MojiDockTile.r.name;
      final cfid1 = U.fid();
      final cfid2 = U.fid();
      final order = generateOrderKeys(2);
      final dMojiR = S.mojiSignal(dfid).untrackedValue;
      final cMoji1R = S.mojiSignal(cfid1).untrackedValue;
      final cMoji2R = S.mojiSignal(cfid2).untrackedValue;
      R.m.write(() {
        dMojiR.c[cfid1] = order.first;
        dMojiR.c[cfid2] = order.last;
        cMoji1R.p = dfid;
        cMoji2R.p = dfid;
      });

      final result = R.updateDockMojiChildrenAndGetLastParent(cfid1, includeSelf: true);
      expect(result, cfid1);

      expect(dMojiR.q, {cfid1: generateOrderKeys(1).first});
    });

    test('changeParent', () async {
      final opfid = U.fid();
      final npfid = U.fid();
      final cfid = U.fid();
      final order = generateOrderKeys(1);
      final opMojiR = S.mojiSignal(opfid).untrackedValue;
      final npMojiR = S.mojiSignal(npfid).untrackedValue;
      final cMojiR = S.mojiSignal(cfid).untrackedValue;
      U.activeTreeControllers[npfid] = (
        Node(id: npfid),
        TreeController<Node>(roots: [Node(id: cfid), Node(id: opfid), Node(id: npfid)], childrenProvider: (Node node) => node.children),
      );

      R.m.write(() {
        opMojiR.p = MojiDockTile.g.name;
        npMojiR.p = MojiDockTile.g.name;
        opMojiR.c[cfid] = order.first;
        cMojiR.p = opfid;
      });

      R.changeParent(cfid, opfid, npfid, 0, 0);

      expect(cMojiR.p, npfid);
      expect(opMojiR.c, isEmpty);
      expect(npMojiR.c, {cfid: order.first});

      U.mojiChanges.undo();

      expect(cMojiR.p, opfid);
      expect(opMojiR.c, {cfid: order.first});
      expect(npMojiR.c, isEmpty);

      final ncfid = U.fid();

      R.m.write(() {
        npMojiR.c[ncfid] = order.first;
      });

      R.changeParent(cfid, opfid, npfid, 0, 0);

      expect(cMojiR.p, npfid);
      expect(opMojiR.c, isEmpty);
      expect(npMojiR.c, {cfid: between(next: order.first), ncfid: order.first});

      U.mojiChanges.undo();

      expect(cMojiR.p, opfid);
      expect(opMojiR.c, {cfid: order.first});
      expect(npMojiR.c, {ncfid: order.first});

      R.changeParent(cfid, opfid, npfid, 0, 1);

      expect(cMojiR.p, npfid);
      expect(opMojiR.c, isEmpty);
      expect(npMojiR.c, {cfid: between(prev: order.first), ncfid: order.first});

      U.mojiChanges.undo();

      expect(cMojiR.p, opfid);
      expect(opMojiR.c, {cfid: order.first});
      expect(npMojiR.c, {ncfid: order.first});

      final acfid = U.fid();
      final aclid = between(prev: order.first);
      R.m.write(() {
        npMojiR.c[acfid] = aclid;
      });

      R.changeParent(cfid, opfid, npfid, 0, 1);

      expect(cMojiR.p, npfid);
      expect(opMojiR.c, isEmpty);
      expect(npMojiR.c, {ncfid: order.first, cfid: between(prev: order.first, next: aclid), acfid: aclid});

      U.mojiChanges.undo();

      expect(cMojiR.p, opfid);
      expect(opMojiR.c, {cfid: order.first});
      expect(npMojiR.c, {ncfid: order.first, acfid: aclid});

      R.changeParent(cfid, opfid, npfid, 0, -1);

      expect(cMojiR.p, npfid);
      expect(opMojiR.c, isEmpty);
      expect(npMojiR.c, {cfid: between(next: order.first), ncfid: order.first, acfid: aclid});

      U.mojiChanges.undo();

      expect(cMojiR.p, opfid);
      expect(opMojiR.c, {cfid: order.first});
      expect(npMojiR.c, {ncfid: order.first, acfid: aclid});

      R.changeParent(cfid, opfid, npfid, 0, npMojiR.c.length + 1);

      expect(cMojiR.p, npfid);
      expect(opMojiR.c, isEmpty);
      expect(npMojiR.c, {ncfid: order.first, acfid: aclid, cfid: between(prev: aclid)});

      U.mojiChanges.undo();

      expect(cMojiR.p, opfid);
      expect(opMojiR.c, {cfid: order.first});
      expect(npMojiR.c, {ncfid: order.first, acfid: aclid});
    });

    test('openMojiToggle', () async {
      final cfid = U.fid();
      final cfid2 = U.fid();
      final orderKeys = generateOrderKeys(1);
      final mojiR = S.mojiSignal(cfid).untrackedValue;

      R.m.write(() {
        mojiR.p = MojiDockTile.g.name;
        mojiR.o = false;
        mojiR.c[cfid2] = orderKeys.first;
      });

      R.openMojiToggle(cfid);

      expect(mojiR.o, true);

      R.openMojiToggle(cfid);

      expect(mojiR.o, false);
    });

    test('getMojiDockTileAndParents', () async {
      final dfid = MojiDockTile.r.name;
      final pfid = U.fid();
      final cfid = U.fid();
      final cMojiR = S.mojiSignal(cfid).untrackedValue;
      final pMojiR = S.mojiSignal(pfid).untrackedValue;
      final dMojiR = S.mojiSignal(dfid).untrackedValue;
      R.m.write(() {
        dMojiR.d = dfid;
        pMojiR.p = dfid;
        cMojiR.p = pfid;
      });

      final (dockTile, parents) = R.getMojiDockTileAndParents(cMojiR);
      expect(dockTile.name, dfid);
      expect(parents.map((p) => p.id).toList(), [dfid, pfid]);
    });

    test('getDockMojiTiles', () async {
      final dfid1 = MojiDockTile.r.name;
      final dfid2 = MojiDockTile.o.name;
      S.mojiSignal(dfid1).untrackedValue;
      S.mojiSignal(dfid2).untrackedValue;

      final dMojiTiles = R.getDockMojiTiles();
      expect(dMojiTiles.map((m) => m.id).toList(), containsAll([dfid1, dfid2]));
    });

    test('addMojiToPlannerIfNeeded', () async {
      final sTime = DateTime(2021, 1, 1, 0, 0, 0, 0, 0).toUtc();
      final nsTime = sTime.add(Duration(minutes: 5));
      final eTime = nsTime.add(kDefaultMojiEventDuration);
      final did = U.did(sTime);
      final pfid = U.fid();
      final cfid = U.fid();
      final pMojiR = S.mojiSignal(pfid).untrackedValue;
      final cMojiR = S.mojiSignal(cfid).untrackedValue;
      final plMojiR = S.mojiSignal(did).untrackedValue;
      U.mojiPlannersNotifiers = {
        did: FlutterSignal((Map<String, FlexibleMojiEvent>.from({did: FlexibleMojiEvent(cMojiR)}), 0))
      };
      R.m.write(() {
        pMojiR.c[cfid] = generateOrderKeys(1).first;
        cMojiR.t = 'test';
        cMojiR.s = sTime.toUtc();
      });

      R.addMojiToPlannerIfNeeded(pMojiR, [Moji(cfid, s: nsTime.toUtc())], cStartTime: nsTime, cEndTime: eTime);

      expect(pMojiR.l, {cfid: nsTime});
      expect(pMojiR.c.length, 0);
      expect(plMojiR.l, {cfid: nsTime});

      U.mojiChanges.undo();

      expect(pMojiR.l.length, 0);
      expect(pMojiR.c.length, 1);
      expect(pMojiR.c.keys.first, cfid);
      expect(pMojiR.c.values.first, generateOrderKeys(1).first);
      expect(plMojiR.l.length, 0);
    });

    test('addMojiToPlannerIfNeeded removes moji from planner when the new start time is on a different day', () async {
      final sTime = DateTime(2021, 1, 1, 0, 0, 0, 0, 0).toUtc();
      final nsTime = sTime.add(Duration(minutes: 2000));
      final eTime = nsTime.add(kDefaultMojiEventDuration);
      final did = U.did(sTime);
      final nDid = U.did(nsTime);
      final pfid = U.fid();
      final cfid = U.fid();
      final pMojiR = S.mojiSignal(pfid).untrackedValue;
      final cMojiR = S.mojiSignal(cfid).untrackedValue;
      final plMojiR = S.mojiSignal(did).untrackedValue;
      final nPlMojiR = S.mojiSignal(nDid).untrackedValue;
      U.mojiPlannersNotifiers = {
        did: FlutterSignal((Map<String, FlexibleMojiEvent>.from({did: FlexibleMojiEvent(cMojiR)}), 0))
      };
      R.m.write(() {
        pMojiR.c[cfid] = generateOrderKeys(1).first;
        cMojiR.t = 'test';
        cMojiR.s = sTime.toUtc();
        plMojiR.l[cfid] = sTime.toUtc();
      });

      R.addMojiToPlannerIfNeeded(pMojiR, [Moji(cfid, s: nsTime.toUtc())], cStartTime: nsTime, cEndTime: eTime);

      expect(pMojiR.l, {cfid: nsTime});
      expect(pMojiR.c.length, 0);
      expect(plMojiR.l, isEmpty);
      expect(nPlMojiR.l, {cfid: nsTime});

      U.mojiChanges.undo();

      expect(pMojiR.l.length, 0);
      expect(pMojiR.c.length, 1);
      expect(pMojiR.c.keys.first, cfid);
      expect(pMojiR.c.values.first, generateOrderKeys(1).first);
      expect(plMojiR.l.length, 0);
      expect(nPlMojiR.l.length, 0);
    });

    test('addChildMoji', () async {
      final pfid = U.fid();
      final cfid = U.fid();
      const text = 'Test child';
      final pMojiR = S.mojiSignal(pfid).untrackedValue;
      final cMojiR = S.mojiSignal(cfid).untrackedValue;

      R.addChildMoji(pid: pfid, cfid: cfid, text: text);

      expect(pMojiR.c, {cfid: generateOrderKeys(1).first});

      expect(cMojiR.p, pfid);
      expect(cMojiR.t, text);
    });

    test('addSiblingMoji', () async {
      final pfid = U.fid();
      final cfid1 = U.fid();
      final cfid2 = U.fid();
      final sfid = U.fid();
      final order = generateOrderKeys(2);
      final pMojiR = S.mojiSignal(pfid).untrackedValue;
      final cMojiR = S.mojiSignal(cfid1).untrackedValue;
      final sMojiR = S.mojiSignal(sfid).untrackedValue;

      R.m.write(() {
        pMojiR.c[cfid1] = order.first;
        pMojiR.c[cfid2] = order.last;
        cMojiR.p = pfid;
      });

      R.addSiblingMoji(cMojiR, sfid: sfid);

      expect(pMojiR.c, {cfid1: order.first, cfid2: order.last, sfid: between(prev: order.first, next: order.last)});

      expect(sMojiR.p, pfid);
    });

    test('updateMoji card updates correctly', () async {
      final cfid = U.fid();
      final opfid = U.fid();
      final npfid = U.fid();

      final opMojiR = S.mojiSignal(opfid).untrackedValue;
      final cMojiR = S.mojiSignal(cfid).untrackedValue;
      final npMojiR = S.mojiSignal(npfid).untrackedValue;
      const text = 'Updated text';
      final orderKeys = generateOrderKeys(1);
      R.m.write(() {
        opMojiR.c[cfid] = orderKeys.first;
        opMojiR.h[cfid] = orderKeys.first;
        cMojiR.p = opfid;
      });

      R.updateMoji(cfid, text: text, npid: npfid, shouldUpdateOrigin: true);

      expect(cMojiR.t, text);
      expect(cMojiR.p, npfid);
      expect(opMojiR.c.length, 0);
      expect(opMojiR.h.length, 0);
      expect(npMojiR.c.length, 1);

      U.mojiChanges.undo();

      expect(cMojiR.t, null);
      expect(cMojiR.m, isNull);
      expect(cMojiR.p, opfid);
      expect(npMojiR.c.length, 0);
      expect(opMojiR.h.length, 1);
      expect(opMojiR.c.length, 1);
    });

    test('updateMoji tile updates correctly', () async {
      final cfid = U.fid();
      final opfid = U.fid();
      final npfid = U.fid();
      final svg = 'brain-02-stroke-rounded.svg';

      final opMojiR = S.mojiSignal(opfid).untrackedValue;
      final cMojiR = S.mojiSignal(cfid).untrackedValue;
      final npMojiR = S.mojiSignal(npfid).untrackedValue;
      const text = 'Updated text';
      final orderKeys = generateOrderKeys(1);
      R.m.write(() {
        opMojiR.h[cfid] = orderKeys.first;
        cMojiR.p = opfid;
        cMojiR.m = svg;
      });

      R.updateMoji(cfid, text: text, npid: npfid);

      expect(cMojiR.t, text);
      expect(cMojiR.p, npfid);
      expect(cMojiR.m, svg);
      expect(opMojiR.c.length, 0);
      expect(opMojiR.h.length, 0);
      expect(npMojiR.h.length, 1);

      U.mojiChanges.undo();

      expect(cMojiR.t, null);
      expect(cMojiR.p, opfid);
      expect(cMojiR.m, svg);
      expect(opMojiR.c.length, 0);
      expect(opMojiR.h.length, 1);
      expect(npMojiR.h.length, 0);
    });

    test('clearQuickAccessMojis', () async {
      final cfid = U.fid();
      final order = generateOrderKeys(2);
      final mojiR = S.mojiSignal(cfid).untrackedValue;
      R.m.write(() {
        mojiR.p = MojiDockTile.g.name;
        mojiR.q['quick1'] = order.first;
        mojiR.q['quick2'] = order.last;
      });

      R.clearQuickAccessMojis(cfid);

      expect(mojiR.q, isEmpty);
    });

    test('getMoji', () async {
      final cfid = U.fid();
      S.mojiSignal(cfid).untrackedValue;
      final mojiR = R.getMoji(cfid);
      expect(mojiR.id, cfid);
    });

    test('finishMoji', () async {
      final cfid = U.fid();
      final mojiR = S.mojiSignal(cfid).untrackedValue;

      R.finishMoji(cfid);

      expect(mojiR.f, isNotNull);

      U.mojiChanges.undo();

      expect(mojiR.f, isNull);

      R.finishMoji(cfid);
      R.finishMoji(cfid);

      expect(mojiR.f, U.zeroDateTime);

      U.mojiChanges.undo();

      expect(mojiR.f, isNotNull);
    });

    test('getAllMojis', () async {
      final cfid1 = U.fid();
      final cfid2 = U.fid();
      S.mojiSignal(cfid1).untrackedValue;
      S.mojiSignal(cfid2).untrackedValue;
      final allMojis = R.getAllMojis({cfid1, cfid2, ''});
      expect(allMojis.length, 2);
      expect(allMojis.map((m) => m.id).toList(), [cfid1, cfid2]);
    });

    test('clear', () async {
      final cfid = U.fid();
      S.mojiSignal(cfid).untrackedValue;

      R.clear();

      final allMojis = R.m.all<Moji>();
      expect(allMojis, isEmpty);
    });

    test('deleteMojiFromPlanner', () async {
      final sTime = DateTime(2017, 1, 1).toUtc();
      final did = U.did(sTime);
      final cfid = U.fid();
      final plMojiR = S.mojiSignal(did).untrackedValue;
      final eMojiR = S.mojiSignal(cfid).untrackedValue;
      R.m.write(() {
        plMojiR.l[cfid] = sTime.toUtc();
        eMojiR.p = MojiDockTile.g.name;
        eMojiR.s = sTime;
      });

      R.deleteMojiFromPlanner(cfid);

      expect(plMojiR.l, isEmpty);
    });

    test('deleteMoji', () async {
      final sTime = DateTime.now().toUtc();
      final did = U.did(sTime);
      final pfid = U.fid();
      final cfid = U.fid();
      final order = generateOrderKeys(1);
      final pMojiR = S.mojiSignal(pfid).untrackedValue;
      final cMojiR = S.mojiSignal(cfid).untrackedValue;
      final plMojiR = S.mojiSignal(did).untrackedValue;
      U.mojiPlannersNotifiers = {
        did: FlutterSignal((Map<String, FlexibleMojiEvent>.from({did: FlexibleMojiEvent(cMojiR)}), 0))
      };
      R.m.write(() {
        pMojiR.c[cfid] = order.first;
        cMojiR.s = sTime;
        cMojiR.p = pfid;
        plMojiR.l[cfid] = sTime.toUtc();
      });

      R.deleteMojis({cfid});

      expect(pMojiR.c, isEmpty);
      expect(pMojiR.j.values.first.isAfter(sTime), true);
      expect(plMojiR.l, isEmpty);
      expect(plMojiR.j.values.first.isAfter(sTime), true);

      U.mojiChanges.undo();

      expect(pMojiR.c, {cfid: order.first});
      expect(pMojiR.j, isEmpty);
      expect(plMojiR.l, {cfid: sTime});
      expect(plMojiR.j, isEmpty);
      expect(cMojiR.p, pfid);
      expect(cMojiR.s, sTime);

      R.m.write(() {
        pMojiR.c[cfid] = order.first;
        cMojiR.s = sTime;
        cMojiR.p = pfid;
        plMojiR.l[cfid] = sTime.toUtc();
      });

      R.deleteMojis({cfid}, permanently: true);

      expect(pMojiR.c, isEmpty);
      expect(pMojiR.j, isEmpty);
      expect(plMojiR.l, isEmpty);
      expect(plMojiR.j, isEmpty);
    });

    test('mergeMojiTiles', () async {
      final sTime = DateTime.now().toUtc();
      final pfid = U.fid();
      final mwwid = U.fid();
      final mwwcid = U.fid();
      final mtid = U.fid();
      const svg = 'brain-02-stroke-rounded.svg';
      final order = generateOrderKeys(2);

      final pMojiR = S.mojiSignal(pfid).untrackedValue;
      final mojiWWR = S.mojiSignal(mwwid).untrackedValue;
      final mojiWWcR = S.mojiSignal(mwwcid).untrackedValue;
      final mojiTargetR = S.mojiSignal(mtid).untrackedValue;

      R.m.write(() {
        pMojiR.c[mwwid] = order.first;
        pMojiR.c[mtid] = order.last;
        mojiWWR.c[mwwcid] = order.first;
        mojiWWR.h[mtid] = order.last;
        mojiWWR.p = pfid;
        mojiWWR.m = svg;
        mojiWWcR.p = mwwid;
        mojiTargetR.p = pfid;
        mojiTargetR.m = svg;
      });

      R.mergeMojiTiles(mojiWWR, mojiTargetR);

      expect(pMojiR.c, {mtid: order.last});
      expect(pMojiR.j.values.first.isAfter(sTime), true);
      expect(mojiWWR.c, {});
      expect(mojiWWR.h, {});
      expect(mojiWWR.l, {});
      expect(mojiWWR.j, {});
      expect(mojiTargetR.c, {mwwcid: order.first});
      expect(mojiTargetR.h, {mtid: order.last});
      expect(mojiWWcR.p, mtid);

      U.mojiChanges.undo();

      expect(pMojiR.c, {mwwid: order.first, mtid: order.last});
      expect(pMojiR.j, isEmpty);
      expect(mojiWWR.c, {mwwcid: order.first});
      expect(mojiWWR.h, {mtid: order.last});
      expect(mojiWWR.l, isEmpty);
      expect(mojiWWR.j, isEmpty);
      expect(mojiTargetR.c, isEmpty);
      expect(mojiTargetR.h, isEmpty);
      expect(mojiWWcR.p, mwwid);
    });

    test('fixMojiRelations', () async {
      final pfid = U.fid();
      final cfid = U.fid();
      final efid = U.fid();
      final rfid = U.fid();
      final tfid = U.fid();
      final sTime = DateTime(2020, 1, 1, 0, 0, 0, 0, 0).toUtc();
      final did = U.did(sTime);
      final order = generateOrderKeys(2);
      final pMojiR = S.mojiSignal(pfid).untrackedValue;
      final plMojiR = S.mojiSignal(did).untrackedValue;
      final cMojiR = S.mojiSignal(cfid).untrackedValue;
      final eMojiR = S.mojiSignal(efid).untrackedValue;
      final rMojiR = S.mojiSignal(rfid).untrackedValue;
      final tmojiR = S.mojiSignal(tfid).untrackedValue;
      R.m.write(() {
        pMojiR.p = MojiDockTile.g.name;
        plMojiR.j[rfid] = sTime;
        plMojiR.l[rfid] = sTime;
        cMojiR.p = pfid;
        cMojiR.l[rfid] = sTime;
        cMojiR.c[efid] = order.first;
        cMojiR.c[rfid] = order.last;
        cMojiR.h[rfid] = order.last;
        cMojiR.j[rfid] = sTime;
        eMojiR.p = cfid;
        eMojiR.s = sTime;
        rMojiR.p = cfid;
        rMojiR.s = sTime;
        tmojiR.p = cfid;
        tmojiR.m = 'brain-02-stroke-rounded.svg';
      });

      R.fixMojiRelations();

      expect(pMojiR.c, {cfid: generateOrderKeys(1).first});
      expect(pMojiR.j, isEmpty);
      expect(cMojiR.p, pfid);
      expect(cMojiR.c, {});
      expect(cMojiR.l.containsKey(efid), true);
      expect(cMojiR.h, {tfid: generateOrderKeys(1).first});
      expect(cMojiR.j, {rfid: sTime});
      expect(eMojiR.p, cfid);
      expect(eMojiR.s, sTime);
      expect(plMojiR.l, {efid: sTime});
    });

    test('changeMojiDay', () async {
      final sTime = DateTime(2023, 1, 1).subtract(const Duration(days: 10)).toUtc();
      final eTime = sTime.add(kDefaultMojiEventDuration).toUtc();
      final pid = U.fid();
      final cid = U.fid();
      final cDate = DateTime(2024, 1, 1).toUtc();
      final cStartTime = DateTime(cDate.year, cDate.month, cDate.day, sTime.hour, sTime.minute).toUtc();
      final oplid = U.did(sTime);
      final nplid = U.did(cDate);
      final pMojiR = S.mojiSignal(pid).untrackedValue;
      final cMojiR = S.mojiSignal(cid).untrackedValue;
      final plMojiR = S.mojiSignal(oplid).untrackedValue;
      final nplMojiR = S.mojiSignal(nplid).untrackedValue;
      final oplMojiR = S.mojiSignal(oplid).untrackedValue;
      R.m.write(() {
        pMojiR.p = MojiDockTile.g.name;
        pMojiR.l[cid] = sTime;
        cMojiR.s = sTime;
        cMojiR.e = eTime;
        cMojiR.p = pid;
        plMojiR.l[cid] = sTime;
      });
      R.changeMojiDay(cDate, cMojiR);
      expect(pMojiR.l, {cid: sTime});
      expect(cMojiR.s, DateTime(cDate.year, cDate.month, cDate.day, sTime.hour, sTime.minute).toUtc());
      expect(cMojiR.e, DateTime(cDate.year, cDate.month, cDate.day, eTime.hour, eTime.minute).toUtc());
      expect(oplMojiR.l, {});
      expect(nplMojiR.l, {cid: cStartTime});
    });
  });
}
