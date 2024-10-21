import 'package:mojikit/mojikit.dart';
import 'package:signals/signals.dart';

enum MojiDockTile implements Comparable<MojiDockTile> {
  r(mcp: 1602),
  o(mcp: 509),
  g(mcp: 4018),
  t(mcp: 3813),
  b(mcp: 1949),
  i(mcp: 3898),
  p(mcp: 1367),
  c(mcp: 3588);

  const MojiDockTile({required int mcp}) : _mcp = mcp;
  final int _mcp;

  int get mcp => _mcp;
  Computed<Dye> get dye {
    switch (this) {
      case MojiDockTile.r:
        return Dyes.red;
      case MojiDockTile.o:
        return Dyes.orange;
      case MojiDockTile.g:
        return Dyes.green;
      case MojiDockTile.t:
        return Dyes.teal;
      case MojiDockTile.b:
        return Dyes.blue;
      case MojiDockTile.i:
        return Dyes.indigo;
      case MojiDockTile.p:
        return Dyes.pink;
      case MojiDockTile.c:
        return Dyes.chestnut;
    }
  }

  @override
  String toString() {
    return name;
  }

  @override
  int compareTo(MojiDockTile other) => name.compareTo(other.name);

  static MojiDockTile fromString(String? mojiDockTileName) {
    switch (mojiDockTileName) {
      case 'r':
        return MojiDockTile.r;
      case 'o':
        return MojiDockTile.o;
      case 'g':
        return MojiDockTile.g;
      case 't':
        return MojiDockTile.t;
      case 'b':
        return MojiDockTile.b;
      case 'i':
        return MojiDockTile.i;
      case 'p':
        return MojiDockTile.p;
      case 'c':
        return MojiDockTile.c;
      default:
        return MojiDockTile.r;
    }
  }
}
