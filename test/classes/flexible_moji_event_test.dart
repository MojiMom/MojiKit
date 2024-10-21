import 'package:mojikit/mojikit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlexibleMojiEvent tests', () {
    test('FlexibleMojiEvent initializes with correct default values', () {
      final moji = Moji('testId');
      final event = FlexibleMojiEvent(moji);

      expect(event.moji.id, 'testId');
      expect(event.index, isNull);
      expect(event.maxNeighbours, 1);
      expect(event.flexibleWidth, 0);
      expect(event.neigbouringEvents, isEmpty);
    });

    test('FlexibleMojiEvent can add neighbouring events', () {
      final moji1 = Moji('moji1');
      final moji2 = Moji('moji2');
      final event1 = FlexibleMojiEvent(moji1);
      final event2 = FlexibleMojiEvent(moji2);

      event1.neigbouringEvents['moji2'] = event2;

      expect(event1.neigbouringEvents.length, 1);
      expect(event1.neigbouringEvents['moji2'], equals(event2));
    });
  });
}
