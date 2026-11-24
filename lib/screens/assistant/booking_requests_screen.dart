import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/appointment.dart';
import '../../repositories/booking_repository.dart';
import '../../widgets/request_card.dart';
import 'request_details_screen.dart';
/// Assistant tab 0: all Pending requests, live from Firestore.
class BookingRequestsScreen extends StatefulWidget {
  const BookingRequestsScreen({super.key});

  @override
  State<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends State<BookingRequestsScreen> {
  late final Stream<List<Appointment>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = context.read<BookingRepository>().watchPendingRequests();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<List<Appointment>>(
        stream: _stream,
        builder: (context, snapshot) {
          final requests = snapshot.data ?? const <Appointment>[];

          String subtitle;
          if (snapshot.hasError) {
            subtitle = 'Something went wrong';
          } else if (!snapshot.hasData) {
            subtitle = 'Loading...';
          } else if (requests.isEmpty) {
            subtitle = 'No pending requests';
          } else {
            subtitle = '${requests.length} waiting for your decision';
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Booking Requests',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(child: _body(snapshot, requests)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _body(
      AsyncSnapshot<List<Appointment>> snapshot,
      List<Appointment> list,
      ) {
    if (snapshot.hasError) {
      // Usually a Firestore rules problem (permission-denied).
      return Center(
        child: Text(
          'Could not load requests.\n${snapshot.error}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (list.isEmpty) {
      return const Center(
        child: Text(
          'You are all caught up.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) => RequestCard(
        appointment: list[i],
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RequestDetailsScreen(appointment: list[i]),
            ),
          );
        },
      ),
    );
  }
}