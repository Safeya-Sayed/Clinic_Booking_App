import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentStatus {
  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String rejected = 'rejected';
  static const String cancelled = 'cancelled';
  static const String completed = 'completed';
}

class Appointment {
  static const Duration changeDeadline = Duration(hours: 2);

  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String specialtyName;
  final String date;
  final String time;
  final int fee;
  final String status;
  final String rejectReason;
  final DateTime? createdAt;

  const Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.specialtyName,
    required this.date,
    required this.time,
    required this.fee,
    required this.status,
    this.rejectReason = '',
    this.createdAt,
  });
  DateTime get startsAt {
    final d = DateTime.parse(date);
    final parts = time.split(':');
    return DateTime(
      d.year,
      d.month,
      d.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }
  String get initials {
    final cleaned = doctorName.replaceFirst(RegExp(r'^Dr\.?\s*'), '').trim();
    final parts = cleaned.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
  bool get isPending => status == AppointmentStatus.pending;
  bool get isConfirmed => status == AppointmentStatus.confirmed;
  bool get isRejected => status == AppointmentStatus.rejected;
  bool get isCancelled => status == AppointmentStatus.cancelled;
  bool get isCompleted => status == AppointmentStatus.completed;

  bool get canChange {
    if (!isPending && !isConfirmed) return false;
    return startsAt.difference(DateTime.now()) >= changeDeadline;
  }

  factory Appointment.fromMap(Map<String, dynamic> map, String id) {
    final created = map['createdAt'];
    return Appointment(
      id: id,
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      doctorId: map['doctorId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      specialtyName: map['specialtyName'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      fee: (map['fee'] ?? 0).toInt(),
      status: map['status'] ?? AppointmentStatus.pending,
      rejectReason: map['rejectReason'] ?? '',
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'specialtyName': specialtyName,
      'date': date,
      'time': time,
      'fee': fee,
      'status': status,
      'rejectReason': rejectReason,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}