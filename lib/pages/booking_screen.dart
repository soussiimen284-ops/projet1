import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class BookingScreen extends StatefulWidget {
  final String roomName;
  const BookingScreen({
    super.key,
    required this.roomName,
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Réservation'),
        backgroundColor: const Color(0xFF2457A7),
        foregroundColor: Colors.white,
      ),
      body: Padding(
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
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: focusedDay,
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
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            '08:00',
            '09:00',
            '10:00',
            '11:00',
            '12:00',
            '13:00',
            '14:00',
            '15:00',
          ].map((hour) {
            return ChoiceChip(
              label: Text(hour),
              selected: selectedHour == hour,
              onSelected: (value){
                setState(() {
                                  selectedHour = hour;
                                });
              },
            );
          }).toList(),
          ),
            const SizedBox(height: 20),

            const Text(
              'Durée de réservation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            DropdownButton<int>(
              value: selectedDuration,
              items: const [
                DropdownMenuItem(
                  value: 1,
                  child: Text('1 heure'),
                ),
                DropdownMenuItem(
                  value: 2,
                  child: Text('2 heures'),
                ),
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
              child: ElevatedButton(
                onPressed: () {
                  if (selectedHour == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Veuillez choisir une heure'),
                      ),
                    );
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sélection effectuée'),
                    ),
                  );
                },
                child: const Text('Confirmer la réservation'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}