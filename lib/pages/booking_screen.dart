import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingScreen extends StatefulWidget {
  final String roomName;
  //definir le type de la ressource
  final String resourceType;
  final String roomId;

  // Récupérer les horaires d'ouverture et de fermeture de la salle.
  final String ouverture;
  final String fermeture;
  final DateTime? initialDate;
  final String? initialHour;
  final int? initialDuration;

  const BookingScreen({
    super.key,
    required this.roomName,
    required this.roomId,
    required this.resourceType,
    this.ouverture = '08:00',
    this.fermeture = '18:00',
    this.initialDate,
    this.initialHour,
    this.initialDuration,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}
class _BookingScreenState extends State<BookingScreen> {
  DateTime selectedDay = DateTime.now();
  String? selectedHour;
  int selectedDuration = 1;
  DateTime focusedDay = DateTime.now();
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);

    if (widget.initialDate != null) {
      selectedDay = widget.initialDate!;
      focusedDay = widget.initialDate!;
    }
    selectedHour = widget.initialHour;
    selectedDuration = widget.initialDuration ?? 1;
  }
  Future<void> confirmerReservation() async {
    if (selectedHour == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez choisir une heure'),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez vous connecter'),
        ),
      );
      return;
    }

    try {
      final startHour = int.parse(selectedHour!.substring(0, 2));
      // Vérifier que la réservation se termine avant la fermeture.
      final closingHour = int.parse(widget.fermeture.substring(0, 2));

      if (startHour + selectedDuration > closingHour) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La réservation dépasse l’heure de fermeture.'),
          ),
        );
        return;
      }



      final date = DateTime(
        selectedDay.year,
        selectedDay.month,
        selectedDay.day,
      );
      // Calculer le début et la fin de la semaine de réservation.
      final weekStart = DateTime(
        date.year,
        date.month,
        date.day,
      ).subtract(Duration(days: date.weekday - 1));

      final weekEnd = weekStart.add(const Duration(days: 7));

      // Récupérer les réservations confirmées de l'étudiant.
      final weeklyBookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'confirmed')
          .get();

     // Calculer le nombre d'heures déjà réservées cette semaine.
      final weeklyHours = weeklyBookings.docs
          .where((doc) {
        final bookingDate = (doc.data()['date'] as Timestamp).toDate();
        return !bookingDate.isBefore(weekStart) &&
            bookingDate.isBefore(weekEnd);
      })
          .fold<int>(
        0,
            (total, doc) =>
        total + ((doc.data()['duration'] as num?)?.toInt() ?? 0),
      );

      // Vérifier que l'étudiant ne dépasse pas 4 heures par semaine.
      if (weeklyHours + selectedDuration > 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous avez atteint la limite de 4 heures par semaine.',),
          ),
        );
        return;
      }

      final startAt = DateTime(
        date.year,
        date.month,
        date.day,
        startHour,
      );

      final bookingRef = FirebaseFirestore.instance.collection('bookings').doc();

      final slotRefs = List.generate(selectedDuration, (index) {
        final hour = startHour + index;
        final hourText = hour.toString().padLeft(2, '0');

        final slotId =
            '${widget.roomId}_${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}_$hourText';

        return FirebaseFirestore.instance.collection('slots').doc(slotId);
      });

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshots = [];

        for (final ref in slotRefs) {
          snapshots.add(await transaction.get(ref));
        }

        if (snapshots.any((snapshot) => snapshot.exists)) {
          throw Exception('Ce créneau est déjà réservé');
        }

        for (int i = 0; i < slotRefs.length; i++) {
          transaction.set(slotRefs[i], {'roomId': widget.roomId, 'roomName': widget.roomName,
            'resourceType': widget.resourceType,
            'userId': user.uid, 'bookingId': bookingRef.id,
            'date': Timestamp.fromDate(date), 'hour': startHour + i, 'status': 'reserved', 'createdAt': FieldValue.serverTimestamp(),
          });
        }

        transaction.set(bookingRef, {
          'roomId': widget.roomId,
          'roomName': widget.roomName,
          'resourceType': widget.resourceType,
          'userId': user.uid,
          'slotIds': slotRefs.map((ref) => ref.id).toList(),
          'date': Timestamp.fromDate(date),
          'startAt': Timestamp.fromDate(startAt),
          'duration': selectedDuration,
          'status': 'confirmed',
          'createdAt': FieldValue.serverTimestamp()}
        );
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Réservation enregistrée avec succès !'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Réservation'),
        backgroundColor: const Color(0xFF2457A7),
        foregroundColor: Colors.white,
      ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
             'Salle : ${widget.roomName}',
              style: const TextStyle(fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Choisir une date',
              style: TextStyle(fontSize: 18),
            ),
            TableCalendar(
              locale: 'fr_FR',
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: focusedDay,
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Color(0xFF2457A7),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Color(0xFFB8D2F5),
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              selectedDayPredicate: (day) => isSameDay(selectedDay, day),
              onDaySelected: (selected,focused){
                setState(() {
                                  selectedDay = selected;
                                  focusedDay = focused;
                                });
              },
              ),
            const SizedBox(height: 20),
            const Text('Choisir une heure', style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
            ),
            ),
            const SizedBox(height: 10),
            // Afficher les créneaux disponibles en vert et les créneaux réservés en rouge
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('slots')
                  .where('roomId', isEqualTo: widget.roomId)
                  .where(
                'date',
                isEqualTo: Timestamp.fromDate(
                  DateTime(
                    selectedDay.year,
                    selectedDay.month,
                    selectedDay.day,
                  ),
                ),
              )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Erreur de chargement des horaires');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final occupiedHours = snapshot.data!.docs
                    .map((doc) => doc.data()['hour'] as int)
                    .toSet();
                // Convertir les horaires d'ouverture et de fermeture en heures.
                final openingHour = int.parse(widget.ouverture.substring(0, 2));
                final closingHour = int.parse(widget.fermeture.substring(0, 2));

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children:List.generate(closingHour - openingHour,(index) =>'${(openingHour + index).toString().padLeft(2, '0')}:00',).map((hour) {
                    final hourNumber = int.parse(hour.substring(0, 2));
                    final isOccupied = occupiedHours.contains(hourNumber);
                    final isSelected = selectedHour == hour;

                    return ChoiceChip(label: SizedBox(width: 58, height: 58, child: Center(
                          child: Text(hour, style: TextStyle(color: isSelected ? Colors.white : isOccupied ? Colors.red.shade900 : Colors.green.shade900, fontWeight: FontWeight.bold,fontSize: 14),
                          ),
                        ),
                      ),
                      selected: isSelected,
                      showCheckmark: false,
                      backgroundColor: isOccupied ? Colors.red.shade100 : Colors.green.shade100,
                      disabledColor: Colors.red.shade100,
                      selectedColor: const Color(0xFF2457A7),
                      shape: CircleBorder(side: BorderSide(color: isOccupied ? Colors.red : Colors.green, width: 1.3,),
                      ),
                      padding: EdgeInsets.zero,
                      onSelected: isOccupied ? null : (value) {
                        setState(() {
                          selectedHour = hour;
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),

            const Text('Durée de réservation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,),
            ),

            DropdownButton<int>(value: selectedDuration, items: const [DropdownMenuItem(value: 1, child: Text('1 heure'),),
                DropdownMenuItem(value: 2, child: Text('2 heures'),),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedDuration = value;
                  });
                }
              },
            ),
            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: confirmerReservation,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Confirmer la réservation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2457A7),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                ),
              ),
            ),
          ],
            ),
        ),
      ),
    );
  }
}