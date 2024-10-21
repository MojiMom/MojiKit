import 'dart:math';
import 'package:mojikit/mojikit.dart';

List<FlexibleMojiEvent> calculateFlexibility(List<Moji> mojis, double mojiPlannerWidth) {
  mojiPlannerWidth -= (kMojiHoursIndicatorWidth * 2 + kMojiPlannerPadding);
  final flexibleEvents = mojis.map((moji) => FlexibleMojiEvent(moji)).toList();

  final flexibleEventPoints = flexibleEvents.expand((event) {
    final sTime = event.moji.s?.toUtc();
    final eTime = event.moji.e?.toUtc();
    if (sTime != null && eTime != null) {
      return [
        (time: sTime, event: event, isStart: true),
        (time: eTime, event: event, isStart: false),
      ];
    }
    return <({DateTime time, FlexibleMojiEvent event, bool isStart})>[];
  }).toList()
    ..sort((a, b) => a.time == b.time ? (a.isStart ? 1 : -1) : a.time.compareTo(b.time));

  final activeFlexibleEvents = <FlexibleMojiEvent>{};
  Set<FlexibleMojiEvent> currentFlexibleEvents = <FlexibleMojiEvent>{};
  final neighbourhood = <Set<FlexibleMojiEvent>>[];

  for (final point in flexibleEventPoints) {
    if (point.isStart) {
      for (final activeEvent in activeFlexibleEvents) {
        point.event.neigbouringEvents[activeEvent.moji.id] = activeEvent;
        activeEvent.neigbouringEvents[point.event.moji.id] = point.event;
      }
      activeFlexibleEvents.add(point.event);
      currentFlexibleEvents.add(point.event);
    } else {
      activeFlexibleEvents.remove(point.event);
      if (activeFlexibleEvents.isEmpty && currentFlexibleEvents.isNotEmpty) {
        neighbourhood.add(currentFlexibleEvents);
        currentFlexibleEvents = {};
      }
    }

    for (final event in activeFlexibleEvents) {
      event.maxNeighbours = max(event.maxNeighbours, activeFlexibleEvents.length);
    }
  }

  if (currentFlexibleEvents.isNotEmpty) neighbourhood.add(currentFlexibleEvents);

  for (final neighbours in neighbourhood) {
    final maxNeighbours = neighbours.map((e) => e.maxNeighbours).reduce(max);
    final flexibleWidth = mojiPlannerWidth / maxNeighbours;

    final sortedEvents = neighbours.toList()
      ..sort((a, b) {
        final aStart = a.moji.s;
        final bStart = b.moji.s;

        if (aStart == null || bStart == null) {
          return 0;
        }

        final startComparison = aStart.compareTo(bStart);
        if (startComparison != 0) {
          return startComparison;
        }

        final aEnd = a.moji.e;
        final bEnd = b.moji.e;

        if (aEnd != null && bEnd != null) {
          return bEnd.difference(bStart).compareTo(aEnd.difference(aStart));
        }

        return 0;
      });

    for (final event in sortedEvents) {
      event.flexibleWidth = flexibleWidth;
      final usedIndexes = event.neigbouringEvents.values.where((e) => e.index != null).map((e) => e.index ?? 0).toSet();

      event.index = Iterable<int?>.generate(maxNeighbours).firstWhere((i) => !usedIndexes.contains(i), orElse: () => null);
    }
  }

  return flexibleEvents;
}
