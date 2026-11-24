import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment.dart';
import '../models/doctor.dart';
import 'booking_repository.dart';

class FirestoreBookingRepository implements BookingRepository {
  final FirebaseFirestore _db;

  FirestoreBookingRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _appointments =>
      _db.collection('appointments');

  DocumentReference<Map<String, dynamic>> _dayRef(
      String doctorId,
      String date,
      ) =>
      _db.collection('doctors').doc(doctorId).collection('days').doc(date);

  List<String> _slotsOf(DocumentSnapshot<Map<String, dynamic>> snap) =>
      List<String>.from(snap.data()?['slots'] ?? const []);

  @override
  Future<Appointment> createBooking({
    required String patientId,
    required String patientName,
    required Doctor doctor,
    required String date,
    required String time,
  }) async {
    final dayRef = _dayRef(doctor.id, date);
    final bookingRef = _appointments.doc();

    final appointment = Appointment(
      id: bookingRef.id,
      patientId: patientId,
      patientName: patientName,
      doctorId: doctor.id,
      doctorName: doctor.name,
      specialtyName: doctor.specialtyName,
      date: date,
      time: time,
      fee: doctor.fee,
      status: AppointmentStatus.pending,
    );

    await _db.runTransaction((tx) async {
      final daySnap = await tx.get(dayRef);
      final slots = _slotsOf(daySnap);
      if (!slots.contains(time)) throw const SlotTakenException();

      slots.remove(time);
      tx.update(dayRef, {'slots': slots});
      tx.set(bookingRef, appointment.toMap());
    });

    return appointment;
  }

