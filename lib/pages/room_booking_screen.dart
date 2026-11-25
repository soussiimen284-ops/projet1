import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projet1/pages/booking_screen.dart';
import 'dart:convert';

class RoomBookingScreen extends StatelessWidget {
  final String typeRessource;
  const RoomBookingScreen({super.key, this.typeRessource = 'Salle'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: Text(typeRessource == 'Terrain' ? 'Réserver un terrain' : 'Réserver une salle'),
        backgroundColor: const Color(0xFF2457A7),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('ressources').snapshots(),
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
          // Filtrer les ressources selon le type choisi.
          final rooms = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['type'] == typeRessource;
          }).toList();
          // Vérifier si des ressources correspondent au type choisi.
          if (rooms.isEmpty) {
            return Center(
              child: Text(
                typeRessource == 'Terrain' ? 'Aucun terrain disponible' : 'Aucune salle disponible',),
            );
          }
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
                          builder: (context) =>BookingScreen(roomName: room['nom'] ?? 'Salle', roomId: rooms[index].id,
                            resourceType: typeRessource,
                            ouverture: room['ouverture'] ?? '08:00',
                            fermeture: room['fermeture'] ?? '18:00',
                          ),
                        ),
                      );
                    },
                    contentPadding: const EdgeInsets.all(15),

                    // Afficher la photo de la ressource enregistrée dans Firebase.
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: room['photoBase64'] != null ? Image.memory(base64Decode(room['photoBase64']),
                        width: 65,
                        height: 65,
                        fit: BoxFit.cover,
                      )
                          : const Icon(Icons.meeting_room, size: 40),
                    ),

                    title: Text(
                      room['nom'] ?? 'Salle',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Capacité : ${room['capacite'] ?? 0} personnes\n''Équipement : ${(room['equipements'] ?? []).join(', ')}',
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