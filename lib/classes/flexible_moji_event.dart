import 'package:mojikit/mojikit.dart';

class FlexibleMojiEvent {
  final Moji moji;
  int? index;
  int maxNeighbours = 1;
  double flexibleWidth = 0;
  final Map<String, FlexibleMojiEvent> neigbouringEvents = {};
  FlexibleMojiEvent(this.moji);
}
