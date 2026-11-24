import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/day_availability.dart';
import '../models/doctor.dart';
import '../models/specialty.dart';
import 'clinic_repository.dart';

/// Reads specialties / doctors / days from Cloud Firestore.
///
/// specialties/{id}          -> name
/// doctors/{id}              -> name, specialtyId, specialtyName, about, ...
/// doctors/{id}/days/{date}  -> date, slots[]
class FirestoreClinicRepository implements ClinicRepository {
  final FirebaseFirestore _db;

  FirestoreClinicRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  @override
  Future<List<Specialty>> getSpecialties() async {
    final snap = await _db.collection('specialties').orderBy('name').get();
    return snap.docs.map((d) => Specialty.fromMap(d.data(), d.id)).toList();
  }

  @override
  Future<List<Doctor>> getDoctors({String? specialtyId}) async {
    Query<Map<String, dynamic>> query = _db.collection('doctors');
    if (specialtyId != null) {
      query = query.where('specialtyId', isEqualTo: specialtyId);
    }
    final snap = await query.get();
    final doctors =
        snap.docs.map((d) => Doctor.fromMap(d.data(), d.id)).toList();
    // Highest rating first (same order as the design).
    doctors.sort((a, b) => b.rating.compareTo(a.rating));
    return doctors;
  }

  @override
  Future<List<DayAvailability>> getAvailableDays(String doctorId) async {
    final snap = await _db
        .collection('doctors')
        .doc(doctorId)
        .collection('days')
        .orderBy('date')
        .get();
    return snap.docs
        .map((d) => DayAvailability.fromMap(d.data()))
        .where((day) => day.slots.isNotEmpty)
        .toList();
  }
}