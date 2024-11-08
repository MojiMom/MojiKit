import 'package:duration/duration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:mojikit/mojikit.dart';
import 'package:signals/signals_flutter.dart';

class MojiToolbar extends StatefulWidget {
  final String mojiId;
  const MojiToolbar({required this.mojiId, super.key});

  @override
  State<MojiToolbar> createState() => _MojiToolbarState();
}

class _MojiToolbarState extends State<MojiToolbar> {
  late final _mojiR = S.mojiSignal(widget.mojiId);
  late final _result = computed(() {
    final mojiR = _mojiR.value;
    if (mojiR.id.isEmpty) return null;
    final recalculateMojiTilesAt = S.recalculateMojiTilesAt.value;
    final mojiDockTileAndParents = R.getMojiDockTileAndParents(mojiR);
    final mojiTileParents = mojiDockTileAndParents.$2.where((p) => p.m != null).toList();
    // If the moji itself is a tile
    if (mojiR.m != null) {
      // Add it to the list
      mojiTileParents.add(mojiR);
    }
    final mojiDT = mojiDockTileAndParents.$1;
    final dye = mojiDT.dye.value;
    return (mojiDockTileAndParents, mojiTileParents, dye, recalculateMojiTilesAt);
  });

  late final _durationString = computed(() {
    final mojiR = _mojiR.value;
    String? durationString;
    if (mojiR.id.isNotEmpty) {
      final interval = mojiR.i ?? kDefaultMojiEventDuration.inMinutes;
      durationString = prettyDuration(
        Duration(minutes: interval),
        abbreviated: true,
        delimiter: kEmptyString,
        spacer: kEmptyString,
      );
      final eTime = mojiR.e?.toUtc();
      final sTime = mojiR.s?.toUtc();
      if (eTime != null && sTime != null) {
        durationString = prettyDuration(
          eTime.difference(sTime),
          abbreviated: true,
          delimiter: kEmptyString,
          spacer: kEmptyString,
        );
      }
    }
    return durationString;
  });

