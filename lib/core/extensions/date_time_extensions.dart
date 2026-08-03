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
}
