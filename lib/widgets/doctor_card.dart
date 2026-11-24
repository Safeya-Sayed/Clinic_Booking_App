import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/doctor.dart';
import 'initials_avatar.dart';

/// Card used in the 2-column doctors grid.
class DoctorCard extends StatelessWidget {
  const DoctorCard({super.key, required this.doctor, required this.onTap});

  final Doctor doctor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InitialsAvatar(initials: doctor.initials, size: 46),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: doctor.isAvailable
                        ? AppColors.lightPurple
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    doctor.isAvailable ? 'Available' : 'Busy',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              doctor.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              doctor.specialtyName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: AppColors.star, size: 18),
                const SizedBox(width: 3),
                Text(
                  doctor.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${doctor.fee} EGP',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
