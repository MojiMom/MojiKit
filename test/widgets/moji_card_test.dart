import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_test/flutter_test.dart';
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

  group('MojiCard widget tests', () {
    testWidgets('MojiCard renders correctly and can receive focus', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MojiCard(
              id: 'testId',
              renderedByMojiIsland: false,
              shouldShowParentMojis: false,
              openMojiChild: false,
              placeholder: false,
            ),
          ),
        ),
      );

      // Verify that MojiCard widget is displayed
      expect(find.byType(MojiCard), findsOneWidget);

      // Tap to give focus
      await tester.tap(find.byType(TextField));
      await tester.pump();

      // Verify that the text field has focus
      final textField = find.byType(TextField);
      expect(tester.widget<TextField>(textField).focusNode?.hasFocus, isTrue);
    });

    testWidgets('MojiCard removes empty node and deletes Moji when text is empty', (WidgetTester tester) async {
      final mockNode = Node(id: 'testNodeId');
      U.activeTreeController = (mockNode, TreeController<Node>(roots: [mockNode], childrenProvider: (Node node) => node.children));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MojiCard(
              id: 'testId',
              renderedByMojiIsland: false,
              shouldShowParentMojis: false,
              openMojiChild: false,
              placeholder: false,
              node: mockNode,
            ),
          ),
        ),
      );

      // Enter empty text to trigger deletion
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      // Verify that the node was removed and the Moji deleted
      expect(mockNode.parent?.children, isNull);
    });

    testWidgets('MojiCard prefixes text with empty space if not present', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MojiCard(
              id: 'testId',
              renderedByMojiIsland: false,
              shouldShowParentMojis: false,
              openMojiChild: false,
              placeholder: false,
            ),
          ),
        ),
      );

      // Enter text without leading space
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();

      // Verify that the text now has a leading space
      final textField = find.byType(TextField);
      expect((tester.widget<TextField>(textField).controller as TextEditingController).text, equals('${kEmptySpace}Hello'));
    });

    testWidgets('MojiCard disallows 0th character selection', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MojiCard(
              id: 'testId',
              renderedByMojiIsland: false,
              shouldShowParentMojis: false,
              openMojiChild: false,
              placeholder: false,
            ),
          ),
        ),
      );

      // Enter text and set cursor at position 0
      await tester.enterText(find.byType(TextField), 'Hello');
      final textField = find.byType(TextField);
      (tester.widget<TextField>(textField).controller as TextEditingController).selection = TextSelection(baseOffset: 0, extentOffset: 0);
      await tester.pump();

      // Verify that the cursor was moved to position 1
      expect((tester.widget<TextField>(textField).controller as TextEditingController).selection.baseOffset, equals(1));
    });

    testWidgets('MojiCard updates server when focus is lost with unwritten changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MojiCard(
              id: 'testId',
              renderedByMojiIsland: false,
              shouldShowParentMojis: false,
              openMojiChild: false,
              placeholder: false,
            ),
          ),
        ),
      );

      // Enter text to create an unwritten change
      await tester.enterText(find.byType(TextField), 'New Moji Text');
      await tester.pump();

      // Remove focus
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      // Verify that the server was updated
      expect(R.getMoji('testId').t, equals('${kEmptySpace}New Moji Text'));
    });

    testWidgets('MojiCard handles onTapOutside by updating server and clearing text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GestureDetector(
              // Add a GestureDetector to tap outside the TextField
              onTap: () {},
              child: Column(
                children: [
                  MojiCard(
                    id: 'testId',
                    renderedByMojiIsland: false,
                    shouldShowParentMojis: false,
                    openMojiChild: false,
                    placeholder: false,
                  ),
                  SizedBox(height: 50), // Space to tap outside
                ],
              ),
            ),
          ),
        ),
      );

      // Tap to give focus
      await tester.tap(find.byType(TextField));
      await tester.pump();

      // Enter text to create an unwritten change
      await tester.enterText(find.byType(TextField), 'Outside Tap Test');
      await tester.pump();

      // Tap outside to trigger onTapOutside
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();

      // Verify that the server was updated and currentMojiText was cleared
      expect(R.getMoji('testId').t, equals('${kEmptySpace}Outside Tap Test'));
      expect(S.currentMojiText.value, equals(kEmptyString));
    });

    testWidgets('Can create sibling moji when submitting text on thoughts view', (WidgetTester tester) async {
      S.selectedHeaderView.set(MMHeaderView.thoughts);
      final pMojiId = U.fid();
      final cMojiId = U.fid();
      final pMojiR = untracked(() => S.mojiSignal(pMojiId).value);
      final cMojiR = untracked(() => S.mojiSignal(cMojiId).value);
      final orderKey = generateOrderKeys(2);
      R.m.write(() {
        pMojiR.c[cMojiId] = orderKey.first;
        cMojiR.p = pMojiId;
      });
      final Widget app = MaterialApp(
        home: Material(
          child: Center(
            child: MojiCard(
              id: cMojiId,
              renderedByMojiIsland: false,
              shouldShowParentMojis: false,
              openMojiChild: false,
              placeholder: false,
            ),
          ),
        ),
      );

      await tester.pumpWidget(app);

      // Set initial focus to window.
      await tester.tapAt(Offset.zero);

      await tester.enterText(find.byType(TextField), 'Submitted Text');
      await tester.pumpAndSettle();

      // Move focus to first focusable widget via keyboard (TextField).
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Send done action to submit form field.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(cMojiR.t, equals('${kEmptySpace}Submitted Text'));
      expect(pMojiR.c.length, equals(2));
    });

    testWidgets('Can create child moji when submitting text on thoughts view', (WidgetTester tester) async {
      S.selectedHeaderView.set(MMHeaderView.thoughts);
      final pMojiId = U.fid();
      final pMojiR = untracked(() => S.mojiSignal(pMojiId).value);
      U.activeTreeController =
          (Node(id: pMojiId), TreeController<Node>(roots: [Node(id: pMojiId)], childrenProvider: (Node node) => node.children));
      R.m.write(() {
        pMojiR.p = MojiDockTile.g.name;
      });
      final Widget app = MaterialApp(
        home: Material(
          child: Center(
            child: MojiCard(
              id: pMojiId,
              renderedByMojiIsland: true,
              shouldShowParentMojis: true,
              openMojiChild: false,
              placeholder: false,
            ),
          ),
        ),
      );

      await tester.pumpWidget(app);

      // Set initial focus to window.
      await tester.tapAt(Offset.zero);

      await tester.enterText(find.byType(TextField), 'Submitted Text');
      await tester.pumpAndSettle();

      // Move focus to first focusable widget via keyboard (TextField).
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Send done action to submit form field.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(pMojiR.t, equals('${kEmptySpace}Submitted Text'));
      expect(pMojiR.c.length, equals(1));
    });

    testWidgets('Can update itself when not on thoughts view', (WidgetTester tester) async {
      S.selectedHeaderView.set(MMHeaderView.plan);
      final pMojiId = U.fid();
      final pMojiR = untracked(() => S.mojiSignal(pMojiId).value);
      final Widget app = MaterialApp(
        home: Material(
          child: Center(
            child: MojiCard(
              id: pMojiId,
              renderedByMojiIsland: true,
              shouldShowParentMojis: true,
              openMojiChild: false,
              placeholder: false,
            ),
          ),
        ),
      );

      await tester.pumpWidget(app);

      // Set initial focus to window.
      await tester.tapAt(Offset.zero);

      await tester.enterText(find.byType(TextField), 'Submitted Text');
      await tester.pumpAndSettle();

      // Move focus to first focusable widget via keyboard (TextField).
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Send done action to submit form field.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(pMojiR.t, equals('${kEmptySpace}Submitted Text'));
    });

    testWidgets('Can request focus when tapped outside of TextField', (WidgetTester tester) async {
      final Widget app = MaterialApp(
        home: Material(
          child: Center(
            child: MojiCard(
              id: U.fid(),
              renderedByMojiIsland: false,
              shouldShowParentMojis: false,
              openMojiChild: false,
              placeholder: false,
            ),
          ),
        ),
      );

      await tester.pumpWidget(app);

      final widget = find.byType(MojiCard).first;
      final rect = tester.getRect(widget);
      await tester.tapAt(rect.topLeft);
      await tester.pump();

      final textField = find.byType(TextField);
      expect(tester.widget<TextField>(textField).focusNode?.hasFocus, isTrue);
    });

    testWidgets('Displays the iOS context menu when supported', (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            final MediaQueryData mediaQueryData = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQueryData.copyWith(
                supportsShowingSystemContextMenu: defaultTargetPlatform == TargetPlatform.iOS,
              ),
              child: const MaterialApp(
                home: Scaffold(
                  body: MojiCard(
                    id: 'testId',
                    renderedByMojiIsland: false,
                    shouldShowParentMojis: false,
                    openMojiChild: false,
                    placeholder: false,
                  ),
                ),
              ),
            );
          },
        ),
      );

      // Tap to give focus
      await tester.tap(find.byType(TextField));
      await tester.pump();

      // Trigger long press to open context menu
      await tester.longPress(find.byType(TextField));
      await tester.pump();

      // Verify that the correct context menu is shown based on platform support
      if (SystemContextMenu.isSupported(tester.element(find.byType(TextField)))) {
        expect(find.byType(SystemContextMenu), findsOneWidget);
      } else {
        expect(find.byType(AdaptiveTextSelectionToolbar), findsOneWidget);
      }
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('Displays the Flutter context menu when unsupported', (WidgetTester tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            final MediaQueryData mediaQueryData = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQueryData.copyWith(
                supportsShowingSystemContextMenu: defaultTargetPlatform == TargetPlatform.iOS,
              ),
              child: const MaterialApp(
                home: Scaffold(
                  body: MojiCard(
                    id: 'testId',
                    renderedByMojiIsland: false,
                    shouldShowParentMojis: false,
                    openMojiChild: false,
                    placeholder: false,
                  ),
                ),
              ),
            );
          },
        ),
      );

      // Tap to give focus
      await tester.tap(find.byType(TextField));
      await tester.pump();

      // Trigger long press to open context menu
      await tester.longPress(find.byType(TextField));
      await tester.pump();

      // Verify that the correct context menu is shown based on platform support
      if (SystemContextMenu.isSupported(tester.element(find.byType(TextField)))) {
        expect(find.byType(SystemContextMenu), findsOneWidget);
      } else {
        expect(find.byType(AdaptiveTextSelectionToolbar), findsOneWidget);
      }
    });
  });
}
