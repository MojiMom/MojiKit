import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:forui/forui.dart';
import 'package:signals/signals_flutter.dart';
import 'package:signals/signals_flutter_extended.dart';
import 'package:undo/undo.dart';
import 'package:mojikit/mojikit.dart';
import 'package:duration_picker/duration_picker.dart';

class MojiIntervalPicker extends StatefulWidget {
  final Dye dye;
  final String mid;
  final double mojiPlannerWidth;
  const MojiIntervalPicker({required this.mid, required this.mojiPlannerWidth, required this.dye, super.key});

  @override
  MojiIntervalPickerState createState() => MojiIntervalPickerState();
}

class MojiIntervalPickerState extends State<MojiIntervalPicker> {
  // Moji before changes
  late final _mojiR = S.mojiSignal(widget.mid);

  late final _interval = computed(() {
    final moji = _mojiR.value;
    final intervalPickerState = S.intervalPickerState.value;
    final startTime = moji.s?.toLocal();
    final endTime = moji.e?.toLocal();
    switch (intervalPickerState) {
      case IntervalPickerState.start:
        return (startTime?.hour ?? 0) * 60 + (startTime?.minute ?? 0);
      case IntervalPickerState.end:
        return (endTime?.hour ?? 0) * 60 + (endTime?.minute ?? 0);
      default:
        return endTime?.difference(startTime ?? U.zeroDateTime).inMinutes ?? moji.i ?? kDefaultMojiEventDuration.inMinutes;
    }
  });

  Moji? mojiBC;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        colorScheme: ColorScheme.dark(
          secondary: widget.dye.darker,
          surface: widget.dye.ultraDark.withValues(alpha: 0.05),
          primary: widget.dye.extraLight,
        ),
        textTheme: Typography.blackMountainView.copyWith(
          bodyMedium: TextStyle(color: widget.dye.extraDark),
          titleMedium: TextStyle(color: widget.dye.ultraDark),
        ),
      ),
      child: Listener(
        onPointerDown: (event) {
          // Get the current moji before changes
          mojiBC = R.getMoji(widget.mid).copyWith();
        },
        onPointerUp: (event) {
          // Get the current moji before changes
          final mojiBC = this.mojiBC;
          // If it's not null
          if (mojiBC != null) {
            // Update the moji
            R.syncLocalUnwrittenMojis(mojiIDs: {mojiBC.id});
            // Create a new list of mojis
            final mojiLBC = <Moji>[mojiBC];
            // Track the change so that it can be undoed
            U.mojiChanges.add(
              Change<List<Moji>>(
                mojiLBC,
                () {},
                // On undo
                (mojiLBC) {
                  // Update the mojis before changes
                  R.updateMojis(mojiLBC);
                  // Sync the unwritten mojis
                  R.syncLocalUnwrittenMojis(mojiIDs: mojiLBC.map((moji) => moji.id).toSet());
                  // Force a state reset for the duration picker
                  this.mojiBC = U.emptyMoji;
                  // After the state has been reset
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    // Force another state reset
                    // Where the moji before changes now is the moji which got restored
                    this.mojiBC = R.getMoji(widget.mid);
                  });
                },
              ),
            );
          }
        },
        child: Watch((context) {
          final interval = _interval.value;
          final mojiR = _mojiR.value;
          final mojiIntervalPickerState = S.intervalPickerState.value;
          return Stack(
            children: [
              DurationPicker(
                key: ValueKey('${widget.mid}:$mojiIntervalPickerState'),
                height: double.maxFinite,
                width: double.maxFinite,
                duration: Duration(minutes: interval),
                onChange: (Duration newDuration) {
                  var round = (newDuration.inMinutes / 5).round() * 5;
                  if (interval != round) {
                    HapticFeedback.lightImpact();

                    final sTime = R.m.write<DateTime?>(() {
                      Duration eventDuration = Duration.zero;
                      final sTime = mojiR.s?.toLocal();
                      final eTime = mojiR.e?.toLocal();
                      if (sTime != null && eTime != null) {
                        switch (mojiIntervalPickerState) {
                          case IntervalPickerState.duration:
                            final newEndTime = sTime.add(Duration(minutes: round));
                            if (newEndTime.isAfter(sTime) && newEndTime.day == sTime.day) {
                              mojiR.e = newEndTime.toUtc();
                            }
                          case IntervalPickerState.start:
                            final newStartTime = DateTime(sTime.year, sTime.month, sTime.day).add(Duration(minutes: round));
                            if (newStartTime.isBefore(eTime) &&
                                newStartTime.toLocal().day == sTime.day &&
                                eTime.difference(newStartTime).inMinutes >= kMinMojiEventDuration.inMinutes) {
                              mojiR.s = newStartTime.toUtc();
                            }
                          case IntervalPickerState.end:
                            final newEndTime = DateTime(sTime.year, sTime.month, sTime.day).add(Duration(minutes: round));
                            if (newEndTime.isAfter(sTime) && newEndTime.day == sTime.toLocal().day) {
                              mojiR.e = newEndTime.toUtc();
                            }
                          default:
                        }
                        eventDuration = mojiR.e?.difference(mojiR.s ?? U.zeroDateTime) ?? Duration.zero;
                      }

                      if (eventDuration.inMinutes <= 0) {
                        mojiR.i = round;
                      }
                      mojiR.w = U.zeroDateTime;
                      return mojiR.s?.toUtc();
                    });
                    if (sTime != null) {
                      final (did, flexibleMojiEvents) = U.getFlexibleMojiEventsForDay(sTime, widget.mojiPlannerWidth);
                      // Update the value of the moji planner notifier if it exists
                      U.mojiPlannersNotifiers[did]?.value = (flexibleMojiEvents, DateTime.now().millisecondsSinceEpoch);
                    }
                  }
                },
              ),
              Visibility(
                visible: mojiIntervalPickerState == IntervalPickerState.start || mojiIntervalPickerState == IntervalPickerState.end,
                child: Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      R.deleteMojiFromPlanner(widget.mid);
                      R.updateMoji(widget.mid, npid: mojiR.p);
                      batch(() {
                        S.intervalPickerState.set(IntervalPickerState.none);
                        S.implicitMojiDockTile.set(S.selectedMojiDockTile.untrackedValue);
                        S.implicitPID.set(S.selectedPID.untrackedValue);
                        S.shouldAddChildMoji.set(false);
                        S.fCalendarController.set(FCalendarController.date());
                        S.selectedMID.set(kEmptyString);
                        S.pinnedMID.set(kEmptyString);
                        S.shouldShowMojiPicker.set(false);
                        S.linkingCalendar.set(kEmptyString);
                      });
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: Watch((context) {
                          return SvgPicture.asset(
                            'assets/hugeicons/property-delete-stroke-rounded.svg',
                            colorFilter: ColorFilter.mode(widget.dye.darker, BlendMode.srcIn),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
