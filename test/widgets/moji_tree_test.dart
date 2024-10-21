import 'package:flutter/gestures.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lexicographical_order/lexicographical_order.dart';
import 'package:mojikit/mojikit.dart';
import 'package:realm/realm.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals.dart';

void main() {
  setUpAll(() async {
    R.m = Realm(Configuration.local([Moji.schema], path: await U.newTestRealm()));
    R.p = Realm(Configuration.local([Preferences.schema], path: await U.newTestRealm()));
    R.online = false;
  });

  group('MojiTree widget tests', () {
    testWidgets('MojiTree initializes correctly with root node', (WidgetTester tester) async {
      final rid = U.fid();
      final pid = U.fid();
      final cid = U.fid();
      final gcid = U.fid();
      final ggcid = U.fid();
      final rMojiR = untracked(() => S.mojiSignal(rid).value);
      final pMojiR = untracked(() => S.mojiSignal(pid).value);
      final cMojiR = untracked(() => S.mojiSignal(cid).value);
      final gcMojiR = untracked(() => S.mojiSignal(gcid).value);
      final ggcMojiR = untracked(() => S.mojiSignal(ggcid).value);
      final orderKeys = generateOrderKeys(2);
      R.m.write(() {
        rMojiR.c[pid] = orderKeys.first;
        rMojiR.c[cid] = orderKeys.last;
        cMojiR.c[gcid] = orderKeys.first;
        gcMojiR.c[ggcid] = orderKeys.first;

        rMojiR.p = MojiDockTile.g.name;
        pMojiR.p = rid;
        cMojiR.p = rid;
        gcMojiR.p = cid;
        ggcMojiR.p = gcid;
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MojiTree(
              mid: rid,
              mojiPlannerWidth: 200.0,
              dye: untracked(() => Dyes.green.value),
            ),
          ),
        ),
      );

      // Verify that MojiTree widget is displayed
      expect(find.byType(MojiTree), findsOneWidget);

      expect(rMojiR.c, {pid: orderKeys.first, cid: orderKeys.last});

      final Offset firstLocation = tester.getCenter(find.byType(TreeDraggable<Node>).last);
      final Offset secondLocation = tester.getCenter(find.byType(TreeDraggable<Node>).first);
      TestGesture gesture;

      gesture = await tester.startGesture(firstLocation);
      await tester.pump(kLongPressTimeout);
      await gesture.moveTo(secondLocation);
      await tester.pump();
      expect(untracked(() => S.flyingMoji.value.id), equals(cid));
      await gesture.up();
      await tester.pump();

      expect(rMojiR.c, {pid: orderKeys.first});

      expect(find.byIcon(HugeIcons.strokeRoundedArrowRight01), findsOneWidget);
      await tester.tap(find.byIcon(HugeIcons.strokeRoundedArrowRight01));
      await tester.pump();

      U.mojiChanges.undo();
      await tester.pump();

      expect(rMojiR.c, {pid: orderKeys.first, cid: orderKeys.last});

      gesture = await tester.startGesture(firstLocation);
      await tester.pump(kLongPressTimeout);
      await gesture.moveTo(Offset(secondLocation.dx, secondLocation.dy + 15));
      await tester.pump();
      expect(untracked(() => S.flyingMoji.value.id), equals(cid));
      await gesture.up();
      await tester.pump();

      expect(rMojiR.c, {pid: orderKeys.first, cid: between(prev: orderKeys.first)});

      U.mojiChanges.undo();
      await tester.pump();

      expect(rMojiR.c, {pid: orderKeys.first, cid: orderKeys.last});

      gesture = await tester.startGesture(firstLocation);
      await tester.pump(kLongPressTimeout);
      await gesture.moveTo(Offset(secondLocation.dx, secondLocation.dy - 15));
      await tester.pump();
      expect(untracked(() => S.flyingMoji.value.id), equals(cid));
      await gesture.up();
      await tester.pump();

      expect(rMojiR.c, {cid: between(next: orderKeys.first), pid: orderKeys.first});
    });
  });
  group('Node', () {
    test('initializes correctly with id and optional children', () {
      final child1 = Node(id: 'child1');
      final child2 = Node(id: 'child2');
      final parent = Node(id: 'parent', children: [child1, child2]);

      expect(parent.id, 'parent');
      expect(parent.children.length, 2);
      expect(parent.isLeaf, false);
      expect(child1.parent, parent);
      expect(child2.parent, parent);
    });

    test('isLeaf returns true when node has no children', () {
      final node = Node(id: 'single');

      expect(node.isLeaf, true);
    });

    test('removeChild properly removes a child and sets its parent to null', () {
      final child = Node(id: 'child');
      final parent = Node(id: 'parent', children: [child]);

      parent.removeChild(child);

      expect(parent.children.length, 0);
      expect(child.parent, null);
    });

    test('insertChild correctly adds a child at the specified index', () {
      final child1 = Node(id: 'child1');
      final child2 = Node(id: 'child2');
      final parent = Node(id: 'parent', children: [child1]);

      parent.insertChild(0, child2);

      expect(parent.children.length, 2);
      expect(parent.children.first.id, 'child2');
      expect(child2.parent, parent);
    });

    test('insertChild updates parent and maintains valid structure', () {
      final parent = Node(id: 'parent');
      final child = Node(id: 'child');
      parent.insertChild(0, child);

      expect(parent.children.length, 1);
      expect(child.parent, parent);
      expect(parent.children.first, child);
    });

    test('insertChild updates parent and maintains valid structure even when dropping a node at the same parent', () {
      final child1 = Node(id: 'child1');
      final child2 = Node(id: 'child2');
      final child3 = Node(id: 'child3');
      final parent = Node(id: 'parent', children: [child1, child2, child3]);

      parent.insertChild(2, child1);
      expect(parent.children.length, 3);
      expect(child1.parent, parent);
      expect(child2.parent, parent);
      expect(child3.parent, parent);
      expect(child1.index, 2);
    });
  });
}
