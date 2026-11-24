import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Floating bottom bar of the patient side:
/// Home - Appointments - Notifications - Settings.
class PatientBottomNav extends StatelessWidget {
  const PatientBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<IconData> _icons = [
    Icons.home_outlined,
    Icons.calendar_month_outlined,
    Icons.notifications_none_rounded,
    Icons.settings_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
          child: Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(34),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_icons.length, (i) {
                final selected = i == currentIndex;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.dark : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _icons[i],
                      color:
                          selected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
