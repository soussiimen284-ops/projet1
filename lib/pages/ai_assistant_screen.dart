
import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    // Extraire la durée souhaitée de la réservation.
    final dureeDemandee = question.toLowerCase().contains('deux heures') || question.toLowerCase().contains('2 heures') ? 2 : 1;
    // Identifier le type de ressource demandé par l'étudiant.
    final demande = question.toLowerCase();
    // Détecter si l'étudiant demande un créneau dans l'après-midi.
    final demandeApresMidi = demande.contains('après-midi') || demande.contains('apres-midi');
    // Extraire le nombre de personnes demandé par l'étudiant.
    final personnesMatch = RegExp(r'(\d+)\s*(personnes|places|étudiants|etudiants)').firstMatch(demande);
    final personnesDemandees = personnesMatch == null ? null : int.tryParse(personnesMatch.group(1)!);

// Détecter si l'étudiant demande un projecteur.
    final demandeProjecteur = demande.contains('projecteur');
    String? typeDemande;

    if (demande.contains('laboratoire') || demande.contains('labo')) {
      typeDemande = 'laboratoire';
    } else if (demande.contains('terrain')) {
      typeDemande = 'terrain';
    } else if (demande.contains('salle')) {
      typeDemande = 'salle';
    }
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
          'Tu es un assistant universitaire. '
              'Analyse la demande suivante et identifie la date demandée. '
              'La date actuelle est ${DateTime.now()}. '
              'Réponds uniquement avec une date au format yyyy-MM-dd. '
              'Si la date est impossible à identifier, réponds INCONNUE. '
              'Demande : $question',
        ),
      ]);

      final dateTexte = result.text?.trim();

      if (dateTexte == null ||
          !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateTexte)) {
        throw Exception('Veuillez préciser la date souhaitée.');
      }

      // Convertir la date comprise par Gemini.
      final parties = dateTexte.split('-');
      final date = DateTime(
        int.parse(parties[0]),
        int.parse(parties[1]),
        int.parse(parties[2]),
      );

      // Rechercher les créneaux réellement disponibles.
      final propositions = <String>[];

      for (final ressource in ressources) {
        if (typeDemande != null && ressource['type'].toString().toLowerCase() != typeDemande) {
          continue;
        }
        // Vérifier la capacité de la ressource demandée.
        final capacite = int.tryParse(ressource['capacite'].toString()) ?? 0;
        if (personnesDemandees != null && capacite < personnesDemandees) {
          continue;
        }

// Vérifier la présence du projecteur dans les équipements.
        final equipements = ressource['equipements'].toString().toLowerCase();

        if (demandeProjecteur && !equipements.contains('projecteur')) {
          continue;
        }
        final creneaux = await calculerCreneauxDisponibles(ressource, date, dureeDemandee);

        for (final creneau in creneaux) {
          final heureCreneau = int.parse(creneau.split(':')[0]);
          // Ignorer les créneaux en dehors de l'après-midi (12h à 18h).
          if (demandeApresMidi && (heureCreneau < 12 || heureCreneau >= 18)) {
            continue;
          }

          if (heureDemandee != null && heureCreneau != heureDemandee) {
            continue;
          }
          final reference = (ressource['id'] as String).substring(0, 6);

          final heureFin = heureCreneau + dureeDemandee;

          propositions.add('${ressource['nom']} (Réf. $reference) ''de $creneau à ${heureFin.toString().padLeft(2, '0')}:00',);

          if (propositions.length == 3) break;
        }

        if (propositions.length == 3) break;
      }

      if (!mounted) return;

      setState(() {
        reponse = propositions.isEmpty ? (heureDemandee != null
            ? 'Aucun créneau disponible à ${heureDemandee.toString().padLeft(2, '0')}:00 pour cette durée.'
            : 'Aucun créneau disponible pour cette date.')
            : 'Voici les créneaux disponibles :\n'
            '${propositions.join('\n')}';
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                child: Text(reponse!),
              ),
            ],
          ],

        ),
      ),
    );
  }
}
