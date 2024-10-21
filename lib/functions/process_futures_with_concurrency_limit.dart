import 'dart:async';
import 'dart:collection';

Future<List<(bool, String)>> processFuturesWithConcurrencyLimit<T>(
  List<Future<(bool, String)> Function()> futures, {
  required int concurrencyLimit,
}) async {
  final queue = Queue<Future<(bool, String)> Function()>.from(futures);
  final results = <(bool, String)>[];
  final completer = Completer<List<(bool, String)>>();
  var activeCount = 0;

  void startNext() {
    if (queue.isEmpty && activeCount == 0) {
      completer.complete(results);
      return;
    }

    while (activeCount < concurrencyLimit && queue.isNotEmpty) {
      activeCount++;
      final future = queue.removeFirst();
      future().then((value) {
        results.add(value);
        activeCount--;
        startNext();
      }).catchError((error) {
        activeCount--;
        startNext();
        // Handle or rethrow error as needed
      });
    }
  }

  startNext();
  return completer.future;
}
