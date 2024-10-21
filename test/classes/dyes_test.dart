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
    test('unknown Dye contains all black colors', () {
      final dye = Dyes.unknown;

      expect(dye.ultraDark, Colors.black);
      expect(dye.extraDark, Colors.black);
      expect(dye.darker, Colors.black);
      expect(dye.dark, Colors.black);
      expect(dye.medium, Colors.black);
      expect(dye.light, Colors.black);
      expect(dye.lighter, Colors.black);
      expect(dye.extraLight, Colors.black);
      expect(dye.ultraLight, Colors.black);
    });

    test('dyes return correct value based on darkness', () async {
      final preferences = untracked(() => S.preferencesSignal(kLocalPreferences).value);

      expect(preferences.darkness, isNot(true));

      R.p.write(() {
        preferences.darkness = true;
      });

      expect(Dyes.teal.value, equals(Dyes.tealDark));
      expect(Dyes.blue.value, equals(Dyes.blueDark));
      expect(Dyes.indigo.value, equals(Dyes.indigoDark));
      expect(Dyes.pink.value, equals(Dyes.pinkDark));
      expect(Dyes.red.value, equals(Dyes.redDark));
      expect(Dyes.orange.value, equals(Dyes.orangeDark));
      expect(Dyes.green.value, equals(Dyes.greenDark));
      expect(Dyes.chestnut.value, equals(Dyes.chestnustDark));
    });

    test('generateDyePalette returns a dye palette', () {
      final baseColor = Colors.teal;
      final generatedDye = generateDyePalette(baseColor);

      expect(generatedDye, isA<Dye>());
      expect(generatedDye.ultraDark, isNotNull);
      expect(generatedDye.ultraLight, isNotNull);
    });

    test('invertColor correctly inverts the color', () {
      final originalColor = const Color.fromARGB(255, 100, 150, 200);
      final invertedColor = invertColor(originalColor);

      expect(invertedColor.red, 155);
      expect(invertedColor.green, 105);
      expect(invertedColor.blue, 55);
    });
  });
}
