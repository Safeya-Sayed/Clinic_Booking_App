import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/appointment.dart';
import '../utils/assistant_formatters.dart';
import 'initials_avatar.dart';
import 'status_chip.dart';

/// One row of the Booking Requests list:
/// patient avatar + name + "Doctor, Sun 22 Nov, 11:00" + status.
class RequestCard extends StatelessWidget {
  const RequestCard({super.key, required this.appointment, required this.onTap});

  final Appointment appointment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = appointment;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            InitialsAvatar(initials: initialsOf(a.patientName)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.patientName.isEmpty ? 'Unknown patient' : a.patientName,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${a.doctorName}, ${shortDayLabel(a)}, ${a.time}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusChip(status: a.status),
          ],
        ),
      ),
    );
  }
}