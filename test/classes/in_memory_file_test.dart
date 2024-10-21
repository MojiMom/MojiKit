import 'package:flutter_test/flutter_test.dart';
import 'package:mojikit/mojikit.dart';

void main() {
  group('InMemoryFile tests', () {
    test('readAsStringSync returns correct contents', () {
      final file = InMemoryFile('This is a test content.');
      final result = file.readAsStringSync();

      expect(result, 'This is a test content.');
    });

    test('noSuchMethod should throw for unimplemented methods', () {
      final file = InMemoryFile('This is a test content.');

      expect(() => file.readAsBytesSync(), throwsNoSuchMethodError);
    });
  });
}
