import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projet1/pages/booking_screen.dart';


class RoomBookingScreen extends StatelessWidget {
  const RoomBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text('Réserver une salle'),
        backgroundColor: const Color(0xFF2457A7),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('rooms').snapshots(includeMetadataChanges: true),
        builder: (BuildContext  context,AsyncSnapshot<QuerySnapshot> snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError)  {
            return Center(
              child: Text('Erreur: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Pas de données'));
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Collection vide'));
          }

          final rooms = snapshot.data!.docs;
          print('Nomber de salles: ${rooms.length}');

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: rooms.length,

            itemBuilder: (context, index) {

              final room = rooms[index].data()
              as Map<String, dynamic>;

              return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),

                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingScreen(
                            roomName: room['name'] ?? 'Salle',
                            roomId: rooms[index].id,
                          ),
                        ),
                      );
                    },
                    contentPadding: const EdgeInsets.all(15),

                    leading: const Icon(
                      Icons.meeting_room,
                      color: Color(0xFF2457A7),
                      size: 40,
                    ),

                    title: Text(
                      room['name'] ?? 'Salle',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                          'Capacité : ${room['capacity'] ?? 0} personnes\n'
                              'Équipement : ${room['equipment'] ?? ''}',
                        ),
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