/// Single-letter weekday labels, Monday-first - shared by every widget that lays
/// out a Monday-start week (the task date carousel and its calendar drawer).
const List<String> kWeekdayInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

extension DateTimeExtensions on DateTime {
  /// Returns a new DateTime object with the time set to midnight (00:00:00).
  DateTime get atMidnight => DateTime(year, month, day);

  /// Returns a new DateTime object with the time set to the end of the day (23:59:59.999).
  DateTime get atEndOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Returns a new DateTime object with the time set to noon (12:00:00).
  DateTime get atNoon => DateTime(year, month, day, 12);

  /// Returns a new DateTime object with the time set to the start of the hour.
  DateTime get atStartOfHour => DateTime(year, month, day, hour);

  /// Returns a new DateTime object with the time set to the end of the hour.
  DateTime get atEndOfHour => DateTime(year, month, day, hour, 59, 59, 999);

  /// return a datetime as formatted in dd mmm yyyy : hh:mm am/pm format
  String get formattedDateTime {
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final monthName = _monthNames[month - 1];
    return '$day $monthName $year : ${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $amPm';
  }

  /// Canonical serialization for any [DateTime] sent to the backend - the single place this
  /// format is defined, so every service call stays consistent.
  String toServer() => toIso8601String();

  /// Whether this date falls on the same calendar day as [other].
  bool isSameDate(DateTime other) => year == other.year && month == other.month && day == other.day;

  /// Whether this date falls on today's calendar day.
  bool get isToday => isSameDate(DateTime.now());

  /// Time only (hh:mm am/pm) - used where the date is implied by context, e.g. "today".
  String get formattedTime {
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final amPm = hour >= 12 ? 'PM' : 'AM';
    return '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $amPm';
  }

  /// Short date without year, e.g. "10 Aug".
  String get formattedShortDate => '$day ${_monthNames[month - 1]}';

  /// Full month and year, e.g. "September 2026" - used as a calendar view's month header.
  String get monthYearLabel => '${_fullMonthNames[month - 1]} $year';

  static const List<String> _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const List<String> _fullMonthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
}
