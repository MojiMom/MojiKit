import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mojikit/mojikit.dart';

void main() {
  group('TextWithPrefixController tests', () {
    testWidgets('buildTextSpan includes prefixWidget and text', (WidgetTester tester) async {
      const prefixText = 'Prefix';
      const inputText = 'Input Text';
      final controller = TextWithPrefixController(
        prefixWidget: const Text(prefixText),
        text: inputText,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              controller: controller,
            ),
          ),
        ),
      );

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      final textWidgetFinder = find.text(prefixText);
      expect(textWidgetFinder, findsOneWidget);

      final inputTextFinder = find.text(inputText);
      expect(inputTextFinder, findsOneWidget);
    });

    test('initial text is set correctly', () {
      const inputText = 'Initial Text';
      final controller = TextWithPrefixController(
        prefixWidget: const SizedBox(),
        text: inputText,
      );

      final text = controller.text;

      expect(text, equals(inputText));
    });

    testWidgets('prefixWidget is included in the text field', (WidgetTester tester) async {
      const prefixText = 'Prefix';
      final controller = TextWithPrefixController(
        prefixWidget: const Text(prefixText),
        text: 'Some text',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.text(prefixText), findsOneWidget);
    });

    test('buildTextSpan replaces first occurrence of kEmptySpace', () {
      const inputText = '${kEmptySpace}Hello';
      final controller = TextWithPrefixController(
        prefixWidget: const SizedBox(),
        text: inputText,
      );

      final textSpan = controller.buildTextSpan(
        context: TestWidgetsFlutterBinding.ensureInitialized().rootElement!,
        style: null,
        withComposing: false,
      );

      expect(textSpan.children![1], isA<TextSpan>());
      expect((textSpan.children![1] as TextSpan).text, equals('Hello'));
    });
  });
}
