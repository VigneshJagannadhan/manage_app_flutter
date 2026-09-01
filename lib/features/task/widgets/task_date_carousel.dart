import 'package:flutter/material.dart';
import 'package:huddle/core/extensions/build_context_theme_extensions.dart';
import 'package:huddle/core/extensions/date_time_extensions.dart';
import 'package:huddle/features/shared/widgets/text/label_text.dart';

/// Horizontal week-at-a-time day picker shown above the task list. Paging with
/// the arrow buttons moves a full week and selects the new week's first day,
/// so there's no infinite/unbounded scroll range to manage.
class TaskDateCarousel extends StatefulWidget {
  const TaskDateCarousel({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.datesWithPendingTasks,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  /// Calendar days (at midnight) to mark with a pending-task dot.
  final Set<DateTime> datesWithPendingTasks;

  @override
  State<TaskDateCarousel> createState() => _TaskDateCarouselState();
}

class _TaskDateCarouselState extends State<TaskDateCarousel> {
  late DateTime _weekStart = _startOfWeek(widget.selectedDate);

  static DateTime _startOfWeek(DateTime date) => date.atMidnight.subtract(Duration(days: date.weekday - DateTime.monday));

  void _pageWeek(int deltaWeeks) {
    final newWeekStart = _weekStart.add(Duration(days: 7 * deltaWeeks));
    setState(() => _weekStart = newWeekStart);
    widget.onDateSelected(newWeekStart);
  }

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (i) => _weekStart.add(Duration(days: i)));

    return Row(
      children: [
        _WeekPageButton(icon: Icons.chevron_left_rounded, semanticLabel: 'Previous week', onPressed: () => _pageWeek(-1)),
        Expanded(
          child: Row(
            children: [
              for (final day in days)
                Expanded(
                  child: _DayCell(
                    date: day,
                    selected: day.isSameDate(widget.selectedDate),
                    hasPendingTask: widget.datesWithPendingTasks.contains(day),
                    onTap: () => widget.onDateSelected(day),
                  ),
                ),
            ],
          ),
        ),
        _WeekPageButton(icon: Icons.chevron_right_rounded, semanticLabel: 'Next week', onPressed: () => _pageWeek(1)),
      ],
    );
  }
}

class _WeekPageButton extends StatelessWidget {
  const _WeekPageButton({required this.icon, required this.semanticLabel, required this.onPressed});

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(icon: Icon(icon), color: colorScheme.onSurfaceVariant, tooltip: semanticLabel, onPressed: onPressed);
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.date, required this.selected, required this.hasPendingTask, required this.onTap});

  final DateTime date;
  final bool selected;
  final bool hasPendingTask;
  final VoidCallback onTap;

  static const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _pendingDotSize = 6.0;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isToday = date.isToday;
    final circleSize = theme.controlHeight * 0.72;

    final weekdayLabel = '${_weekdayLetters[date.weekday - 1]} ${date.day}';

    return Semantics(
      button: true,
      selected: selected,
      label: hasPendingTask ? '$weekdayLabel, has pending tasks' : weekdayLabel,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(theme.appBorderRadius),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: theme.spacingXSmall),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LabelText.small(_weekdayLetters[date.weekday - 1], color: colorScheme.onSurfaceVariant),
                SizedBox(height: theme.spacingXSmall),
                Container(
                  width: circleSize,
                  height: circleSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? colorScheme.primary : Colors.transparent,
                    border: !selected && isToday ? Border.all(color: colorScheme.primary, width: 1.5) : null,
                  ),
                  child: Text(
                    '${date.day}',
                    style: theme.labelLarge.copyWith(
                      color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: theme.spacingXSmall),
                Container(
                  width: _pendingDotSize,
                  height: _pendingDotSize,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: hasPendingTask ? colorScheme.error : Colors.transparent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
