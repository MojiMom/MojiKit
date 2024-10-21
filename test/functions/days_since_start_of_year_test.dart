import 'package:flutter_test/flutter_test.dart';
import 'package:mojikit/functions/days_since_start_of_year.dart';

void main() {
  test('daysSinceStartOfYear', () {
    final now = DateTime.now();
    for (var i = 0; i < 365; i++) {
      final dDate = DateTime.utc(now.year).add(Duration(days: i));
      final result = daysSinceStartOfYear(dDate);
      expect(result, i);
      for (var j = 0; j < 24; j++) {
        final dhDate = dDate.add(Duration(hours: j));
        final result = daysSinceStartOfYear(dhDate);
        expect(result, i);
        for (var k = 0; k < 60; k++) {
          final dmDate = dhDate.add(Duration(minutes: k));
          final result = daysSinceStartOfYear(dmDate);
          expect(result, i);
        }
      }
    }
  });
}
