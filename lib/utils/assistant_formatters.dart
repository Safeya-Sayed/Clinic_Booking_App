import '../models/appointment.dart';

const List<String> _weekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday',
  'Friday', 'Saturday', 'Sunday',
];

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "Mona Ali" -> "MA"
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final result = parts.take(2).map((p) => p[0].toUpperCase()).join();
  return result.isEmpty ? '?' : result;
}

/// "Sun 22 Nov"
String shortDayLabel(Appointment a) {
  final d = a.startsAt;
  return '${_weekdays[d.weekday - 1].substring(0, 3)} ${d.day} ${_months[d.month - 1]}';
}

/// "Sunday, 22 Nov"
String longDayLabel(Appointment a) {
  final d = a.startsAt;
  return '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}';
}
/// DateTime -> "2026-11-22" (نفس شكل التاريخ المخزّن في Firestore)
String dateKey(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

/// DateTime -> "Sun 22 Nov"
String shortDateLabel(DateTime d) {
  return '${_weekdays[d.weekday - 1].substring(0, 3)} ${d.day} ${_months[d.month - 1]}';
}