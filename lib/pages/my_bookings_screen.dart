import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projet1/pages/qr_scan_screen.dart';



class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}
class _MyBookingsScreenState extends State<MyBookingsScreen> {
  @override
  void initState() {
    super.initState();
    libererReservationsExpirees().catchError((e) {
      debugPrint('Erreur de libération : $e');
    });
  }
  Future<void> libererReservationsExpirees() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snapshot = await FirebaseFirestore.instance.collection('bookings').where('userId', isEqualTo: user.uid).where('status', isEqualTo: 'confirmed').get();
    debugPrint('Nombre de réservations : ${snapshot.docs.length}');
    // Vérifier les réservations dépassant le délai de 15 minutes.
    for (final doc in snapshot.docs) {
      final booking = doc.data();
      final startAt = (booking['startAt'] as Timestamp).toDate();
      // Afficher la date limite de confirmation.
      final dateLimite = startAt.add(const Duration(minutes: 15));
      debugPrint('Date limite : $dateLimite');
      debugPrint('Maintenant : ${DateTime.now()}');
      //afficher la date de début de la reservation.
      debugPrint('Date du début : $startAt');

      if (DateTime.now().isAfter(
        startAt.add(const Duration(minutes: 15)),
      )) {
        // Récupérer les identifiants des créneaux à libérer.
        final bookingRef = doc.reference;
        final slotIds = List<String>.from(booking['slotIds'] ?? []);

        // Libérer les créneaux et marquer la réservation comme expirée.
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final currentBooking = await transaction.get(bookingRef);

          if (!currentBooking.exists || currentBooking.data()?['status'] != 'confirmed') {
            return;
          }

          final slotRefs = slotIds.map((id) => FirebaseFirestore.instance.collection('slots').doc(id)).toList();

          for (final ref in slotRefs) {await transaction.get(ref);
          }

          transaction.update(bookingRef, {'status': 'expired', 'expiredAt': FieldValue.serverTimestamp(),
          });

          for (final ref in slotRefs) {transaction.delete(ref);
          }
        });
      }
    }
  }

  Future<void> cancelBooking(
      BuildContext context,
      String bookingId,
      Map<String, dynamic> booking,
      ) async {
    final startAt = (booking['startAt'] as Timestamp).toDate();
    // Vérifier si la réservation a dépassé le délai de 15 minutes.
    final dateLimite = startAt.add(const Duration(minutes: 15));
    debugPrint('Date limite : $dateLimite');
    debugPrint('Maintenant : ${DateTime.now()}');

    if (DateTime.now().isAfter(
      startAt.subtract(const Duration(hours: 1)),
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Annulation impossible : moins d’une heure avant le début.',
          ),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la réservation ?'),
        content: const Text('Voulez-vous vraiment annuler cette réservation ?',),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final bookingRef = FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId);

      final slotIds = List<String>.from(booking['slotIds'] ?? []);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final slotRefs = slotIds
            .map((id) => FirebaseFirestore.instance.collection('slots').doc(id))
            .toList();

        for (final ref in slotRefs) {
          await transaction.get(ref);
        }

        transaction.update(bookingRef, {
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
        });

        for (final ref in slotRefs) {
          transaction.delete(ref);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Réservation annulée avec succès !'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

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
                    Icon(
                      booking['resourceType'] == 'Terrain'
                          ? Icons.sports_soccer
                          : Icons.meeting_room,
                      color: const Color(0xFF2457A7),
                      size: 28,
                    ),
                  const SizedBox(width: 10),
                    // Afficher le nom de la ressource réservée.
                    Expanded(
                      child: Text(
                        booking['resourceType'] == 'Terrain'
                            ? 'Terrain : ${booking['roomName'] ?? ''}'
                            : 'Salle : ${booking['roomName'] ?? ''}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,),
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
                      // Affichage du statut de la réservation et du bouton d'annulation.
                      if (booking['status'] == 'confirmed') ...[
                        const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                                Text(
                                  'Réservation confirmée',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                ],
                              ),
                              const SizedBox(height: 15),
                        // Ouvrir l'écran de scan pour confirmer la présence.
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => QrScanScreen(bookingId: bookings[index].id, roomId: booking['roomId'] ?? '',),
                                ),
                              );
                            },
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Confirmer ma présence'),
                          ),
                        ),
                        const SizedBox(height: 10),
                              //Annuler la reservation.
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(onPressed: () => cancelBooking(context, bookings[index].id, booking,),
                                  icon: const Icon(Icons.cancel_outlined),
                                  label: const Text('Annuler la réservation'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white,),
                                ),
                              ),
                      // Afficher le statut correct de la réservation.
                    ] else if (booking['status'] == 'present') ...[const Row(children: [
                Icon(Icons.verified, color: Colors.green),
                SizedBox(width: 8),
                Text('Présence confirmée', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold,),
                ),
                ],
              ),
                      // Afficher le statut de la réservation selon son état.
                    ] else if (booking['status'] == 'expired') ...[
                const Row(
                children: [
                Icon(Icons.access_time, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Réservation expirée',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ],
              ),
              ] else ...[
              const Row(children: [Icon(Icons.cancel, color: Colors.red),SizedBox(width: 8),
              Text('Réservation annulée',style: TextStyle(color: Colors.red,fontWeight: FontWeight.bold)),
              ],
              ),
              ],
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