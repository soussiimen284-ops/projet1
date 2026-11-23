import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
  //stocker la photo sélectionnee par le responsable.
  File? selectesImage;
  //controler le nom de la ressource.
  final TextEditingController nomController = TextEditingController();
  //controler la capacite de la ressource.
  final TextEditingController capaciteController = TextEditingController();
  //controler les equipements de la ressource.
  final TextEditingController equipementsController =TextEditingController();
  // Contrôler l'heure d'ouverture de la ressource.
  final TextEditingController ouvertureController = TextEditingController();
  // Contrôler l'heure d'ferme de la ressource.
  final TextEditingController fermetureController = TextEditingController();
  //Stocker le type de la ressource.
  String? typeRessource;

  //choisir une photo depuis le telephone.
  Future<void> choisirImage() async {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image != null) {
      setState(() {
        selectesImage = File(image.path);
      });
    }
  }

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
              controller: nomController,
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
              // Enregistrer le type de ressource.
              onChanged: (value) {
                setState(() {
                  typeRessource = value;
                });
              },
            ),
            const SizedBox(height: 15),
            // Saisir la capacité de la ressource.
            TextField(
              controller: capaciteController,
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
              controller: equipementsController,
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
              controller: ouvertureController,
              decoration: const InputDecoration(
                labelText: 'Heure d’ouverture (ex: 08:00)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.access_time),
              ),
            ),

            const SizedBox(height: 15),
            // Saisir l'heure de fermeture de la ressource.
            TextField(
              controller: fermetureController,
              decoration: const InputDecoration(
                labelText: 'Heure de fermeture (ex: 17:00)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.access_time_filled),
              ),
            ),
            const SizedBox(height: 20),

            // Afficher la photo sélectionnée.
            if (selectesImage != null)
              Image.file(
                selectesImage!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),

            // Ajouter une photo de la ressource.
            ElevatedButton.icon(
              onPressed: choisirImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Ajouter une photo'),
            ),
          ],
        ),
      ),
    );
  }
}