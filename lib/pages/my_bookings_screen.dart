import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Mes réservations'),
        centerTitle: true,
        backgroundColor: const Color(0xFF2457A7),
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(child: Text('Veuillez vous connecter'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Erreur de chargement'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final bookings = snapshot.data!.docs;

          if (bookings.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 70,
                    color: Color(0xFF2457A7),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Aucune réservation pour le moment',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index].data();

              final date =
              (booking['startAt'] as Timestamp).toDate();

              final dateText =
                  '${date.day.toString().padLeft(2, '0')}/'
                  '${date.month.toString().padLeft(2, '0')}/'
                  '${date.year}';

              final hour =
              date.hour.toString().padLeft(2, '0');

              final duration = booking['duration'] ?? 1;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(
                  children: [
                  const Icon(
                  Icons.meeting_room,
                    color: Color(0xFF2457A7),
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      booking['roomName'] ?? 'Salle',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ],
                ),
                const Divider(height: 25),
                Text('Date : $dateText'),
                const SizedBox(height: 10),
                Text('Heure : $hour:00'),
                const SizedBox(height: 10),
                Text('Durée : $duration heure(s)'),
                const SizedBox(height: 15),
                const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8,),
                      Text(
                        'Réservation confirmée',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ],
                    ),
                  ],
                ),
              ),
              );
            },
          );
        },
      ),
    );
  }
}