import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:huddle/core/extensions/build_context_theme_extensions.dart';
import 'package:huddle/core/extensions/date_time_extensions.dart';
import 'package:huddle/features/shared/widgets/text/label_text.dart';
import 'package:huddle/features/task/widgets/task_calendar_sheet.dart';
import 'package:huddle/features/task/widgets/task_date_indicator.dart';

/// Horizontal week-at-a-time day picker shown above the task list. Swiping across
/// it in either direction opens [TaskCalendarSheet], which covers the account's
/// whole history rather than paging week-by-week here.
class TaskDateCarousel extends StatefulWidget {
  const TaskDateCarousel({
    super.key,
    required this.selectedDate,
    required this.accountCreatedDate,
    required this.onDateSelected,
    required this.datesWithPendingTasks,
  });

  final DateTime selectedDate;
  final DateTime accountCreatedDate;
  final ValueChanged<DateTime> onDateSelected;

  /// Calendar days (at midnight) to mark with a pending-task dot.
  final Set<DateTime> datesWithPendingTasks;

  @override
  State<TaskDateCarousel> createState() => _TaskDateCarouselState();
}

class _TaskDateCarouselState extends State<TaskDateCarousel> {
  /// A horizontal drag faster than this (logical pixels/second), in either
  /// direction, counts as a swipe that opens the calendar sheet, rather than an
  /// incidental touch.
  static const _swipeVelocityThreshold = 200.0;

  late DateTime _weekStart = _startOfWeek(widget.selectedDate);

  // Tracked manually with a Listener rather than GestureDetector's
  // onHorizontalDragEnd: the day cells below are InkWells, and a real (non-linear,
  // slower) finger swipe can lose the gesture-arena race to their tap recognizer,
  // silently eating the swipe. Listener sees every raw pointer event regardless of
  // which recognizer wins the arena, so it can't be starved like that.
  VelocityTracker? _velocityTracker;
  Offset? _dragStart;

  static DateTime _startOfWeek(DateTime date) => date.atMidnight.subtract(Duration(days: date.weekday - DateTime.monday));

  @override
  void didUpdateWidget(covariant TaskDateCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Picking a date from the calendar drawer can land in a different week (or
    // month entirely), so the visible week must follow selectedDate rather than
    // only moving when this widget's own day cells are tapped.
    final newWeekStart = _startOfWeek(widget.selectedDate);
    if (newWeekStart != _weekStart) {
      setState(() => _weekStart = newWeekStart);
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    _velocityTracker = VelocityTracker.withKind(event.kind);
    _velocityTracker!.addPosition(event.timeStamp, event.position);
    _dragStart = event.position;
  }

  void _onPointerMove(PointerMoveEvent event) {
    _velocityTracker?.addPosition(event.timeStamp, event.position);
  }

  void _onPointerUp(PointerUpEvent event) {
    final tracker = _velocityTracker;
    final start = _dragStart;
    _velocityTracker = null;
    _dragStart = null;
    if (tracker == null || start == null) return;

    final offset = event.position - start;
    final isHorizontalSwipe = offset.dx.abs() > offset.dy.abs();
    final horizontalVelocity = tracker.getVelocity().pixelsPerSecond.dx;
    if (isHorizontalSwipe && horizontalVelocity.abs() > _swipeVelocityThreshold) {
      TaskCalendarSheet.show(
        context,
        selectedDate: widget.selectedDate,
        accountCreatedDate: widget.accountCreatedDate,
        datesWithPendingTasks: widget.datesWithPendingTasks,
        onDateSelected: widget.onDateSelected,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (i) => _weekStart.add(Duration(days: i)));

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
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
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.date, required this.selected, required this.hasPendingTask, required this.onTap});

  final DateTime date;
  final bool selected;
  final bool hasPendingTask;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final circleSize = theme.controlHeight * 0.72;

    final weekdayLabel = '${kWeekdayInitials[date.weekday - 1]} ${date.day}';

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
                LabelText.small(kWeekdayInitials[date.weekday - 1], color: colorScheme.onSurfaceVariant),
                SizedBox(height: theme.spacingXSmall),
                TaskDateIndicator(date: date, selected: selected, hasPendingTask: hasPendingTask, circleSize: circleSize),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
