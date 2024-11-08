import 'package:mojikit/mojikit.dart';
import 'package:signals/signals.dart';

enum MojiDockTile implements Comparable<MojiDockTile> {
  r(svg: 'google-doc-stroke-rounded.svg'),
  o(svg: 'brain-02-stroke-rounded.svg'),
  g(svg: 'wellness-stroke-rounded.svg'),
  t(svg: 'tv-01-stroke-rounded.svg'),
  b(svg: 'laptop-programming-stroke-rounded.svg'),
  i(svg: 'user-multiple-02-stroke-rounded.svg'),
  p(svg: 'favourite-stroke-rounded.svg'),
  c(svg: 'task-01-stroke-rounded.svg');

  const MojiDockTile({required String svg}) : _svg = svg;
  final String _svg;

  String get svg => _svg;
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
