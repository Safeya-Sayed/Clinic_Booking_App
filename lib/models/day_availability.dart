/// One available day for a doctor, with its free time slots (max 6).
class DayAvailability {
  static const int maxSlots = 6;

  static const List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _months = [
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

  final DateTime date;
  final List<String> slots; // free times, e.g. "10:00"

  DayAvailability({required this.date, required List<String> slots})
      : slots = List.unmodifiable(slots.take(maxSlots));

  /// Document id / stored value, e.g. "2026-11-22".
  String get id =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String get dayName => _weekdays[date.weekday - 1];

  /// e.g. "22 Nov"
  String get dateLabel => '${date.day} ${_months[date.month - 1]}';

  int get slotsCount => slots.length;

  factory DayAvailability.fromMap(Map<String, dynamic> map) {
    return DayAvailability(
      date: DateTime.parse(map['date'] as String),
      slots: List<String>.from(map['slots'] ?? const []),
    );
  }

  Map<String, dynamic> toMap() => {'date': id, 'slots': slots};
}
