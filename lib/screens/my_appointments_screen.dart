import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/appointment.dart';
import '../models/day_availability.dart';
import '../providers/auth_provider.dart';
import '../repositories/booking_repository.dart';
import '../repositories/clinic_repository.dart';
import '../widgets/appointment_card.dart';
import '../widgets/day_card.dart';
import 'time_slots_screen.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  static const List<String> _tabs = ['Upcoming', 'Completed', 'Cancelled'];

  late final Stream<List<Appointment>> _stream;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    final patientId = context.read<AuthProvider>().userId;
    _stream = context.read<BookingRepository>().watchMyAppointments(patientId);
  }
  List<Appointment> _filter(List<Appointment> all) {
    switch (_tab) {
      case 0:
        return all
            .where((a) => a.isPending || a.isConfirmed || a.isRejected)
            .toList();
      case 1:
        return all.where((a) => a.isCompleted).toList();
      default:
        return all.where((a) => a.isCancelled).toList();
    }
  }
  Future<void> _onCancel(Appointment a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: Text('${a.doctorName}, ${a.date} at ${a.time}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel appointment'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final repo = context.read<BookingRepository>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      await repo.cancelBooking(a);
      messenger.showSnackBar(
        const SnackBar(content: Text('Appointment cancelled.')),
      );
    } on TooLateToChangeException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not cancel. Try again.')),
      );
    }
  }
  Future<void> _onReschedule(Appointment a) async {
    final clinic = context.read<ClinicRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final doctors = await clinic.getDoctors();
      final doctor = doctors.firstWhere((d) => d.id == a.doctorId);
      final days = await clinic.getAvailableDays(a.doctorId);
      if (!mounted) return;

      if (days.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No available days for this doctor.')),
        );
        return;
      }
      final day = await _pickDay(days);
      if (day == null) return;

      navigator.push(
        MaterialPageRoute(
          builder: (_) => TimeSlotsScreen(
            doctor: doctor,
            day: day,
            rescheduling: a,
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not load available days.')),
      );
    }
  }
  Future<DayAvailability?> _pickDay(List<DayAvailability> days) {
    return showModalBottomSheet<DayAvailability>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pick a new day',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            for (final day in days)
              DayCard(day: day, onTap: () => Navigator.of(ctx).pop(day)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Appointments',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              _buildTabs(),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<Appointment>>(
                  stream: _stream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Could not load appointments.'),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(
                        child:
                        CircularProgressIndicator(color: AppColors.primary),
                      );
                    }
                    final items = _filter(snapshot.data!);
                    if (items.isEmpty) {
                      return const Center(
                        child: Text(
                          'No appointments here.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.only(bottom: 20),
                      children: [
                        for (final a in items)
                          AppointmentCard(
                            appointment: a,
                            onCancel: () => _onCancel(a),
                            onReschedule: () => _onReschedule(a),
                          ),
                        if (_tab == 0)
                          const Text(
                            'Cancel is allowed up to 2 hours before the '
                                'appointment.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          for (var i = 0; i < _tabs.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tab = i),
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == _tab ? AppColors.dark : Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    _tabs[i],
                    style: TextStyle(
                      color: i == _tab ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}