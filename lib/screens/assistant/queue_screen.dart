import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/appointment.dart';
import '../../models/doctor.dart';
import '../../repositories/booking_repository.dart';
import '../../repositories/clinic_repository.dart';
import '../../utils/assistant_formatters.dart';

/// Assistant tab 2: today's queue of one doctor.
class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  late DateTime _day;
  List<Doctor> _doctors = [];
  Doctor? _doctor;
  Stream<List<Appointment>>? _stream;
  bool _loadingDoctors = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _day = DateTime(now.year, now.month, now.day);
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    final clinicRepo = context.read<ClinicRepository>();
    try {
      final list = await clinicRepo.getDoctors();
      if (!mounted) return;
      setState(() {
        _doctors = list;
        _loadingDoctors = false;
        if (list.isNotEmpty) {
          _doctor = list.first;
          _loadQueue();
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingDoctors = false);
    }
  }

  /// Starts listening to the queue of the selected doctor and day.
  void _loadQueue() {
    final doctor = _doctor;
    if (doctor == null) return;
    _stream = context
        .read<BookingRepository>()
        .watchQueue(doctor.id, dateKey(_day));
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked == null) return;
    setState(() {
      _day = picked;
      _loadQueue();
    });
  }

  /// Runs Skip / Call next while the buttons are disabled.
  Future<void> _act(Future<void> Function() action) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Something went wrong. Try again.')),
      );
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Queue Management',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              shortDateLabel(_day),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 14),
            _selectors(),
            const SizedBox(height: 16),
            Expanded(child: _content()),
          ],
        ),
      ),
    );
  }

  Widget _selectors() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _doctor?.id,
                hint: const Text('Choose a doctor'),
                items: _doctors
                    .map((d) => DropdownMenuItem(
                  value: d.id,
                  child: Text(d.name),
                ))
                    .toList(),
                onChanged: (id) {
                  if (id == null) return;
                  setState(() {
                    _doctor = _doctors.firstWhere((d) => d.id == id);
                    _loadQueue();
                  });
                },
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: _pickDay,
          icon: const Icon(
            Icons.calendar_month_outlined,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _content() {
    if (_loadingDoctors) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_doctor == null || _stream == null) {
      return const Center(
        child: Text(
          'No doctors found.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
      );
    }

    return StreamBuilder<List<Appointment>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Could not load the queue.\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final queue = snapshot.data!;
        if (queue.isEmpty) {
          return const Center(
            child: Text(
              'No confirmed patients in the queue.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          );
        }

        final repo = context.read<BookingRepository>();
        final current = queue.first;

        return ListView(
          children: [
            _ServingCard(
              patientName: current.patientName,
              canSkip: queue.length > 1 && !_busy,
              canCallNext: !_busy,
              onSkip: () => _act(() => repo.skipInQueue(current)),
              onCallNext: () => _act(() => repo.finishVisit(current)),
            ),
            const SizedBox(height: 22),
            const Text(
              'Queue list',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < queue.length; i++)
              _QueueRow(
                number: i + 1,
                appointment: queue[i],
                serving: i == 0,
              ),
          ],
        );
      },
    );
  }
}

class _ServingCard extends StatelessWidget {
  const _ServingCard({
    required this.patientName,
    required this.canSkip,
    required this.canCallNext,
    required this.onSkip,
    required this.onCallNext,
  });

  final String patientName;
  final bool canSkip;
  final bool canCallNext;
  final VoidCallback onSkip;
  final VoidCallback onCallNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.dark],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Text(
            'Now serving',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            '01',
            style: TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            patientName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white38,
                      side: const BorderSide(color: Colors.white38),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed: canSkip ? onSkip : null,
                    child: const Text(
                      'Skip',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      disabledBackgroundColor: Colors.white54,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed: canCallNext ? onCallNext : null,
                    child: const Text(
                      'Call next',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({
    required this.number,
    required this.appointment,
    required this.serving,
  });

  final int number;
  final Appointment appointment;
  final bool serving;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.lightPurple,
              shape: BoxShape.circle,
            ),
            child: Text(
              number.toString().padLeft(2, '0'),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.patientName,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  appointment.time,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: serving ? AppColors.greenBg : const Color(0xFFFFF3D6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              serving ? 'Serving' : 'Waiting',
              style: TextStyle(
                color: serving ? AppColors.greenText : const Color(0xFF8A6D1F),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}