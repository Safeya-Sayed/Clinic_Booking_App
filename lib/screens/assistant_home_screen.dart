import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/assistant_bottom_nav.dart';
import 'assistant/booking_requests_screen.dart';
import 'assistant/schedule_screen.dart';
import 'assistant/queue_screen.dart';
import 'assistant/assistant_notifications_screen.dart';
import 'assistant/assistant_settings_screen.dart';

/// Assistant side shell: bottom navigation + the 5 tabs.
/// All tabs are placeholders until their screens are built.
class AssistantHomeScreen extends StatefulWidget {
  const AssistantHomeScreen({super.key});

  @override
  State<AssistantHomeScreen> createState() => _AssistantHomeScreenState();
}

class _AssistantHomeScreenState extends State<AssistantHomeScreen> {
  int _index = 0;

  void _onSystemBack() {
    if (_index != 0) {
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
          children: const [
            BookingRequestsScreen(),
            ScheduleScreen(),
            QueueScreen(),
            AssistantNotificationsScreen(),
            AssistantSettingsScreen(),
          ],
        ),
        bottomNavigationBar: AssistantBottomNav(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Text(
          '$title\n(coming soon)',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SettingsPlaceholderTab extends StatelessWidget {
  const _SettingsPlaceholderTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Settings\n(coming soon)',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () async {
                final auth = context.read<AuthProvider>();
                final navigator = Navigator.of(context, rootNavigator: true);
                await auth.logout();
                navigator.pushNamedAndRemoveUntil('/login', (route) => false);
              },
              child: const Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }
}