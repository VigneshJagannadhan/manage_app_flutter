import 'package:flutter/material.dart';
import 'package:huddle/core/extensions/build_context_theme_extensions.dart';
import 'package:huddle/core/extensions/date_time_extensions.dart';
import 'package:huddle/core/resources/app_strings.dart';
import 'package:huddle/core/services/navigation_service.dart';
import 'package:huddle/features/shared/widgets/app_bottom_sheet.dart';
import 'package:huddle/features/shared/widgets/text/label_text.dart';
import 'package:huddle/features/shared/widgets/text/title_text.dart';
import 'package:huddle/features/task/widgets/task_date_indicator.dart';

/// Full calendar reached by swiping [TaskDateCarousel] in either direction - lets
/// the user jump to any date back to the account's creation date, one month at a
/// time, instead of only paging a week at a time in the carousel itself.
class TaskCalendarSheet {
  const TaskCalendarSheet._();

  static Future<void> show(
    BuildContext context, {
    required DateTime selectedDate,
    required DateTime accountCreatedDate,
    required Set<DateTime> datesWithPendingTasks,
    required ValueChanged<DateTime> onDateSelected,
  }) {
    return AppBottomSheet.show<void>(
      context,
      title: AppStrings.calendar,
      icon: Icons.calendar_month_rounded,
      body: _TaskCalendarSheetBody(
        selectedDate: selectedDate,
        accountCreatedDate: accountCreatedDate,
        datesWithPendingTasks: datesWithPendingTasks,
        onDateSelected: onDateSelected,
      ),
    );
  }
}

class _TaskCalendarSheetBody extends StatefulWidget {
  const _TaskCalendarSheetBody({
    required this.selectedDate,
    required this.accountCreatedDate,
    required this.datesWithPendingTasks,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final DateTime accountCreatedDate;
  final Set<DateTime> datesWithPendingTasks;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<_TaskCalendarSheetBody> createState() => _TaskCalendarSheetBodyState();
}

class _TaskCalendarSheetBodyState extends State<_TaskCalendarSheetBody> {
  late DateTime _visibleMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);

  DateTime get _earliestMonth => DateTime(widget.accountCreatedDate.year, widget.accountCreatedDate.month);

  bool get _canGoToPreviousMonth => _visibleMonth.isAfter(_earliestMonth);

  void _goToPreviousMonth() {
    if (!_canGoToPreviousMonth) return;
    setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1));
  }

  void _goToNextMonth() {
    setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1));
  }

  void _selectDate(DateTime date) {
    widget.onDateSelected(date);
    navigationService.pop(context);
  }

  /// One cell per grid slot for [month], Monday-first; `null` pads the leading/
  /// trailing slots that fall outside the month so every row stays 7 wide.
  List<DateTime?> _monthCells(DateTime month) {
    final firstOfMonth = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = (firstOfMonth.weekday - DateTime.monday) % 7;
    final totalCells = leadingBlanks + daysInMonth;
    final trailingBlanks = (7 - totalCells % 7) % 7;

    return [
      ...List<DateTime?>.filled(leadingBlanks, null),
      for (var day = 1; day <= daysInMonth; day++) DateTime(month.year, month.month, day),
      ...List<DateTime?>.filled(trailingBlanks, null),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final cells = _monthCells(_visibleMonth);
    final accountCreatedDate = widget.accountCreatedDate;
    // A square grid cell (the delegate's default) isn't tall enough for the day
    // circle plus the pending-task dot below it - size cells to fit that content
    // instead of the cell's width.
    final cellHeight = theme.controlHeight * 0.72 + theme.spacingXSmall * 2 + 6;
    final rowCount = (cells.length / 7).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              color: colorScheme.onSurfaceVariant,
              tooltip: 'Previous month',
              onPressed: _canGoToPreviousMonth ? _goToPreviousMonth : null,
            ),
            Expanded(child: TitleText.small(_visibleMonth.monthYearLabel, textAlign: TextAlign.center)),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              color: colorScheme.onSurfaceVariant,
              tooltip: 'Next month',
              onPressed: _goToNextMonth,
            ),
          ],
        ),
        SizedBox(height: theme.spacingMedium),
        Row(
          children: [
            for (final letter in kWeekdayInitials)
              Expanded(child: Center(child: LabelText.small(letter, color: colorScheme.onSurfaceVariant))),
          ],
        ),
        SizedBox(height: theme.spacingSmall),
        // A bounded SizedBox (rather than Expanded, which needs an ancestor that
        // hands down a fixed height) lets this grid sit inside the bottom sheet's
        // content column, which sizes itself to fit its children.
        SizedBox(
          height: rowCount * cellHeight,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisExtent: cellHeight),
            itemCount: cells.length,
            itemBuilder: (context, index) {
              final date = cells[index];
              if (date == null) return const SizedBox.shrink();

              return _CalendarDayCell(
                date: date,
                selected: date.isSameDate(widget.selectedDate),
                hasPendingTask: widget.datesWithPendingTasks.contains(date),
                enabled: !date.isBefore(accountCreatedDate),
                onTap: () => _selectDate(date),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.selected,
    required this.hasPendingTask,
    required this.enabled,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool hasPendingTask;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: hasPendingTask ? '${date.day}, has pending tasks' : '${date.day}',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(theme.appBorderRadius),
          onTap: enabled ? onTap : null,
          child: TaskDateIndicator(
            date: date,
            selected: selected,
            hasPendingTask: hasPendingTask,
            circleSize: theme.controlHeight * 0.72,
            enabled: enabled,
          ),
        ),
      ),
    );
  }
}
