import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/day_availability.dart';
import '../models/doctor.dart';
import '../providers/auth_provider.dart';
import '../repositories/booking_repository.dart';
import '../widgets/back_circle_button.dart';
import 'patient_home_screen.dart';

class ReviewBookingScreen extends StatefulWidget {
  const ReviewBookingScreen({
    super.key,
    required this.doctor,
    required this.day,
    required this.time,
  });

  final Doctor doctor;
  final DayAvailability day;
  final String time;

  @override
  State<ReviewBookingScreen> createState() => _ReviewBookingScreenState();
}

class _ReviewBookingScreenState extends State<ReviewBookingScreen> {
  bool _sending = false;

  Future<void> _send() async {
    setState(() => _sending = true);

    final auth = context.read<AuthProvider>();
    final repo = context.read<BookingRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await repo.createBooking(
        patientId: auth.userId,
        patientName: auth.user?.name ?? '',
        doctor: widget.doctor,
        date: widget.day.id,
        time: widget.time,
      );
      if (!mounted) return;
      PatientHomeScreen.openTab(context, 1);
      navigator.popUntil((route) => route.isFirst);
      messenger.showSnackBar(
        const SnackBar(content: Text('Booking request sent.')),
      );
    } on SlotTakenException {
      navigator.popUntil((route) => route.isFirst);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('This time was just taken. Please pick another.'),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _sending = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not send the request. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctor = widget.doctor;
    final day = widget.day;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BackCircleButton(),
              const SizedBox(height: 22),
              const Text(
                'Review Booking',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  children: [
                    _InfoRow(label: 'Doctor', value: doctor.name),
                    _InfoRow(label: 'Specialty', value: doctor.specialtyName),
                    _InfoRow(
                      label: 'Date',
                      value: '${day.dayName}, ${day.dateLabel}',
                    ),
                    _InfoRow(label: 'Time', value: widget.time),
                    _InfoRow(label: 'Fee', value: '${doctor.fee} EGP'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3D6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Your request goes to the clinic assistant for '
                      'confirmation. Status will be Pending until then.',
                  style: TextStyle(color: Color(0xFF8A6D1F), fontSize: 13),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ), onPressed: _sending ? null : _send,
                  child: _sending
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Send Booking Request',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}