  @override
  Stream<List<Appointment>> watchMyAppointments(String patientId) {
    return _appointments
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snap) {
      final list =
      snap.docs.map((d) => Appointment.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => a.startsAt.compareTo(b.startsAt));
      return list;
    });
  }

  @override
  Future<void> cancelBooking(Appointment appointment) async {
    if (!appointment.canChange) throw const TooLateToChangeException();

    final bookingRef = _appointments.doc(appointment.id);
    final dayRef = _dayRef(appointment.doctorId, appointment.date);

    await _db.runTransaction((tx) async {
      final bookingSnap = await tx.get(bookingRef);
      final current = bookingSnap.data()?['status'];
      if (current != AppointmentStatus.pending &&
          current != AppointmentStatus.confirmed) {
        return;
      }

      final daySnap = await tx.get(dayRef);
      final slots = _slotsOf(daySnap);
      if (!slots.contains(appointment.time)) {
        slots.add(appointment.time);
        slots.sort();
      }

      tx.update(bookingRef, {'status': AppointmentStatus.cancelled});
      tx.set(
        dayRef,
        {'date': appointment.date, 'slots': slots},
        SetOptions(merge: true),
      );
    });
  }

  @override
  Future<void> rescheduleBooking(
      Appointment appointment, {
        required String newDate,
        required String newTime,
      }) async {
    if (!appointment.canChange) throw const TooLateToChangeException();

    final bookingRef = _appointments.doc(appointment.id);
    final oldDayRef = _dayRef(appointment.doctorId, appointment.date);
    final newDayRef = _dayRef(appointment.doctorId, newDate);
    final sameDay = appointment.date == newDate;

    await _db.runTransaction((tx) async {

      final oldSnap = await tx.get(oldDayRef);
      final newSnap = sameDay ? oldSnap : await tx.get(newDayRef);

      final oldSlots = _slotsOf(oldSnap);
      final newSlots = sameDay ? oldSlots : _slotsOf(newSnap);

      if (!newSlots.contains(newTime)) throw const SlotTakenException();

      newSlots.remove(newTime);
      if (!oldSlots.contains(appointment.time)) {
        oldSlots.add(appointment.time);
        oldSlots.sort();
      }

      tx.set(
        oldDayRef,
        {'date': appointment.date, 'slots': oldSlots},
        SetOptions(merge: true),
      );
      if (!sameDay) {
        tx.set(
          newDayRef,
          {'date': newDate, 'slots': newSlots},
          SetOptions(merge: true),
        );
      }
      tx.update(bookingRef, {
        'date': newDate,
        'time': newTime,
        'status': AppointmentStatus.pending,
        'rejectReason': '',
      });
    });
  }

  // =========================
  // Assistant side
  // =========================

  // بتحوّل نتيجة Firestore لقائمة Appointment
  List<Appointment> _toList(QuerySnapshot<Map<String, dynamic>> snap) =>
      snap.docs.map((d) => Appointment.fromMap(d.data(), d.id)).toList();

  @override
  Stream<List<Appointment>> watchPendingRequests() {
    return _appointments
        .where('status', isEqualTo: AppointmentStatus.pending)
        .snapshots()
        .map((snap) {
      final list = _toList(snap);
      list.sort((a, b) => a.startsAt.compareTo(b.startsAt));
      return list;
    });
  }

  @override
  Stream<List<Appointment>> watchAppointmentsByDate(String date) {
    return _appointments.where('date', isEqualTo: date).snapshots().map((snap) {
      final list = _toList(snap);
      list.sort((a, b) => a.time.compareTo(b.time));
      return list;
    });
  }

  @override
  Stream<List<Appointment>> watchAllAppointments() {
    return _appointments.snapshots().map((snap) {
      final list = _toList(snap);
      list.sort((a, b) => b.startsAt.compareTo(a.startsAt));
      return list;
    });
  }

  @override
  Future<bool> confirmBooking(Appointment appointment) async {
    final ref = _appointments.doc(appointment.id);

    return _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(ref);
      if (snap.data()?['status'] != AppointmentStatus.pending) return false;

      tx.update(ref, {
        'status': AppointmentStatus.confirmed,
        'rejectReason': '',
        'skippedAt': 0,
      });
      return true;
    });
  }

  @override
  Future<bool> rejectBooking(
      Appointment appointment, {
        required String reason,
      }) async {
    final ref = _appointments.doc(appointment.id);
    final dayRef = _dayRef(appointment.doctorId, appointment.date);
    final cleaned =
    reason.trim().isEmpty ? 'Rejected by the clinic' : reason.trim();

    return _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(ref);
      if (snap.data()?['status'] != AppointmentStatus.pending) return false;

      final daySnap = await tx.get(dayRef);
      final slots = _slotsOf(daySnap);
      if (!slots.contains(appointment.time)) {
        slots.add(appointment.time);
        slots.sort();
      }

      tx.set(
        dayRef,
        {'date': appointment.date, 'slots': slots},
        SetOptions(merge: true),
      );
      tx.update(ref, {
        'status': AppointmentStatus.rejected,
        'rejectReason': cleaned,
      });
      return true;
    });
  }
  // =========================
  // Queue
  // =========================

  // وقت الـ skip (0 معناها ما اتعداش)
  int _skippedAtOf(Map<String, dynamic> m) =>
      (m['skippedAt'] as num?)?.toInt() ?? 0;

  @override
  Stream<List<Appointment>> watchQueue(String doctorId, String date) {
    return _appointments.where('date', isEqualTo: date).snapshots().map((snap) {
      // مواعيد الدكتور ده المؤكدة بس
      final docs = snap.docs.where((d) {
        final m = d.data();
        return m['doctorId'] == doctorId &&
            m['status'] == AppointmentStatus.confirmed;
      }).toList();

      docs.sort((a, b) {
        final sa = _skippedAtOf(a.data());
        final sb = _skippedAtOf(b.data());

        // اللي ما اتعداش قبل اللي اتعدّى
        if ((sa == 0) != (sb == 0)) return sa == 0 ? -1 : 1;
        // اللي اتعدّوا: اللي اتعدّى الأول يبقى قبل
        if (sa != sb) return sa.compareTo(sb);
        // الباقي بالوقت
        return (a.data()['time'] ?? '')
            .toString()
            .compareTo((b.data()['time'] ?? '').toString());
      });

      return docs.map((d) => Appointment.fromMap(d.data(), d.id)).toList();
    });
  }

  @override
  Future<void> finishVisit(Appointment appointment) async {
    final ref = _appointments.doc(appointment.id);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.data()?['status'] != AppointmentStatus.confirmed) return;

      tx.update(ref, {
        'status': AppointmentStatus.completed,
        'skippedAt': 0,
      });
    });
  }

  @override
  Future<void> skipInQueue(Appointment appointment) async {
    final ref = _appointments.doc(appointment.id);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.data()?['status'] != AppointmentStatus.confirmed) return;

      tx.update(ref, {'skippedAt': DateTime.now().millisecondsSinceEpoch});
    });
  }
}