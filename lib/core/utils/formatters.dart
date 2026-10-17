class AppDateFormatter {
  /// Formats a date string (e.g. "2026-11-16", ISO string), [DateTime],
  /// or Firestore Timestamp to user-visible "DD-MM-YYYY" format.
  /// Returns [fallback] if null or invalid.
  static String formatDate(dynamic input, {String fallback = ''}) {
    if (input == null) return fallback;

    if (input is DateTime) {
      return _formatDateTime(input);
    }

    if (input is String) {
      final str = input.trim();
      if (str.isEmpty) return fallback;

      // Check if string is already DD-MM-YYYY (10 chars, dashes at index 2 and 5)
      final ddMmyyyyRegex = RegExp(r'^\d{2}-\d{2}-\d{4}');
      if (ddMmyyyyRegex.hasMatch(str)) {
        return str.substring(0, 10);
      }

      // Check if YYYY-MM-DD format (index 4 and 7 are dashes)
      final yyyyMmDdRegex = RegExp(r'^\d{4}-\d{2}-\d{2}');
      if (yyyyMmDdRegex.hasMatch(str)) {
        final parts = str.substring(0, 10).split('-');
        final year = parts[0];
        final month = parts[1];
        final day = parts[2];
        return '$day-$month-$year';
      }

      // Try DateTime.tryParse (for ISO dates)
      final parsed = DateTime.tryParse(str);
      if (parsed != null) {
        return _formatDateTime(parsed);
      }

      return str;
    }

    return fallback;
  }

  static String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString().padLeft(4, '0');
    return '$day-$month-$year';
  }

  /// Converts user-displayed "DD-MM-YYYY" string back to canonical "YYYY-MM-DD" for queries/storage.
  static String toCanonicalDate(String displayDate) {
    final str = displayDate.trim();
    if (str.isEmpty) return '';
    final ddMmyyyyRegex = RegExp(r'^(\d{2})-(\d{2})-(\d{4})');
    final match = ddMmyyyyRegex.firstMatch(str);
    if (match != null) {
      final day = match.group(1)!;
      final month = match.group(2)!;
      final year = match.group(3)!;
      return '$year-$month-$day';
    }
    return str;
  }

  /// Formats current date as DD-MM-YYYY
  static String todayDisplay() {
    return _formatDateTime(DateTime.now());
  }

  /// Formats current date as canonical YYYY-MM-DD
  static String todayCanonical() {
    final dt = DateTime.now();
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
