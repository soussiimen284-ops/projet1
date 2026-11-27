
import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projet1/pages/booking_screen.dart';
import 'dart:convert';


// Écran de l'assistant intelligent pour aider les étudiants.
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController questionController = TextEditingController();
// Stocker la réponse de l'assistant et gérer le chargement.
  String? reponse;
  bool chargement = false;
  List<Map<String, dynamic>> propositions = [];
  // Récupérer les ressources réellement enregistrées dans Firestore.
  Future<List<Map<String, dynamic>>> recupererRessources() async {
    final snapshot = await FirebaseFirestore.instance.collection('ressources').get();
    return snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data(),
      };
    }).toList();
  }
  // Récupérer les heures déjà réservées pour une ressource et une date.
  Future<List<int>> recupererHeuresOccupees(
      String roomId,
      DateTime date,
      ) async {
    final debutJournee = DateTime(date.year, date.month, date.day);
    final finJournee = debutJournee.add(const Duration(days: 1));

    final snapshot = await FirebaseFirestore.instance
        .collection('slots')
        .where('roomId', isEqualTo: roomId)
        .where(
      'date',
      isGreaterThanOrEqualTo: Timestamp.fromDate(debutJournee),
    )
        .where('date', isLessThan: Timestamp.fromDate(finJournee))
        .where('status', isEqualTo: 'reserved')
        .get();

    return snapshot.docs
        .map((doc) => (doc.data()['hour'] as num).toInt())
        .toList();
  }
  // Calculer les créneaux réellement disponibles pour une ressource.
  Future<List<String>> calculerCreneauxDisponibles(
      Map<String, dynamic> ressource,
      DateTime date,
      int duree,
      ) async {
    final roomId = ressource['id'] as String;

    final ouverture = ressource['ouverture'].toString().split(':');
    final fermeture = ressource['fermeture'].toString().split(':');

    final heureDebut = int.parse(ouverture[0]);
    final heureFin = int.parse(fermeture[0]);

    final heuresOccupees = await recupererHeuresOccupees(roomId, date);

    final creneaux = <String>[];

    for (int heure = heureDebut; heure + duree <= heureFin; heure++) {
      bool disponible = true;

      for (int i = 0; i < duree; i++) {
        if (heuresOccupees.contains(heure + i)) {
          disponible = false;
          break;
        }
      }

      if (disponible) {
        creneaux.add(
          '${heure.toString().padLeft(2, '0')}:00',
        );
      }
    }

    return creneaux;
  }

  // Analyser la demande et proposer uniquement des disponibilités réelles.
  Future<void> envoyerQuestion() async {
    final question = questionController.text.trim();
    // Extraire l'heure souhaitée dans la demande de l'étudiant.
    final heureMatch = RegExp(
      r'(?:à|vers)\s*(\d{1,2})(?:h|:00)?',
      caseSensitive: false,
    ).firstMatch(question);

    final heureDemandee = heureMatch == null
        ? null
        : int.tryParse(heureMatch.group(1)!);
      int dureeDemandee = 1;
    // Identifier le type de ressource demandé par l'étudiant.
    final demande = question.toLowerCase();
    // Détecter si l'étudiant demande un créneau dans l'après-midi.
    final demandeApresMidi = demande.contains('après-midi') || demande.contains('apres-midi');
    // Extraire le nombre de personnes demandé par l'étudiant.
    final personnesMatch = RegExp(r'(\d+)\s*(personnes|places|étudiants|etudiants)').firstMatch(demande);
    final personnesDemandees = personnesMatch == null ? null : int.tryParse(personnesMatch.group(1)!);

    if (question.isEmpty) return;

    setState(() {
      chargement = true;
      reponse = null;
    });

    try {
      // Récupérer les ressources enregistrées dans Firestore.
      final ressources = await recupererRessources();

      // Demander à Gemini de comprendre la demande de l'étudiant.
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.5-flash-lite',
      );
      final result = await model.generateContent([
        Content.text(
          'Tu es un assistant universitaire pour la réservation de salles et terrains. '
              'Analyse la demande de l étudiant et retourne uniquement un objet JSON valide, sans Markdown. '
              'La date actuelle est ${DateTime.now()}. '
              'Le JSON doit contenir exactement les champs suivants : '
              '"type", "equipements", "date", "heure", "duree". '
              '"type" doit être salle, laboratoire ou terrain. '
              '"equipements" doit être une liste de chaînes de caractères. '
              '"date" doit être au format yyyy-MM-dd. '
              '"heure" doit être au format HH:mm. '
              '"duree" doit être 1 ou 2 heures. '
              'Si une information est absente ou impossible à identifier, utilise null pour cette information. '
              'Ne devine jamais une information. '
              'Demande : $question',
        ),
      ]);

      final texteJson = result.text?.trim();

      if (texteJson == null || texteJson.isEmpty) {
        throw Exception('Aucune réponse de Gemini.');
      }

      Map<String, dynamic> criteresIA;

      try {
        criteresIA = jsonDecode(texteJson) as Map<String, dynamic>;
      } catch (e) {
        throw Exception('Réponse JSON invalide.');
      }

      final typeIA = criteresIA['type']?.toString();
      final equipementsIA = criteresIA['equipements'] is List ? List<String>.from(criteresIA['equipements'])
          : <String>[];

      final dateTexte = criteresIA['date']?.toString();
      final heureTexte = criteresIA['heure']?.toString();
      final dureeIA = criteresIA['duree'];

      if (dateTexte == null ||
          !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateTexte)) {
        throw Exception('Veuillez préciser la date souhaitée.');
      }

      if (dureeIA != 1 && dureeIA != 2) {
        throw Exception('La durée doit être de 1 ou 2 heures.');
      }
      dureeDemandee = dureeIA as int;

      if (typeIA != null &&
          !['salle', 'laboratoire', 'terrain'].contains(typeIA.toLowerCase())) {
        throw Exception('Type de ressource invalide.');
      }

      if (heureTexte != null && !RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(heureTexte)) {
        throw Exception('Veuillez préciser une heure valide.');
      }

      // Convertir la date comprise par Gemini.
      final parties = dateTexte.split('-');
      final date = DateTime(
        int.parse(parties[0]),
        int.parse(parties[1]),
        int.parse(parties[2]),
      );

      // Rechercher les créneaux réellement disponibles.
      propositions = [];

      for (final ressource in ressources) {
        if (typeIA != null && ressource['type'].toString().toLowerCase() != typeIA.toLowerCase()) {
          continue;
        }
        // Vérifier la capacité de la ressource demandée.
        final capacite = int.tryParse(ressource['capacite'].toString()) ?? 0;
        if (personnesDemandees != null && capacite < personnesDemandees) {
          continue;
        }

// Vérifier la présence du projecteur dans les équipements.
        final equipements = ressource['equipements'].toString().toLowerCase();

        final equipementsDisponibles = equipementsIA.every((equipement) => equipements.contains(equipement.toLowerCase()));

        if (!equipementsDisponibles) {
          continue;
        }
        final creneaux = await calculerCreneauxDisponibles(ressource, date, dureeDemandee);

        for (final creneau in creneaux) {
          final heureCreneau = int.parse(creneau.split(':')[0]);
          // Ignorer les créneaux en dehors de l'après-midi (12h à 18h).
          if (demandeApresMidi && (heureCreneau < 12 || heureCreneau >= 18)) {
            continue;
          }

          if (heureTexte != null && creneau != heureTexte) {
            continue;
          }
          final reference = (ressource['id'] as String).substring(0, 6);

          propositions.add({
            'roomId': ressource['id'],
            'roomName': ressource['nom'],
            'resourceType': ressource['type'],
            'ouverture': ressource['ouverture'],
            'fermeture': ressource['fermeture'],
            'date': date,
            'heure': creneau,
            'duree': dureeDemandee,
            'reference': reference,
          });

          if (propositions.length == 3) break;
        }

        if (propositions.length == 3) break;
      }

      if (!mounted) return;

      setState(() {
        reponse = propositions.isEmpty
            ? (heureDemandee != null
            ? 'Aucun créneau disponible à ${heureDemandee.toString().padLeft(2, '0')}:00 pour cette durée.' : 'Aucun créneau disponible pour cette date.') : 'Voici les créneaux disponibles :';
        chargement = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        reponse = 'Erreur : $e';
        chargement = false;
      });
    }
  }


  @override
  void dispose() {
    questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant intelligent'),
      ),
        body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
            const Icon(
              Icons.smart_toy,
              size: 70,
              color: Colors.blue,
            ),
            const SizedBox(height: 15),
            const Text(
              'Comment puis-je vous aider ?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: questionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Exemple : Je cherche une salle demain...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                //lancer l'envoi de la question a gemini.
                onPressed: envoyerQuestion,
                icon: const Icon(Icons.send),
                label: const Text('Envoyer'),
              ),
            ),
            // Afficher le chargement pendant la réponse de Gemini.
            if (chargement)
              const CircularProgressIndicator(),

            // Afficher la réponse de l'assistant.
            if (reponse != null) ...[
              const SizedBox(height: 20),
              Text(reponse!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              ...propositions.map((proposition) {
                final date = proposition['date'] as DateTime;

                return Card(child: ListTile(leading: const Icon(Icons.meeting_room, color: Colors.blue),
                    title: Text(proposition['roomName'].toString()),
                    subtitle: Text(
                      'Date : ${date.day}/${date.month}/${date.year}\n'
                          'Heure : ${proposition['heure']}\n'
                          'Durée : ${proposition['duree']} heure(s)',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (context) => BookingScreen(
                            roomId: proposition['roomId'].toString(),
                            roomName: proposition['roomName'].toString(),
                            resourceType: proposition['resourceType'].toString(),
                            ouverture: proposition['ouverture'].toString(),
                            fermeture: proposition['fermeture'].toString(),
                            initialDate: date,
                            initialHour: proposition['heure'].toString(),
                            initialDuration: proposition['duree'] as int,
                          ),
                        ),
                      );
                    },
                  ),
                );

              }),
            ],
                  ],
              ),
              ),
            ),
        ),
    );
  }
}