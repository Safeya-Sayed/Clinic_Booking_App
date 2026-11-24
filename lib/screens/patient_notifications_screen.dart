import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_colors.dart';
import '../models/appointment.dart';
import '../providers/auth_provider.dart';
import '../repositories/booking_repository.dart';
import '../utils/assistant_formatters.dart';

/// Patient tab 2: updates about my bookings, built from my appointments.
class PatientNotificationsScreen extends StatefulWidget {
  const PatientNotificationsScreen({super.key});

  @override
  State<PatientNotificationsScreen> createState() =>
      _PatientNotificationsScreenState();
}

class _PatientNotificationsScreenState
    extends State<PatientNotificationsScreen> {
  static const String _prefsKey = 'patient_read_notifications';

  late final Stream<List<Appointment>> _stream;
  final Set<String> _read = {};

  @override
  void initState() {
    super.initState();
    final patientId = context.read<AuthProvider>().userId;
    _stream = context.read<BookingRepository>().watchMyAppointments(patientId);
    _loadRead();
  }

  Future<void> _loadRead() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey) ?? const <String>[];
    if (!mounted) return;
    setState(() => _read.addAll(saved));
  }

  Future<void> _markAllRead(List<_Notif> items) async {
    setState(() => _read.addAll(items.map((n) => n.key)));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _read.toList());
  }

  /// My appointments -> notifications (newest first, max 30).
  List<_Notif> _build(List<Appointment> all) {
    final items = <_Notif>[];

    for (final a in all) {
      final when = a.createdAt ?? DateTime.now();
      final details = '${a.doctorName}, ${shortDayLabel(a)}, ${a.time}';

      if (a.isConfirmed) {
        items.add(_Notif('${a.id}_confirmed', _Kind.confirmed,
            'Booking confirmed', details, when));
      } else if (a.isPending) {
        items.add(_Notif('${a.id}_pending', _Kind.pending, 'Request sent',
            '$details is pending', when));
      } else if (a.isRejected) {
        final reason = a.rejectReason.isEmpty
            ? 'the clinic could not take this slot'
            : a.rejectReason;
        items.add(_Notif('${a.id}_rejected', _Kind.rejected,
            'Request rejected', '${a.doctorName}: $reason', when));
      }
    }

    items.sort((a, b) => b.time.compareTo(a.time));
    return items.take(30).toList();
  }

  String _sectionOf(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(DateTime(t.year, t.month, t.day)).inDays;
    if (diff <= 0) return 'TODAY';
    if (diff == 1) return 'YESTERDAY';
    return 'EARLIER';
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<List<Appointment>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Could not load notifications.\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = _build(snapshot.data!);
          final unread = items.where((n) => !_read.contains(n.key)).length;

          final sections = <String, List<_Notif>>{};
          for (final n in items) {
            sections.putIfAbsent(_sectionOf(n.time), () => []).add(n);
          }

          final children = <Widget>[];
          var first = true;
          sections.forEach((label, list) {
            children.add(
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (first && unread > 0)
                      GestureDetector(
                        onTap: () => _markAllRead(items),
                        child: const Text(
                          'Mark all as read',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
            children.addAll(list.map(
                  (n) => _NotifCard(
                notif: n,
                timeLabel: _timeAgo(n.time),
                unread: !_read.contains(n.key),
              ),
            ));
            first = false;
          });

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (unread > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$unread NEW',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: items.isEmpty
                      ? const Center(
                    child: Text(
                      'No notifications yet.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  )
                      : ListView(children: children),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

enum _Kind { confirmed, pending, rejected }

class _Notif {
  const _Notif(this.key, this.kind, this.title, this.body, this.time);

  final String key;
  final _Kind kind;
  final String title;
  final String body;
  final DateTime time;
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({
    required this.notif,
    required this.timeLabel,
    required this.unread,
  });

  final _Notif notif;
  final String timeLabel;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    late final Color bg;
    late final Color fg;

    switch (notif.kind) {
      case _Kind.confirmed:
        icon = Icons.check_rounded;
        bg = AppColors.greenBg;
        fg = AppColors.greenText;
        break;
      case _Kind.pending:
        icon = Icons.access_time_rounded;
        bg = const Color(0xFFFFF3D6);
        fg = const Color(0xFF8A6D1F);
        break;
      case _Kind.rejected:
        icon = Icons.close_rounded;
        bg = const Color(0xFFFBE3E3);
        fg = const Color(0xFFB3261E);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif.title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  notif.body,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeLabel,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              if (unread)
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}