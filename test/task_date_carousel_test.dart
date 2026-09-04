import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huddle/core/extensions/date_time_extensions.dart';
import 'package:huddle/core/resources/app_fonts.dart';
import 'package:huddle/core/resources/app_strings.dart';
import 'package:huddle/core/themes/app_theme.dart';
import 'package:huddle/features/shared/widgets/app_bottom_sheet.dart';
import 'package:huddle/features/task/widgets/task_date_carousel.dart';

/// Hosts [TaskDateCarousel] the same way [TaskListScreen] does, without needing
/// the real providers/backend. The carousel opens `TaskCalendarSheet` itself (via
/// `showModalBottomSheet`) when swiped, so this harness only supplies the
/// carousel's own inputs - there's nothing extra to wire up for the sheet.
class _Harness extends StatefulWidget {
  const _Harness({required this.accountCreatedDate});

  final DateTime accountCreatedDate;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  DateTime selectedDate = DateTime.now().atMidnight;

  void _onDateSelected(DateTime date) => setState(() => selectedDate = date);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppThemes.lightTheme(font: AppFontOption.defaultOption),
      home: Scaffold(
        appBar: AppBar(),
        body: TaskDateCarousel(
          selectedDate: selectedDate,
          accountCreatedDate: widget.accountCreatedDate,
          onDateSelected: _onDateSelected,
          datesWithPendingTasks: const {},
        ),
      ),
    );
  }
}

void main() {
  testWidgets('swiping left-to-right on the carousel opens the calendar sheet', (tester) async {
    await tester.pumpWidget(_Harness(accountCreatedDate: DateTime(2020)));
    await tester.pumpAndSettle();

    expect(find.byType(AppBottomSheet), findsNothing);

    await tester.fling(find.byType(TaskDateCarousel), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.byType(AppBottomSheet), findsOneWidget);
    expect(find.text(AppStrings.calendar), findsOneWidget);
  });

  testWidgets('swiping right-to-left on the carousel also opens the calendar sheet', (tester) async {
    await tester.pumpWidget(_Harness(accountCreatedDate: DateTime(2020)));
    await tester.pumpAndSettle();

    expect(find.byType(AppBottomSheet), findsNothing);

    await tester.fling(find.byType(TaskDateCarousel), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.byType(AppBottomSheet), findsOneWidget);
  });

  testWidgets('a real, non-linear swipe starting on a day cell still opens the sheet', (tester) async {
    // tester.fling() sends a perfectly linear, high-sample-rate gesture from the
    // widget's geometric center, which can hide a gesture-arena conflict where a
    // real finger's swipe over a day cell's InkWell loses the arena to its tap
    // recognizer instead of registering as a drag. Drive raw pointer events by hand,
    // starting exactly on a day cell, with uneven step sizes, to catch that case.
    await tester.pumpWidget(_Harness(accountCreatedDate: DateTime(2020)));
    await tester.pumpAndSettle();

    // TestGesture's timeStamp defaults to Duration.zero unless passed explicitly,
    // so each step below supplies an increasing timestamp - otherwise the
    // VelocityTracker sees zero elapsed time between samples and computes 0 velocity.
    final dayCellCenter = tester.getCenter(find.byType(TaskDateCarousel).first);
    final gesture = await tester.startGesture(dayCellCenter);
    await gesture.moveBy(const Offset(40, 2), timeStamp: const Duration(milliseconds: 16));
    await gesture.moveBy(const Offset(90, -1), timeStamp: const Duration(milliseconds: 36));
    await gesture.moveBy(const Offset(70, 0), timeStamp: const Duration(milliseconds: 52));
    await gesture.up(timeStamp: const Duration(milliseconds: 68));
    await tester.pumpAndSettle();

    expect(find.byType(AppBottomSheet), findsOneWidget);
  });

  testWidgets('picking a date in the sheet selects it, closes the sheet, and moves the carousel week', (tester) async {
    // Fixed "today" far from month boundaries so the target day (10th) always
    // falls in a different week than today, regardless of which day this runs on.
    final today = DateTime.now();
    final targetDate = DateTime(today.year, today.month, 10).isSameDate(today.atMidnight)
        ? DateTime(today.year, today.month, 20)
        : DateTime(today.year, today.month, 10);

    await tester.pumpWidget(_Harness(accountCreatedDate: DateTime(2020)));
    await tester.pumpAndSettle();

    await tester.fling(find.byType(TaskDateCarousel), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('${targetDate.day}'));
    await tester.pumpAndSettle();

    expect(find.byType(AppBottomSheet), findsNothing);
    // The carousel's own day cell for targetDate should now render selected -
    // its Semantics label is unambiguous even across weeks since it includes the weekday letter.
    expect(find.bySemanticsLabel('${kWeekdayInitials[targetDate.weekday - 1]} ${targetDate.day}'), findsOneWidget);
  });

  testWidgets('dates before account creation are disabled in the sheet', (tester) async {
    final accountCreatedDate = DateTime.now().atMidnight;
    await tester.pumpWidget(_Harness(accountCreatedDate: accountCreatedDate));
    await tester.pumpAndSettle();

    await tester.fling(find.byType(TaskDateCarousel), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();

    // The previous-month button must be disabled since the account was created this month.
    final previousMonthButton = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_left_rounded));
    expect(previousMonthButton.onPressed, isNull);
  });
}
