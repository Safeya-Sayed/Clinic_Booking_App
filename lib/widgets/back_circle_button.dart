import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class BackCircleButton extends StatelessWidget {
  const BackCircleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: AppColors.cardShadow,
        ),
        child: const Icon(Icons.chevron_left, color: AppColors.text, size: 28),
      ),
    );
  }
}
