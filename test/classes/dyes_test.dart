import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mojikit/mojikit.dart';
import 'package:realm/realm.dart';
import 'package:signals/signals_flutter.dart';

void main() {
  setUpAll(() async {
    R.m = Realm(Configuration.local([Moji.schema], path: await U.newTestRealm()));
    R.p = Realm(Configuration.local([Preferences.schema], path: await U.newTestRealm()));
    R.online = false;
    return Future.value();
  });

  group('Dyes class tests', () {
    test('the ultra dark dye is same as the reference', () {
      final dye = untracked(() => Dyes.grey.value);

      expect(dye.ultraDark, Dyes.greyReference);
    });

    test('dyes return correct value based on darkness', () async {
      final preferences = untracked(() => S.preferencesSignal(kLocalPreferences).value);

      expect(preferences.darkness, isNot(true));

      R.p.write(() {
        preferences.darkness = true;
      });

      expect(Dyes.grey.value, equals(Dyes.greyDark));
      expect(Dyes.teal.value, equals(Dyes.tealDark));
      expect(Dyes.blue.value, equals(Dyes.blueDark));
      expect(Dyes.indigo.value, equals(Dyes.indigoDark));
      expect(Dyes.pink.value, equals(Dyes.pinkDark));
      expect(Dyes.red.value, equals(Dyes.redDark));
      expect(Dyes.orange.value, equals(Dyes.orangeDark));
      expect(Dyes.green.value, equals(Dyes.greenDark));
      expect(Dyes.chestnut.value, equals(Dyes.chestnutDark));
    });

    test('generateDyePalette returns a dye palette', () {
      final baseColor = Colors.teal;
      final generatedDye = generateDyePalette(baseColor);

      expect(generatedDye, isA<Dye>());
      expect(generatedDye.ultraDark, isNotNull);
      expect(generatedDye.ultraLight, isNotNull);
    });

    test('invertColor correctly inverts the color', () {
      final originalColor = const Color.from(alpha: 1.0, red: 0.9, green: 0.8, blue: 0.7);
      final invertedColor = invertColor(originalColor);

      expect((invertedColor.r * 10).round() / 10, 0.1);
      expect((invertedColor.g * 10).round() / 10, 0.2);
      expect((invertedColor.b * 10).round() / 10, 0.3);
    });
  });
}
