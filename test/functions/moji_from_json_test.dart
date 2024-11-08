import 'package:flutter_test/flutter_test.dart';
import 'package:mojikit/mojikit.dart';

void main() {
  group('mojiFromJson tests', () {
    test('mojiFromJson correctly converts JSON to Moji object', () {
      final json = {
        'a': 'author',
        'd': 'dye',
        'm': 'brain-02-stroke-rounded.svg',
        'p': 'parent',
        't': 'text',
        'c': {'cardKey': 'cardValue'},
        'h': {'heapKey': 'heapValue'},
        'l': {'logKey': 1683004800000},
        'j': {'junkKey': 1683091200000},
        'q': {'quickKey': 'quickValue'},
        'x': {kGoogleCalendarTokenKey: 'googleToken'},
        's': 1683177600000,
        'e': 1683264000000,
        'f': 1683350400000,
        'u': 1683436800000,
        'w': 1683523200000,
        'b': 1683524200000,
        'o': true,
        'i': 10,
      };

      final moji = mojiFromJson('documentID', json);

      expect(moji.id, 'documentID');
      expect(moji.a, 'author');
      expect(moji.d, 'dye');
      expect(moji.m, 'brain-02-stroke-rounded.svg');
      expect(moji.p, 'parent');
      expect(moji.t, 'text');
      expect(moji.c['cardKey'], 'cardValue');
      expect(moji.h['heapKey'], 'heapValue');
      expect(moji.l['logKey'], DateTime.fromMillisecondsSinceEpoch(1683004800000, isUtc: true));
      expect(moji.j['junkKey'], DateTime.fromMillisecondsSinceEpoch(1683091200000, isUtc: true));
      expect(moji.q['quickKey'], 'quickValue');
      expect(moji.x, {kGoogleCalendarTokenKey: 'googleToken'});
      expect(moji.s, DateTime.fromMillisecondsSinceEpoch(1683177600000, isUtc: true));
      expect(moji.e, DateTime.fromMillisecondsSinceEpoch(1683264000000, isUtc: true));
      expect(moji.f, DateTime.fromMillisecondsSinceEpoch(1683350400000, isUtc: true));
      expect(moji.u, DateTime.fromMillisecondsSinceEpoch(1683436800000, isUtc: true));
      expect(moji.w, DateTime.fromMillisecondsSinceEpoch(1683523200000, isUtc: true));
      expect(moji.b, DateTime.fromMillisecondsSinceEpoch(1683524200000, isUtc: true));
      expect(moji.o, true);
      expect(moji.i, 10);
    });

    test('mojiFromJson handles null values correctly', () {
      final json = {
        'a': null,
        'd': null,
        'm': null,
        'p': null,
        't': null,
        'c': null,
        'h': null,
        'l': null,
        'j': null,
        'q': null,
        'x': null,
        's': null,
        'e': null,
        'f': null,
        'u': null,
        'w': null,
        'b': null,
        'o': null,
        'i': null,
      };

      final moji = mojiFromJson('documentID', json);

      expect(moji.id, 'documentID');
      expect(moji.a, isNull);
      expect(moji.d, isNull);
      expect(moji.m, isNull);
      expect(moji.p, isNull);
      expect(moji.t, isNull);
      expect(moji.c, isEmpty);
      expect(moji.h, isEmpty);
      expect(moji.l, isEmpty);
      expect(moji.j, isEmpty);
      expect(moji.q, isEmpty);
      expect(moji.x, isEmpty);
      expect(moji.s, isNull);
      expect(moji.e, isNull);
      expect(moji.f, isNull);
      expect(moji.u, isNull);
      expect(moji.w, isNull);
      expect(moji.b, isNull);
      expect(moji.o, isNull);
      expect(moji.i, isNull);
    });
  });
}
