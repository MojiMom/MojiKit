import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mojikit/mojikit.dart';

class MojiCalendar extends StatefulWidget {
  const MojiCalendar({required this.dye, required this.fCalendarController, required this.relativeDay, required this.mojiR, super.key});
  final Dye dye;
  final FCalendarController fCalendarController;
  final DateTime relativeDay;
  final Moji? mojiR;

  @override
  State<MojiCalendar> createState() => _MojiCalendarState();
}

class _MojiCalendarState extends State<MojiCalendar> {
  @override
  Widget build(BuildContext context) {
    return FCalendar(
      onPress: (cDate) {
        final mojiR = widget.mojiR;
        // If them moji from realm is not null
        if (mojiR != null) {
          R.changeMojiDay(cDate, mojiR);
        }
      },
      controller: widget.fCalendarController,
      start: widget.relativeDay,
      end: widget.relativeDay.add(const Duration(days: 365)),
      style: context.theme.calendarStyle.copyWith(
        decoration: BoxDecoration(
          color: widget.dye.lighter.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(15),
        ),
        dayPickerStyle: context.theme.calendarStyle.dayPickerStyle.copyWith(
          headerTextStyle: context.theme.calendarStyle.dayPickerStyle.headerTextStyle.copyWith(
            fontFamily: kDefaultFontFamily,
            color: Colors.black54,
          ),
          unselectableEnclosing: FCalendarDayStyle(
            unselectedStyle: context.theme.calendarStyle.dayPickerStyle.unselectableStyles.enclosing.unselectedStyle.copyWith(
              padding: const EdgeInsets.all(2),
              radius: const Radius.circular(6),
              backgroundColor: widget.dye.lighter,
              focusedBorderColor: widget.dye.extraDark,
              hoveredBackgroundColor: widget.dye.extraDark,
              textStyle: context.theme.calendarStyle.dayPickerStyle.unselectableStyles.enclosing.unselectedStyle.textStyle.copyWith(
                fontFamily: kDefaultFontFamily,
                color: widget.dye.medium,
                decorationColor: widget.dye.extraDark.withValues(alpha: 0.0),
              ),
            ),
            selectedStyle: context.theme.calendarStyle.dayPickerStyle.unselectableStyles.enclosing.selectedStyle.copyWith(
              padding: const EdgeInsets.all(2),
              radius: const Radius.circular(6),
              backgroundColor: widget.dye.dark,
              focusedBorderColor: widget.dye.extraDark,
              hoveredBackgroundColor: widget.dye.extraDark,
              textStyle: context.theme.calendarStyle.dayPickerStyle.unselectableStyles.enclosing.selectedStyle.textStyle.copyWith(
                fontFamily: kDefaultFontFamily,
                decorationColor: widget.dye.extraDark.withValues(alpha: 0.0),
              ),
            ),
          ),
          unselectableCurrent: FCalendarDayStyle(
            unselectedStyle: context.theme.calendarStyle.dayPickerStyle.unselectableStyles.current.unselectedStyle.copyWith(
              padding: const EdgeInsets.all(2),
              radius: const Radius.circular(6),
              backgroundColor: widget.dye.lighter,
              focusedBorderColor: widget.dye.extraDark,
              hoveredBackgroundColor: widget.dye.extraDark,
              textStyle: context.theme.calendarStyle.dayPickerStyle.unselectableStyles.current.unselectedStyle.textStyle.copyWith(
                fontFamily: kDefaultFontFamily,
                color: widget.dye.medium,
                decorationColor: widget.dye.extraDark.withValues(alpha: 0.0),
              ),
            ),
            selectedStyle: context.theme.calendarStyle.dayPickerStyle.unselectableStyles.current.selectedStyle.copyWith(
              padding: const EdgeInsets.all(2),
              radius: const Radius.circular(6),
              backgroundColor: widget.dye.dark,
              focusedBorderColor: widget.dye.extraDark,
              hoveredBackgroundColor: widget.dye.extraDark,
              textStyle: context.theme.calendarStyle.dayPickerStyle.unselectableStyles.current.selectedStyle.textStyle.copyWith(
                fontFamily: kDefaultFontFamily,
                decorationColor: widget.dye.extraDark.withValues(alpha: 0.0),
              ),
            ),
          ),
          selectableEnclosing: FCalendarDayStyle(
            unselectedStyle: context.theme.calendarStyle.dayPickerStyle.selectableStyles.current.unselectedStyle.copyWith(
              padding: const EdgeInsets.all(2),
              radius: const Radius.circular(6),
              backgroundColor: widget.dye.lighter,
              focusedBorderColor: widget.dye.extraDark,
              hoveredBackgroundColor: widget.dye.extraDark,
              textStyle: context.theme.calendarStyle.dayPickerStyle.selectableStyles.current.unselectedStyle.textStyle.copyWith(
                fontFamily: kDefaultFontFamily,
                color: widget.dye.medium,
                decorationColor: widget.dye.extraDark.withValues(alpha: 0.0),
              ),
            ),
            selectedStyle: context.theme.calendarStyle.dayPickerStyle.selectableStyles.current.selectedStyle.copyWith(
              padding: const EdgeInsets.all(2),
              radius: const Radius.circular(6),
              backgroundColor: widget.dye.dark,
              focusedBorderColor: widget.dye.extraDark,
              hoveredBackgroundColor: widget.dye.extraDark,
              textStyle: context.theme.calendarStyle.dayPickerStyle.selectableStyles.enclosing.selectedStyle.textStyle.copyWith(
                fontFamily: kDefaultFontFamily,
                color: widget.dye.extraDark,
                decorationColor: widget.dye.extraDark.withValues(alpha: 0.0),
              ),
            ),
          ),
          selectableCurrent: FCalendarDayStyle(
            unselectedStyle: context.theme.calendarStyle.dayPickerStyle.selectableStyles.current.unselectedStyle.copyWith(
              padding: const EdgeInsets.all(2),
              radius: const Radius.circular(6),
              backgroundColor: widget.dye.light,
              textStyle: context.theme.calendarStyle.dayPickerStyle.selectableStyles.current.unselectedStyle.textStyle.copyWith(
                color: widget.dye.darker,
                decorationColor: widget.dye.extraDark.withValues(alpha: 0.0),
                fontFamily: kDefaultFontFamily,
              ),
              focusedBorderColor: widget.dye.extraDark,
              hoveredBackgroundColor: widget.dye.extraDark,
            ),
            selectedStyle: context.theme.calendarStyle.dayPickerStyle.selectableStyles.current.selectedStyle.copyWith(
              padding: const EdgeInsets.all(2),
              radius: const Radius.circular(6),
              focusedBorderWidth: 1.5,
              backgroundColor: widget.dye.medium,
              textStyle: context.theme.calendarStyle.dayPickerStyle.selectableStyles.current.selectedStyle.textStyle.copyWith(
                color: widget.dye.extraDark,
                decorationColor: widget.dye.extraDark.withValues(alpha: 0.0),
                fontFamily: kDefaultFontFamily,
              ),
              focusedBorderColor: widget.dye.extraDark,
              hoveredBackgroundColor: widget.dye.extraDark,
            ),
          ),
        ),
        headerStyle: context.theme.calendarStyle.headerStyle.copyWith(
          buttonStyle: context.theme.buttonStyles.outline.copyWith(
            enabledBoxDecoration: context.theme.buttonStyles.outline.enabledBoxDecoration.copyWith(
              color: widget.dye.light,
              border: Border.all(
                color: widget.dye.medium,
                width: 1.5,
              ),
            ),
            disabledBoxDecoration: context.theme.buttonStyles.outline.enabledBoxDecoration.copyWith(
              color: widget.dye.lighter,
              border: Border.all(
                color: widget.dye.light,
                width: 1.5,
              ),
            ),
          ),
          headerTextStyle: context.theme.calendarStyle.headerStyle.headerTextStyle.copyWith(
            fontFamily: kDefaultFontFamily,
            color: Colors.black54,
          ),
          enabledIconColor: widget.dye.extraDark,
        ),
        padding: const EdgeInsets.only(top: 8),
      ),
    );
  }
}
