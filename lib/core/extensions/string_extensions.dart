extension StringCasingExtensions on String {
  /// Converts a SCREAMING_SNAKE_CASE or snake_case string to 'Title Case'.
  String get toTitleCase {
    return split('_')
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}
