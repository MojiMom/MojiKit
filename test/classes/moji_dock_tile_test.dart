import 'package:flutter_test/flutter_test.dart';
import 'package:mojikit/mojikit.dart';
import 'package:realm/realm.dart';

void main() {
  setUpAll(() async {
    R.m = Realm(Configuration.local([Moji.schema], path: await U.newTestRealm()));
    R.p = Realm(Configuration.local([Preferences.schema], path: await U.newTestRealm()));
    R.online = false;
    return Future.value();
  });

  group('MojiDockTile tests', () {
    test('MojiDockTile values have correct mcp', () {
      expect(MojiDockTile.r.mcp, 1602);
      expect(MojiDockTile.o.mcp, 509);
      expect(MojiDockTile.g.mcp, 4018);
      expect(MojiDockTile.t.mcp, 3813);
      expect(MojiDockTile.b.mcp, 1949);
      expect(MojiDockTile.i.mcp, 3898);
      expect(MojiDockTile.p.mcp, 1367);
      expect(MojiDockTile.c.mcp, 3588);
    });

    test('MojiDockTile dye returns correct Dye instance', () {
      expect(MojiDockTile.r.dye.value, equals(Dyes.red.value));
      expect(MojiDockTile.o.dye.value, equals(Dyes.orange.value));
      expect(MojiDockTile.g.dye.value, equals(Dyes.green.value));
      expect(MojiDockTile.t.dye.value, equals(Dyes.teal.value));
      expect(MojiDockTile.b.dye.value, equals(Dyes.blue.value));
      expect(MojiDockTile.i.dye.value, equals(Dyes.indigo.value));
      expect(MojiDockTile.p.dye.value, equals(Dyes.pink.value));
      expect(MojiDockTile.c.dye.value, equals(Dyes.chestnut.value));
    });

    test('MojiDockTile toString returns correct name', () {
      expect(MojiDockTile.r.toString(), 'r');
      expect(MojiDockTile.o.toString(), 'o');
      expect(MojiDockTile.g.toString(), 'g');
      expect(MojiDockTile.t.toString(), 't');
      expect(MojiDockTile.b.toString(), 'b');
      expect(MojiDockTile.i.toString(), 'i');
      expect(MojiDockTile.p.toString(), 'p');
      expect(MojiDockTile.c.toString(), 'c');
    });

    test('MojiDockTile fromString returns correct MojiDockTile', () {
      expect(MojiDockTile.fromString('r'), MojiDockTile.r);
      expect(MojiDockTile.fromString('o'), MojiDockTile.o);
      expect(MojiDockTile.fromString('g'), MojiDockTile.g);
      expect(MojiDockTile.fromString('t'), MojiDockTile.t);
      expect(MojiDockTile.fromString('b'), MojiDockTile.b);
      expect(MojiDockTile.fromString('i'), MojiDockTile.i);
      expect(MojiDockTile.fromString('p'), MojiDockTile.p);
      expect(MojiDockTile.fromString('c'), MojiDockTile.c);
      expect(MojiDockTile.fromString('unknown'), MojiDockTile.r);
    });

    test('MojiDockTile compareTo compares based on name', () {
      expect(MojiDockTile.r.compareTo(MojiDockTile.o), greaterThan(0));
      expect(MojiDockTile.b.compareTo(MojiDockTile.c), lessThan(0));
      expect(MojiDockTile.t.compareTo(MojiDockTile.t), equals(0));
    });
  });
}
