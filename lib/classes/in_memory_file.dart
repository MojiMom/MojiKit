import 'dart:convert';
import 'dart:io';

class InMemoryFile implements File {

  InMemoryFile(this.contents) : super();

  final String contents;

  @override
  String readAsStringSync({Encoding encoding = utf8}) {
    return contents;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}