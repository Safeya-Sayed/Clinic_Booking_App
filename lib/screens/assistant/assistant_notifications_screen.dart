import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/app_colors.dart';
import '../../models/appointment.dart';
import '../../repositories/booking_repository.dart';
import '../../utils/assistant_formatters.dart';

/// Assistant tab 3: new requests and cancellations, built from appointments.
class AssistantNotificationsScreen extends StatefulWidget {
  const AssistantNotificationsScreen({super.key});

  @override
  State<AssistantNotificationsScreen> createState() =>
      _AssistantNotificationsScreenState();
}

class _AssistantNotificationsScreenState
    extends State<AssistantNotificationsScreen> {
  static const String _prefsKey = 'assistant_read_notifications';

  late final Stream<List<Appointment>> _stream;
  final Set<String> _read = {};

  @override
  void initState() {
    super.initState();
    _stream = context.read<BookingRepository>().watchAllAppointments();
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

  /// Appointments -> notifications (newest first, max 30).
  List<_Notif> _build(List<Appointment> all) {
    final items = <_Notif>[];

    for (final a in all) {
      final when = a.createdAt ?? DateTime.now();
      final details = '${a.doctorName}, ${shortDayLabel(a)}, ${a.time}';

      if (a.isPending) {
        items.add(_Notif(
          key: '${a.id}_pending',
          cancelled: false,
          title: 'New booking request',
          body: '${a.patientName}, $details',
          time: when,
        ));
      } else if (a.isCancelled) {
        items.add(_Notif(
          key: '${a.id}_cancelled',
          cancelled: true,
          title: 'Appointment cancelled',
          body: '${a.patientName} cancelled $details',
          time: when,
        ));
      }
    }

    items.sort((a, b) => b.time.compareTo(a.time));
    return items.take(30).toList();
  }

  String _sectionOf(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final diff = today.difference(day).inDays;
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

          // group by day label (items are already sorted, so order is kept)
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

class _Notif {
  const _Notif({
    required this.key,
    required this.cancelled,
    required this.title,
    required this.body,
    required this.time,
  });

  final String key;
  final bool cancelled;
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
    final bg = notif.cancelled
        ? const Color(0xFFFBE3E3)
        : const Color(0xFFFFF3D6);
    final fg = notif.cancelled
        ? const Color(0xFFB3261E)
        : const Color(0xFF8A6D1F);

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
            child: Icon(
              notif.cancelled ? Icons.close_rounded : Icons.inbox_outlined,
              color: fg,
            ),
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