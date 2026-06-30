extension DateTimeFormatting on DateTime {
  String get formattedFull {
    final d = day.toString().padLeft(2, '0');
    final m = month.toString().padLeft(2, '0');
    final h = hour.toString().padLeft(2, '0');
    final min = minute.toString().padLeft(2, '0');
    return '$d/$m/$year at $h:$min';
  }

  String get formattedDateOnly {
    final d = day.toString().padLeft(2, '0');
    final m = month.toString().padLeft(2, '0');
    return '$d/$m/$year';
  }

  String get formattedShort {
    final d = day.toString().padLeft(2, '0');
    final m = month.toString().padLeft(2, '0');
    final h = hour.toString().padLeft(2, '0');
    final min = minute.toString().padLeft(2, '0');
    return '$d/$m at $h:$min';
  }

  String get formattedDateTime {
    final d = day.toString().padLeft(2, '0');
    final m = month.toString().padLeft(2, '0');
    final h = hour.toString().padLeft(2, '0');
    final min = minute.toString().padLeft(2, '0');
    return '$d/$m/$year $h:$min';
  }
}
