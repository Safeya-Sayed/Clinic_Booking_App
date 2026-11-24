import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../utils/assistant_formatters.dart';

/// Patient tab 3: account info, notification switches, log out.
class PatientSettingsScreen extends StatefulWidget {
  const PatientSettingsScreen({super.key});

  @override
  State<PatientSettingsScreen> createState() => _PatientSettingsScreenState();
}

class _PatientSettingsScreenState extends State<PatientSettingsScreen> {
  bool _bookingUpdates = true;
  bool _reminders = true;
  String? _name; // name after editing

  static const TextStyle _rowStyle = TextStyle(
    color: AppColors.text,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  Future<void> _editName() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final ctrl = TextEditingController(text: _name ?? user.name);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit profile'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Full name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    final newName = ctrl.text.trim();
    if (ok != true || newName.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'name': newName});
      if (!mounted) return;
      setState(() => _name = newName);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not update your name.')),
      );
    }
  }

  Future<void> _changePassword() async {
    final email = context.read<AuthProvider>().user?.email ?? '';
    final messenger = ScaffoldMessenger.of(context);
    if (email.isEmpty) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      messenger.showSnackBar(
        SnackBar(content: Text('Password reset link sent to $email')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not send the reset email.')),
      );
    }
  }

  Future<void> _logout() async {
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context, rootNavigator: true);
    await auth.logout();
    navigator.pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final name = _name ?? user?.name ?? 'Your name';
    const divider = Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: AppColors.border,
    );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          _card([
            ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.lightPurple,
                child: Text(
                  initialsOf(name),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              title: Text(
                name,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(user?.email ?? ''),
            ),
          ]),
          _label('ACCOUNT'),
          _card([
            _link('Edit profile', _editName),
            divider,
            _link('Change password', _changePassword),
          ]),
          _label('NOTIFICATIONS'),
          _card([
            _switch('Booking updates', _bookingUpdates,
                    (v) => setState(() => _bookingUpdates = v)),
            divider,
            _switch('Appointment reminders', _reminders,
                    (v) => setState(() => _reminders = v)),
          ]),
          const SizedBox(height: 22),
          SizedBox(
            height: 54,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB3261E),
                side: const BorderSide(color: Color(0xFFF3CFCF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: _logout,
              child: const Text(
                'Log Out',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 22, 0, 8),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _card(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: AppColors.cardShadow,
    ),
    child: Column(children: children),
  );

  Widget _link(String label, VoidCallback onTap) => ListTile(
    title: Text(label, style: _rowStyle),
    trailing: const Icon(
      Icons.chevron_right_rounded,
      color: AppColors.textSecondary,
    ),
    onTap: onTap,
  );

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged) =>
      ListTile(
        title: Text(label, style: _rowStyle),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primary,
          thumbColor: const WidgetStatePropertyAll(Colors.white),
        ),
      );
}