import 'package:flutter/material.dart';

// Écran de gestion des ressources par le responsable.
// Gérer les ressources avec des champs modifiables.
class ResourceManagementScreen extends StatefulWidget {
  const ResourceManagementScreen({super.key});

  @override
  State<ResourceManagementScreen> createState() =>
      _ResourceManagementScreenState();
}

class _ResourceManagementScreenState
    extends State<ResourceManagementScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text('Gestion des ressources'),
        backgroundColor: const Color(0xFF2457A7),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      // Afficher le formulaire de gestion des ressources.
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Ajouter une ressource',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // Saisir le nom de la ressource.
            TextField(
              decoration: InputDecoration(
                labelText: 'Nom de la ressource',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.meeting_room),
              ),
            ),

            const SizedBox(height: 15),

            // Choisir le type de la ressource.
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Type de ressource',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Salle',
                  child: Text('Salle'),
                ),
                DropdownMenuItem(
                  value: 'Laboratoire',
                  child: Text('Laboratoire'),
                ),
                DropdownMenuItem(
                  value: 'Terrain',
                  child: Text('Terrain'),
                ),
              ],
              onChanged: (value) {},
            ),
            const SizedBox(height: 15),
            // Saisir la capacité de la ressource.
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Capacité',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people),
              ),
            ),
            const SizedBox(height: 15),
            // Saisir les équipements disponibles.
            TextField(
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Équipements',
                hintText: 'Exemple : PC, Projecteur, Tableau',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.devices),
              ),
            ),
            const SizedBox(height: 15),

            // Saisir l'heure d'ouverture de la ressource.
            TextField(
              decoration: const InputDecoration(
                labelText: 'Heure d’ouverture (ex: 08:00)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.access_time),
              ),
            ),

            const SizedBox(height: 15),
            // Saisir l'heure de fermeture de la ressource.
            TextField(
              decoration: const InputDecoration(
                labelText: 'Heure de fermeture (ex: 17:00)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.access_time_filled),
              ),
            ),
          ],
        ),
      ),
    );
  }
}