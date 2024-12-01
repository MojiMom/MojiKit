import 'package:mojikit/mojikit.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:signals/signals_flutter.dart';
import 'package:signals/signals_flutter_extended.dart';

class E {
  static void setupSelectedMojiIdEffect() {
    effect(() {
      final cMID = S.selectedMID.value;
      final oMID = S.selectedMID.previousValue;
      if (cMID != null && cMID != oMID && cMID.isEmpty) {
        final cMojiDT = S.selectedMojiDockTile.untrackedValue;
        S.implicitMojiDockTile.set(cMojiDT);
      }
    });
  }

  static void setupSelectedMojiDockTileEffect() {
    effect(() {
      final cMojiDT = S.selectedMojiDockTile.value;
      final oMojiDT = S.selectedMojiDockTile.previousValue;
      if (cMojiDT != oMojiDT) {
        if (cMojiDT != null) {
          final existingPreferences = S.preferencesSignal(kLocalPreferences).untrackedValue;
          if (existingPreferences.id.isNotEmpty) {
            R.p.write(() {
              existingPreferences.selectedMojiDockTileName = cMojiDT.name;
            });
          }
        }
      }
    });
  }

  static void setupImplicitMojiDockTileEffect() {
    effect(() {
      final cMojiDT = S.implicitMojiDockTile.value;
      if (cMojiDT != null) {
        U.mojiDockTileASC.scrollToIndex(
          cMojiDT.index,
          preferPosition: AutoScrollPosition.middle,
          duration: const Duration(milliseconds: 400),
        );
      }
    });
  }
}
