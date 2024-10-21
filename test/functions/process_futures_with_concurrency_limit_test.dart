import 'package:flutter_test/flutter_test.dart';
import 'package:mojikit/mojikit.dart';

void main() {
  group('processFuturesWithConcurrencyLimit tests', () {
    test('processFuturesWithConcurrencyLimit processes all futures with correct results', () async {
      final futures = List<Future<(bool, String)> Function()>.generate(5, (index) {
        return () async {
          await Future.delayed(Duration(milliseconds: 100));
          return (true, 'result_$index');
        };
      });

      final results = await processFuturesWithConcurrencyLimit(futures, concurrencyLimit: 2);

      expect(results.length, 5);
      for (int i = 0; i < 5; i++) {
        expect(results[i], (true, 'result_$i'));
      }
    });

    test('processFuturesWithConcurrencyLimit respects concurrency limit', () async {
      final futuresStarted = <int>[];
      final futures = List<Future<(bool, String)> Function()>.generate(5, (index) {
        return () async {
          futuresStarted.add(index);
          await Future.delayed(Duration(milliseconds: 100));
          return (true, 'result_$index');
        };
      });

      await processFuturesWithConcurrencyLimit(futures, concurrencyLimit: 2);

      // Ensure only up to 2 futures are running concurrently
      for (int i = 0; i < futuresStarted.length - 2; i++) {
        final startedFutures = futuresStarted.sublist(i, i + 3).toSet().length;
        expect(startedFutures <= 3, isTrue);
      }
    });

    test('processFuturesWithConcurrencyLimit handles empty list of futures', () async {
      final futures = <Future<(bool, String)> Function()>[];

      final results = await processFuturesWithConcurrencyLimit(futures, concurrencyLimit: 2);

      expect(results, isEmpty);
    });

    test('processFuturesWithConcurrencyLimit handles errors gracefully', () async {
      final futures = [
        () async {
          await Future.delayed(Duration(milliseconds: 100));
          return (true, 'success');
        },
        () async {
          await Future.delayed(Duration(milliseconds: 100));
          throw Exception('Test error');
        },
        () async {
          await Future.delayed(Duration(milliseconds: 100));
          return (true, 'another success');
        },
      ];

      final results = await processFuturesWithConcurrencyLimit(futures, concurrencyLimit: 2);

      expect(results.length, 2);
      expect(results, contains((true, 'success')));
      expect(results, contains((true, 'another success')));
    });
  });
}
