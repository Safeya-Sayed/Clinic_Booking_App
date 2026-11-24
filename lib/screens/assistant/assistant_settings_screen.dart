import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../utils/assistant_formatters.dart';

/// Assistant tab 4: account info, notification switches, log out.
class AssistantSettingsScreen extends StatefulWidget {
  const AssistantSettingsScreen({super.key});

  @override
  State<AssistantSettingsScreen> createState() =>
      _AssistantSettingsScreenState();
}

class _AssistantSettingsScreenState extends State<AssistantSettingsScreen> {
  static const String _kRequests = 'assistant_notif_requests';
  static const String _kCancellations = 'assistant_notif_cancellations';
  static const String _kQueue = 'assistant_notif_queue';

  bool _requests = true;
  bool _cancellations = true;
  bool _queue = true;

  /// الاسم بعد التعديل (لحد ما الأكونت يتحمّل تاني)
  String? _name;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _requests = prefs.getBool(_kRequests) ?? true;
      _cancellations = prefs.getBool(_kCancellations) ?? true;
      _queue = prefs.getBool(_kQueue) ?? true;
    });
  }

  Future<void> _savePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _editProfile() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final nameCtrl = TextEditingController(text: _name ?? user.name);
    final phoneCtrl = TextEditingController(text: user.phone);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
          ],
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

    if (saved != true) return;

    final newName = nameCtrl.text.trim();
    if (newName.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Name cannot be empty.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': newName,
        'phone': phoneCtrl.text.trim(),
      });
      if (!mounted) return;
      setState(() => _name = newName);
      messenger.showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not update your profile.')),
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
    final name = _name ?? user?.name ?? 'Clinic Assistant';

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
          _card(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.lightPurple,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    initialsOf(name),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Clinic assistant',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _sectionLabel('ACCOUNT'),
          _card(
            child: Column(
              children: [
                _NavRow(label: 'Edit profile', onTap: _editProfile),
                const _Divider(),
                _NavRow(label: 'Change password', onTap: _changePassword),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _sectionLabel('NOTIFICATIONS'),
          _card(
            child: Column(
              children: [
                _SwitchRow(
                  label: 'New booking requests',
                  value: _requests,
                  onChanged: (v) {
                    setState(() => _requests = v);
                    _savePref(_kRequests, v);
                  },
                ),
                const _Divider(),
                _SwitchRow(
                  label: 'Cancellations',
                  value: _cancellations,
                  onChanged: (v) {
                    setState(() => _cancellations = v);
                    _savePref(_kCancellations, v);
                  },
                ),
                const _Divider(),
                _SwitchRow(
                  label: 'Queue alerts',
                  value: _queue,
                  onChanged: (v) {
                    setState(() => _queue = v);
                    _savePref(_kQueue, v);
                  },
                ),
              ],
            ),
          ),
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

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow,
      ),
      child: child,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 18,
      endIndent: 18,
      color: AppColors.border,
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
            thumbColor: const WidgetStatePropertyAll(Colors.white),
          ),
        ],
      ),
    );
  }
}