  late final _dayString = computed(() {
    String text;
    final mojiR = _mojiR.value;
    final sTime = mojiR.s?.toUtc();
    final now = DateTime.now();
    if (sTime == null || (sTime.year == now.year && sTime.month == now.month && sTime.day == now.day)) {
      text = 'today';
    } else {
      text = DateFormat('MMM d').format(sTime);
    }
    return text;
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: SizedBox(
        height: 30,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  final shouldShowMojiPicker = untracked(() => S.shouldShowMojiPicker.value) == true;
                  final mojiR = _mojiR.value;
                  batch(() {
                    S.selectedMID.set(mojiR.id);
                    S.shouldShowMojiPicker.set(!shouldShowMojiPicker);
                    S.fCalendarController.set(FCalendarController.date());
                  });
                },
                child: Watch((context) {
                  final shouldShowMojiPicker = S.shouldShowMojiPicker.value;
                  final dye = _result.value?.$3 ?? Dyes.grey.value;
                  return AnimatedContainer(
                    curve: Curves.ease,
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      color: dye.light,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        width: 1.5,
                        color: shouldShowMojiPicker ? dye.dark : dye.light,
                      ),
                    ),
                    margin: const EdgeInsets.only(right: 5.0),
                    padding: const EdgeInsets.only(left: 5, right: 5),
                    child: Watch((context) {
                      final mojiTileParents = _result.value?.$2;
                      if (mojiTileParents == null) return const SizedBox.shrink();
                      return ListView.separated(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          final pMoji = mojiTileParents[index];
                          return Watch(
                            (context) {
                              final dye = _result.value?.$3 ?? Dyes.grey.value;
                              return SvgPicture.asset(
                                'assets/hugeicons/${pMoji.m}',
                                colorFilter: ColorFilter.mode(dye.ultraDark, BlendMode.srcIn),
                                width: 17,
                                height: 17,
                              );
                            },
                          );
                        },
                        separatorBuilder: (context, index) {
                          return const SizedBox(width: 5);
                        },
                        itemCount: mojiTileParents.length,
                      );
                    }),
                  );
                }),
              ),
              GestureDetector(
                key: ValueKey(IntervalPickerState.duration),
                onTap: () {
                  final shouldToggleIntervalPicker = untracked(() => S.intervalPickerState.value) == IntervalPickerState.duration;
                  batch(() {
                    if (shouldToggleIntervalPicker) {
                      S.intervalPickerState.set(IntervalPickerState.none);
                    } else {
                      S.intervalPickerState.set(IntervalPickerState.duration);
                    }
                    S.shouldShowMojiPicker.set(false);
                    S.selectedHeaderView.set(MMHeaderView.plan);
                    S.fCalendarController.set(FCalendarController.date());
                  });
                },
                child: Watch((context) {
                  final dye = _result.value?.$3;
                  return Container(
                    constraints: const BoxConstraints(minWidth: 45),
                    decoration: BoxDecoration(
                      color: dye?.light,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    margin: const EdgeInsets.only(left: 5.0, right: 5.0),
                    padding: const EdgeInsets.only(left: 5, right: 5),
                    child: Center(
                      child: Watch(
                        (context) {
                          final dye = _result.value?.$3;
                          final durationString = _durationString.value;
                          if (durationString == null) return const SizedBox.shrink();
                          return Text(
                            durationString.replaceAll('min', 'm'),
                            style: TextStyle(
                              fontFamily: kDefaultFontFamily,
                              fontFamilyFallback: const [kUnicodeMojiFamily],
                              color: dye?.ultraDark,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }),
              ),
              GestureDetector(
                onTap: () {
                  final existingDateController = untracked(() => S.fCalendarController.value);
                  if (existingDateController?.value != null) {
                    batch(() {
                      S.fCalendarController.set(FCalendarController.date());
                      S.intervalPickerState.set(IntervalPickerState.none);
                      S.shouldShowMojiPicker.set(false);
                      S.shouldAddChildMoji.set(false);
                    });
                  } else {
                    final now = DateTime.now();
                    final utcDay = DateTime.utc(now.year, now.month, now.day);
                    final dateController = FCalendarController.date(initialSelection: utcDay);
                    batch(() {
                      S.fCalendarController.set(dateController);
                      S.shouldShowMojiPicker.set(false);
                      S.shouldAddChildMoji.set(false);
                    });
                  }
                },
                child: Watch((context) {
                  final fCalendarController = S.fCalendarController.value;
                  final dye = _result.value?.$3 ?? Dyes.grey.value;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.ease,
                    constraints: const BoxConstraints(minWidth: 45),
                    decoration: BoxDecoration(
                      color: dye.light,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: fCalendarController?.value != null ? dye.dark : dye.light,
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.only(left: 5, right: 5),
                    margin: const EdgeInsets.only(left: 5.0, right: 5.0),
                    child: Center(
                      child: Watch((context) {
                        final dye = _result.value?.$3;
                        final text = _dayString.value;
                        return Text(
                          text,
                          style: TextStyle(
                            fontFamily: kDefaultFontFamily,
                            fontFamilyFallback: const [kUnicodeMojiFamily],
                            color: dye?.ultraDark,
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
              Watch((context) {
                final startTime = _mojiR.value.s;
                final endTime = _mojiR.value.e;
                return Visibility(
                  visible: startTime != null && endTime != null,
                  child: Watch((context) {
                    final dye = _result.value?.$3;
                    return Container(
                      constraints: const BoxConstraints(minWidth: 115),
                      decoration: BoxDecoration(color: dye?.light, borderRadius: BorderRadius.circular(5)),
                      margin: const EdgeInsets.only(left: 5.0, right: 5.0),
                      padding: const EdgeInsets.only(left: 5, right: 5),
                      child: Center(
                        child: Row(
                          children: [
                            GestureDetector(
                              key: ValueKey(IntervalPickerState.start),
                              onTap: () {
                                final shouldToggleIntervalPicker = untracked(() => S.intervalPickerState.value) == IntervalPickerState.start;
                                batch(() {
                                  if (shouldToggleIntervalPicker) {
                                    S.intervalPickerState.set(IntervalPickerState.none);
                                  } else {
                                    S.intervalPickerState.set(IntervalPickerState.start);
                                  }
                                  S.shouldShowMojiPicker.set(false);
                                  S.selectedHeaderView.set(MMHeaderView.plan);
                                  S.fCalendarController.set(FCalendarController.date());
                                });
                              },
                              child: Watch(
                                (context) {
                                  final dye = _result.value?.$3;
                                  final startTime = _mojiR.value.s?.toLocal();
                                  if (startTime == null) return const SizedBox.shrink();
                                  return Text(
                                    DateFormat('h:mm').format(startTime),
                                    style: TextStyle(
                                      fontFamily: kDefaultFontFamily,
                                      fontFamilyFallback: const [kUnicodeMojiFamily],
                                      color: dye?.ultraDark,
                                    ),
                                  );
                                },
                              ),
                            ),
                            GestureDetector(
                              key: ValueKey(IntervalPickerState.end),
                              onTap: () {
                                final shouldToggleIntervalPicker = untracked(() => S.intervalPickerState.value) == IntervalPickerState.end;
                                batch(() {
                                  if (shouldToggleIntervalPicker) {
                                    S.intervalPickerState.set(IntervalPickerState.none);
                                  } else {
                                    S.intervalPickerState.set(IntervalPickerState.end);
                                  }
                                  S.shouldShowMojiPicker.set(false);
                                  S.selectedHeaderView.set(MMHeaderView.plan);
                                  S.fCalendarController.set(FCalendarController.date());
                                });
                              },
                              child: Watch((context) {
                                return Center(
                                  child: Watch(
                                    (context) {
                                      final dye = _result.value?.$3;
                                      final endTime = _mojiR.value.e?.toLocal();
                                      if (endTime == null) return const SizedBox.shrink();
                                      return Text(
                                        ' - ${DateFormat('h:mm a').format(endTime)}',
                                        style: TextStyle(
                                          fontFamily: kDefaultFontFamily,
                                          fontFamilyFallback: const [kUnicodeMojiFamily],
                                          color: dye?.ultraDark,
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              }),
              GestureDetector(
                onTap: () {
                  final mojiR = untracked(() => _mojiR.value);
                  if (mojiR.id.isNotEmpty) {
                    R.finishMoji(mojiR.id);
                  }
                },
                child: Watch((context) {
                  final dye = _result.value?.$3 ?? Dyes.grey.value;
                  return Container(
                    constraints: const BoxConstraints(minWidth: 45),
                    decoration: BoxDecoration(
                      color: dye.light,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    margin: const EdgeInsets.only(left: 5.0, right: 5.0),
                    child: Center(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedTick04,
                        color: dye.ultraDark,
                        size: 15,
                      ),
                    ),
                  );
                }),
              ),
              GestureDetector(
                onTap: () {
                  final mojiR = untracked(() => _mojiR.value);
                  if (mojiR.p == null) return;
                  final isMojiTile = mojiR.m != null;
                  R.deleteMojis({mojiR.id});
                  batch(() {
                    S.selectedMID.set(kEmptyString);
                    S.pinnedMID.set(kEmptyString);
                    S.selectedPID.set(isMojiTile ? mojiR.p : null);
                    S.implicitPID.set(isMojiTile ? mojiR.p : null);
                  });
                },
                child: Watch((context) {
                  final dye = _result.value?.$3;
                  return Container(
                    constraints: const BoxConstraints(minWidth: 45),
                    decoration: BoxDecoration(
                      color: dye?.light,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    margin: const EdgeInsets.only(
                      left: 5.0,
                      right: 5.0,
                    ),
                    child: Center(
                      child: Watch((context) {
                        final dye = _result.value?.$3 ?? Dyes.grey.value;
                        return HugeIcon(
                          icon: HugeIcons.strokeRoundedDelete02,
                          color: dye.ultraDark,
                          size: 15,
                        );
                      }),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
