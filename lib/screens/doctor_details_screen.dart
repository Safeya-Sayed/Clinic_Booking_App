import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/day_availability.dart';
import '../models/doctor.dart';
import '../repositories/clinic_repository.dart';
import '../widgets/back_circle_button.dart';
import '../widgets/day_card.dart';
import 'time_slots_screen.dart';

/// Doctor details: About + "Select an available day".
/// (The clinic location map will be added at the end of the project.)
class DoctorDetailsScreen extends StatefulWidget {
  const DoctorDetailsScreen({super.key, required this.doctor});

  final Doctor doctor;

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  late final Future<List<DayAvailability>> _future;

  @override
  void initState() {
    super.initState();
    _future =
        context.read<ClinicRepository>().getAvailableDays(widget.doctor.id);
  }

  void _onDaySelected(DayAvailability day) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TimeSlotsScreen(doctor: widget.doctor, day: day),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctor = widget.doctor;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE6D6E4), AppColors.background],
            stops: [0.0, 0.35],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            children: [
              Row(
                children: [
                  const BackCircleButton(),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      doctor.specialtyName,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                doctor.name,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                doctor.about,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Select an available day',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              FutureBuilder<List<DayAvailability>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 30),
                      child: Center(
                        child:
                            CircularProgressIndicator(color: AppColors.primary),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Text('Could not load available days.');
                  }
                  final days = snapshot.data ?? <DayAvailability>[];
                  if (days.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Text(
                        'No available days for this doctor.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final day in days)
                        DayCard(day: day, onTap: () => _onDaySelected(day)),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
