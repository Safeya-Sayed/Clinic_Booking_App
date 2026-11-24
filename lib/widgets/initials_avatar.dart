import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Circle with the doctor's initials (e.g. "AH").
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.initials, this.size = 48});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEADFE9), Color(0xFFD3BAD1)],
        ),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.dark,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}
