import 'package:flutter_test/flutter_test.dart';
import 'package:mojikit/mojikit.dart';

void main() {
  group('calculateFlexibility tests', () {
    test('calculateFlexibility correctly calculates widths and indexes', () {
      final mojis = [
        Moji('moji1', s: DateTime.utc(2023, 5, 1), e: DateTime.utc(2023, 5, 2)),
        Moji('moji2', s: DateTime.utc(2023, 5, 1, 12), e: DateTime.utc(2023, 5, 2)),
        Moji('moji3', s: DateTime.utc(2023, 5, 1, 18), e: DateTime.utc(2023, 5, 2)),
      ];

      final result = calculateFlexibility(mojis, 1000);

      expect(result.length, 3);
      expect(result[0].flexibleWidth, greaterThan(0));
      expect(result[0].index, isNotNull);
      expect(result[1].flexibleWidth, greaterThan(0));
      expect(result[1].index, isNotNull);
      expect(result[2].flexibleWidth, greaterThan(0));
      expect(result[2].index, isNotNull);
    });

    test('calculateFlexibility handles events with null start or end times', () {
      final mojis = [
        Moji('moji1', s: DateTime.utc(2023, 5, 1), e: DateTime.utc(2023, 5, 2)),
        Moji('moji2', s: DateTime.utc(2023, 5, 1, 12), e: null),
        Moji('moji3', s: null, e: DateTime.utc(2023, 5, 2)),
      ];

      final result = calculateFlexibility(mojis, 1000);

      expect(result.length, 3);
      expect(result[0].flexibleWidth, greaterThan(0));
      expect(result[0].index, isNotNull);
      expect(result[1].flexibleWidth, equals(0));
      expect(result[1].index, isNull);
      expect(result[2].flexibleWidth, equals(0));
      expect(result[2].index, isNull);
    });

    test('calculateFlexibility correctly handles overlapping events with same start time', () {
      final mojis = [
        Moji('moji1', s: DateTime.utc(2023, 5, 1), e: DateTime.utc(2023, 5, 3)),
        Moji('moji2', s: DateTime.utc(2023, 5, 1), e: DateTime.utc(2023, 5, 2)),
        Moji('moji3', s: DateTime.utc(2023, 5, 1), e: DateTime.utc(2023, 5, 4)),
      ];

      final result = calculateFlexibility(mojis, 1000);

      expect(result.length, 3);
      expect(result[0].flexibleWidth, greaterThan(0));
      expect(result[1].flexibleWidth, greaterThan(0));
      expect(result[2].flexibleWidth, greaterThan(0));
      expect(result[0].index, isNotNull);
      expect(result[1].index, isNotNull);
      expect(result[2].index, isNotNull);
    });
  });
}
