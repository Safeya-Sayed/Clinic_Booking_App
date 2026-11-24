import '../models/appointment.dart';
import '../models/doctor.dart';

class SlotTakenException implements Exception {
  const SlotTakenException();

  @override
  String toString() => 'This time slot is no longer available.';
}

class TooLateToChangeException implements Exception {
  const TooLateToChangeException();

  @override
  String toString() =>
      'Changes are allowed up to 2 hours before the appointment.';
}

abstract class BookingRepository {
  Future<Appointment> createBooking({
    required String patientId,
    required String patientName,
    required Doctor doctor,
    required String date,
    required String time,
  });

  Stream<List<Appointment>> watchMyAppointments(String patientId);

  Future<void> cancelBooking(Appointment appointment);

  Future<void> rescheduleBooking(
      Appointment appointment, {
        required String newDate,
        required String newTime,
      });

  // ---- Assistant side ----
  Stream<List<Appointment>> watchPendingRequests();
  Stream<List<Appointment>> watchAppointmentsByDate(String date);
  Stream<List<Appointment>> watchAllAppointments();

  Future<bool> confirmBooking(Appointment appointment);
  Future<bool> rejectBooking(Appointment appointment, {required String reason});

  // ---- Queue ----
  Stream<List<Appointment>> watchQueue(String doctorId, String date);
  Future<void> finishVisit(Appointment appointment);
  Future<void> skipInQueue(Appointment appointment);
}