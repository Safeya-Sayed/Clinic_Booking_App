import '../models/day_availability.dart';
import '../models/doctor.dart';
import '../models/specialty.dart';

/// The screens only talk to this class.
/// The data comes from FirestoreClinicRepository.
abstract class ClinicRepository {
  Future<List<Specialty>> getSpecialties();

  /// All doctors, or only the doctors of one specialty.
  Future<List<Doctor>> getDoctors({String? specialtyId});

  /// Available days (with free slots) of one doctor.
  Future<List<DayAvailability>> getAvailableDays(String doctorId);
}
