import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/doctor.dart';
import '../models/specialty.dart';
import '../repositories/clinic_repository.dart';
import '../widgets/back_circle_button.dart';
import '../widgets/doctor_card.dart';
import 'doctor_details_screen.dart';

/// Doctors of one specialty: "Choose a doctor".
class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key, required this.specialty});

  final Specialty specialty;

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  late final Future<List<Doctor>> _future;

  @override
  void initState() {
    super.initState();
    _future = context
        .read<ClinicRepository>()
        .getDoctors(specialtyId: widget.specialty.id);
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
              const BackCircleButton(),
              const SizedBox(height: 22),
              Text(
                widget.specialty.name,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose a doctor',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: FutureBuilder<List<Doctor>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.primary),
                      );
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Could not load doctors.'),
                      );
                    }
                    final doctors = snapshot.data ?? <Doctor>[];
                    if (doctors.isEmpty) {
                      return const Center(
                        child: Text(
                          'No doctors in this specialty yet.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: doctors.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 168,
                      ),
                      itemBuilder: (context, index) {
                        final doctor = doctors[index];
                        return DoctorCard(
                          doctor: doctor,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  DoctorDetailsScreen(doctor: doctor),
                            ),
                          ),
                        );
                      },
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
}
