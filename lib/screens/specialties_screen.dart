import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/doctor.dart';
import '../models/specialty.dart';
import '../repositories/clinic_repository.dart';
import '../widgets/initials_avatar.dart';
import '../widgets/specialty_card.dart';
import 'doctor_details_screen.dart';
import 'doctors_screen.dart';

class _HomeData {
  final List<Specialty> specialties;
  final List<Doctor> doctors;

  _HomeData(this.specialties, this.doctors);
}

/// Patient home: "Choose a Specialty".
class SpecialtiesScreen extends StatefulWidget {
  const SpecialtiesScreen({super.key});

  @override
  State<SpecialtiesScreen> createState() => _SpecialtiesScreenState();
}

class _SpecialtiesScreenState extends State<SpecialtiesScreen> {
  late final Future<_HomeData> _future;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load(context.read<ClinicRepository>());
  }

  Future<_HomeData> _load(ClinicRepository repo) async {
    final specialties = await repo.getSpecialties();
    final doctors = await repo.getDoctors();
    return _HomeData(specialties, doctors);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<_HomeData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(child: Text('Could not load specialties.'));
            }
            return _buildContent(snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget _buildContent(_HomeData data) {
    final q = _query.trim().toLowerCase();

    final specialties = q.isEmpty
        ? data.specialties
        : data.specialties
            .where((s) => s.name.toLowerCase().contains(q))
            .toList();

    final doctors = q.isEmpty
        ? <Doctor>[]
        : data.doctors.where((d) => d.name.toLowerCase().contains(q)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      children: [
        const Text(
          'Choose a Specialty',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'What do you need to be seen for?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
        const SizedBox(height: 18),
        _buildSearchField(),
        const SizedBox(height: 18),
        for (final s in specialties)
          SpecialtyCard(
            specialty: s,
            doctorsCount:
                data.doctors.where((d) => d.specialtyId == s.id).length,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DoctorsScreen(specialty: s)),
            ),
          ),
        if (doctors.isNotEmpty) ...[
          const SizedBox(height: 6),
          const Text(
            'Doctors',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (final d in doctors) _buildDoctorResult(d),
        ],
        if (specialties.isEmpty && doctors.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(
              child: Text(
                'No results found',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppColors.cardShadow,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value),
        decoration: InputDecoration(
          hintText: 'Search specialty or doctor',
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          prefixIcon:
              const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDoctorResult(Doctor doctor) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DoctorDetailsScreen(doctor: doctor)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            InitialsAvatar(initials: doctor.initials, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    doctor.specialtyName,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
