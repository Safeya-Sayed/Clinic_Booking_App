import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/appointment.dart';
import '../../repositories/booking_repository.dart';
import '../../utils/assistant_formatters.dart';
import '../../widgets/back_circle_button.dart';
import '../../widgets/status_chip.dart';

/// Confirm or reject one booking request.
class RequestDetailsScreen extends StatefulWidget {
  const RequestDetailsScreen({super.key, required this.appointment});

  final Appointment appointment;

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  final TextEditingController _reason = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  /// Runs confirm/reject, then goes back to the list with a message.
  Future<void> _run(Future<bool> Function() action, String doneMessage) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final applied = await action();
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            applied ? doneMessage : 'This request was already handled.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Something went wrong. Try again.')),
      );
    }
  }

  void _confirm() {
    final repo = context.read<BookingRepository>();
    _run(() => repo.confirmBooking(widget.appointment), 'Booking confirmed.');
  }

  void _reject() {
    final repo = context.read<BookingRepository>();
    _run(
          () => repo.rejectBooking(widget.appointment, reason: _reason.text),
      'Request rejected.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.appointment;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: BackCircleButton(),
              ),
              const SizedBox(height: 22),
              const Text(
                'Request Details',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Column(
                          children: [
                            _InfoRow(label: 'Patient', value: a.patientName),
                            _InfoRow(label: 'Doctor', value: a.doctorName),
                            _InfoRow(label: 'Date', value: longDayLabel(a)),
                            _InfoRow(label: 'Time', value: a.time),
                            _InfoRow(
                              label: 'Status',
                              valueWidget: StatusChip(status: a.status),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Reason (if rejecting)',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _reason,
                        enabled: !_busy,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          hintText: 'e.g. Slot taken by an earlier booking',
                          hintStyle:
                          const TextStyle(color: AppColors.textSecondary),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 18,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide:
                            const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide:
                            const BorderSide(color: AppColors.primary),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide:
                            const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
                  ),
                  onPressed: _busy || !a.isPending ? null : _confirm,
                  child: _busy
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Confirm',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB3261E),
                    side: const BorderSide(color: Color(0xFFF3CFCF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _busy || !a.isPending ? null : _reject,
                  child: const Text(
                    'Reject',
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
  const _InfoRow({required this.label, this.value, this.valueWidget});

  final String label;
  final String? value;
  final Widget? valueWidget;

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
          valueWidget ??
              Text(
                value ?? '',
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