import 'package:flutter/material.dart';
import 'package:mojikit/mojikit.dart';

class TextWithPrefixController extends TextEditingController {
  final Widget prefixWidget;

  TextWithPrefixController({
    required this.prefixWidget,
    super.text,
  });

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return TextSpan(
      style: style,
      children: [
        WidgetSpan(
          child: prefixWidget,
        ),
        TextSpan(text: text.replaceFirst(kEmptySpace, kEmptyString)),
      ],
    );
  }
}
