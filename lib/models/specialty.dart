class Specialty {
  final String id;
  final String name;

  const Specialty({required this.id, required this.name});

  /// Two letters shown inside the card icon (e.g. "Ca").
  String get shortName => name.length >= 2 ? name.substring(0, 2) : name;

  factory Specialty.fromMap(Map<String, dynamic> map, String id) {
    return Specialty(id: id, name: map['name'] ?? '');
  }

  Map<String, dynamic> toMap() => {'name': name};
}
