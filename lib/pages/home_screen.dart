import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projet1/pages/room_booking_screen.dart';
import 'package:projet1/pages/my_bookings_screen.dart';
import 'package:projet1/pages/ai_assistant_screen.dart';
import 'resource_management_screen.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
// Lire le rôle de l'utilisateur depuis Firestore.
return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
future: FirebaseFirestore.instance.collection('users').doc(user!.uid).get(),
builder: (context, snapshot) {
if (!snapshot.hasData) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
}

final role = snapshot.data!.data()?['role'] ?? 'etudiant';

return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text('Réservation Campus'), backgroundColor: const Color(0xFF2457A7),foregroundColor: Colors.white,centerTitle: true),

      body: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           Text(role == 'responsable'?'Espace Responsable':'Bienvenue!', style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
            // Afficher la question uniquement dans l'espace étudiant.
            if (role == 'etudiant') ...[const Text('Que souhaitez-vous réserver ?', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 25),
            ],
          Expanded(child: GridView.count(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, children: [
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const RoomBookingScreen()));
              },
              child: _serviceCard(Icons.meeting_room, 'Réserver une salle', Colors.blue),
            ),
            // Ouvrir la liste des terrains à réserver.
            _serviceCard(Icons.sports_soccer, 'Réserver un terrain', Colors.green, onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const RoomBookingScreen(typeRessource: 'Terrain'),
                  ),
                );
              },
            ),
                _serviceCard(Icons.calendar_month, 'Mes réservations', Colors.orange, onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const MyBookingsScreen()),
                );
              },
            ),
            // Ouvrir la liste des réservations pour confirmer la présence.
            _serviceCard(Icons.qr_code_scanner, 'Scanner QR Code', Colors.purple, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MyBookingsScreen()),
                );
              },
            ),
            // Ouvrir l'écran de l'assistant intelligent.
            _serviceCard(Icons.smart_toy, 'Assistant IA', Colors.teal, onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AiAssistantScreen()),
                );
              },
            ),

            //afficher la gestion des resources uniquement por la responsable.
            if(role == 'responsable')
              _serviceCard(Icons.admin_panel_settings, 'Gestion des ressources', Colors.indigo,
                onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const ResourceManagementScreen()));
                },
              ),
              ],
            ),
          ),
          ],
        ),
      ),
);
},
);
  }

  Widget _serviceCard(IconData icon, String title, Color color, {VoidCallback? onTap,}) {
    return Card(elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(borderRadius: BorderRadius.circular(18),onTap: onTap,
        child: Column(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 42, color: color),
            const SizedBox(height: 12),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}