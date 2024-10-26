import 'package:flutter_test/flutter_test.dart';
import 'package:mojikit/mojikit.dart';

void main() {
  group('Moji toJson tests', () {
    test('toJson converts Moji object to correct map', () {
      final moji = Moji(
        'testId',
        a: 'author',
        d: 'dye',
        m: 123,
        p: 'parent',
        t: 'text',
        c: {'cardKey': 'cardValue'},
        h: {'heapKey': 'heapValue'},
        l: {'logKey': DateTime.utc(2023, 5, 2)},
        j: {'junkKey': DateTime.utc(2023, 5, 3)},
        q: {'quickKey': 'quickValue'},
        x: {kGoogleCalendarTokenKey: 'googleToken'},
        s: DateTime.utc(2023, 5, 4),
        e: DateTime.utc(2023, 5, 5),
        f: DateTime.utc(2023, 5, 6),
        u: DateTime.utc(2023, 5, 7),
        w: DateTime.utc(2023, 5, 8),
        b: DateTime.utc(2023, 5, 9),
        o: true,
        i: 10,
      );

      final json = moji.toJson();

      expect(json['a'], 'author');
      expect(json['d'], 'dye');
      expect(json['m'], 123);
      expect(json['p'], 'parent');
      expect(json['t'], 'text');
      expect(json['c'], {'cardKey': 'cardValue'});
      expect(json['h'], {'heapKey': 'heapValue'});
      expect(json['l'], {'logKey': DateTime.utc(2023, 5, 2).millisecondsSinceEpoch});
      expect(json['j'], {'junkKey': DateTime.utc(2023, 5, 3).millisecondsSinceEpoch});
      expect(json['q'], {'quickKey': 'quickValue'});
      expect(json['x'], {kGoogleCalendarTokenKey: 'googleToken'});
      expect(json['s'], DateTime.utc(2023, 5, 4).millisecondsSinceEpoch);
      expect(json['e'], DateTime.utc(2023, 5, 5).millisecondsSinceEpoch);
      expect(json['f'], DateTime.utc(2023, 5, 6).millisecondsSinceEpoch);
      expect(json['u'], DateTime.utc(2023, 5, 7).millisecondsSinceEpoch);
      expect(json['w'], DateTime.utc(2023, 5, 8).millisecondsSinceEpoch);
      expect(json['b'], DateTime.utc(2023, 5, 9).millisecondsSinceEpoch);
      expect(json['o'], true);
      expect(json['i'], 10);
    });
  });
}
