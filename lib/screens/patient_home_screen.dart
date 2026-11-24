import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../widgets/patient_bottom_nav.dart';
import 'my_appointments_screen.dart';
import 'patient_notifications_screen.dart';
import 'patient_settings_screen.dart';
import 'specialties_screen.dart';

/// Patient side shell: bottom navigation + the 4 tabs.
///
/// Tab 0 (Home) = Specialties -> Doctors -> Doctor details. It has its own
/// Navigator, so the bottom bar stays visible on those screens.
class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
  static void openTab(BuildContext context, int index) {
    context
        .findAncestorStateOfType<_PatientHomeScreenState>()
        ?._selectTab(index);
  }
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _index = 0;
  final GlobalKey<NavigatorState> _homeNavKey = GlobalKey<NavigatorState>();
  void _selectTab(int i) => setState(() => _index = i);

  void _onSystemBack() {
    final nav = _homeNavKey.currentState;
    if (_index == 0 && nav != null && nav.canPop()) {
      nav.pop();
    } else if (_index != 0) {
      setState(() => _index = 0);
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onSystemBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: _index,
          children: [
            // Home tab
            Navigator(
              key: _homeNavKey,
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (_) => const SpecialtiesScreen(),
                settings: settings,
              ),
            ),
            // My Appointments
            const MyAppointmentsScreen(),
            // Notifications
            const PatientNotificationsScreen(),
            // Settings
            const PatientSettingsScreen(),
          ],
        ),
        bottomNavigationBar: PatientBottomNav(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}