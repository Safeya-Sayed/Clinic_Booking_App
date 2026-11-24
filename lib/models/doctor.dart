class Doctor {
  final String id;
  final String name;
  final String specialtyId;
  final String specialtyName;
  final String about;
  final double rating;
  final int fee; // EGP
  final bool isAvailable;

  const Doctor({
    required this.id,
    required this.name,
    required this.specialtyId,
    required this.specialtyName,
    required this.about,
    required this.rating,
    required this.fee,
    this.isAvailable = true,
  });

  /// "Dr. Ahmed Hassan" -> "AH"
  String get initials {
    final cleaned = name.replaceFirst(RegExp(r'^Dr\.?\s*'), '').trim();
    final parts = cleaned.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  factory Doctor.fromMap(Map<String, dynamic> map, String id) {
    return Doctor(
      id: id,
      name: map['name'] ?? '',
      specialtyId: map['specialtyId'] ?? '',
      specialtyName: map['specialtyName'] ?? '',
      about: map['about'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      fee: (map['fee'] ?? 0).toInt(),
      isAvailable: map['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'specialtyId': specialtyId,
      'specialtyName': specialtyName,
      'about': about,
      'rating': rating,
      'fee': fee,
      'isAvailable': isAvailable,
    };
  }
}
