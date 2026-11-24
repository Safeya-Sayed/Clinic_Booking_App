import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/appointment.dart';
import '../models/day_availability.dart';
import '../models/doctor.dart';
import '../repositories/booking_repository.dart';
import '../widgets/back_circle_button.dart';
import '../widgets/time_slot_chip.dart';
import 'review_booking_screen.dart';

class TimeSlotsScreen extends StatefulWidget {
  const TimeSlotsScreen({
    super.key,
    required this.doctor,
    required this.day,
    this.rescheduling,
  });

  final Doctor doctor;
  final DayAvailability day;
  final Appointment? rescheduling;

  @override
  State<TimeSlotsScreen> createState() => _TimeSlotsScreenState();
}

class _TimeSlotsScreenState extends State<TimeSlotsScreen> {
  String? _selectedTime;
  bool _saving = false;

  void _onContinue() {
    if (widget.rescheduling != null) {
      _reschedule();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewBookingScreen(
          doctor: widget.doctor,
          day: widget.day,
          time: _selectedTime!,
        ),
      ),
    );
  }

  Future<void> _reschedule() async {
    setState(() => _saving = true);

    final repo = context.read<BookingRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await repo.rescheduleBooking(
        widget.rescheduling!,
        newDate: widget.day.id,
        newTime: _selectedTime!,
      );
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Reschedule request sent.')),
      );
    } on SlotTakenException {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('This time was just taken. Please pick another.'),
        ),
      );
    } on TooLateToChangeException catch (e) {
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } catch (_) {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not reschedule. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final isReschedule = widget.rescheduling != null;

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
              Text(
                '${day.dayName}, ${day.dateLabel}',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.doctor.name}. Pick a time.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  itemCount: day.slots.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 52,
                  ),
                  itemBuilder: (context, index) {
                    final time = day.slots[index];
                    return TimeSlotChip(
                      time: time,
                      selected: time == _selectedTime,
                      onTap: () => setState(() => _selectedTime = time),
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.lightPurple,
                    disabledForegroundColor: AppColors.textSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed:
                  (_selectedTime == null || _saving) ? null : _onContinue,
                  child: _saving
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    isReschedule ? 'Confirm New Time' : 'Continue',
                    style: const TextStyle(fontWeight: FontWeight.w700),
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