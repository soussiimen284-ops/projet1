import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';

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
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);
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
        Wrap(
          spacing: 12,
          runSpacing: 12,
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
            final isSelected = selectedHour == hour;

            return ChoiceChip(
              label: SizedBox(
                width: 58,
                height: 58,
                child: Center(
                  child: Text(
                    hour,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF2457A7),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              selected: isSelected,
              showCheckmark: false,
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF2457A7),
              shape: const CircleBorder(
                side: BorderSide(color: Color(0xFF2457A7), width: 1.3),
              ),
              padding: EdgeInsets.zero,
              onSelected: (value) {
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
              child: ElevatedButton.icon(
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