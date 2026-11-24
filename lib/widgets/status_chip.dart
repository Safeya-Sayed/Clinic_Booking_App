import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/appointment.dart';

/// Pending / Confirmed / Rejected pill (same colors as the patient side).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.lightPurple;
    Color fg = AppColors.textSecondary;

    if (status == AppointmentStatus.pending) {
      bg = const Color(0xFFFFF3D6);
      fg = const Color(0xFF8A6D1F);
    } else if (status == AppointmentStatus.confirmed) {
      bg = AppColors.greenBg;
      fg = AppColors.greenText;
    } else if (status == AppointmentStatus.rejected) {
      bg = const Color(0xFFFBE3E3);
      fg = const Color(0xFFB3261E);
    }

    final label = status.isEmpty
        ? ''
        : status[0].toUpperCase() + status.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}