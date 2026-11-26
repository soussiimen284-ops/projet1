import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:qr_flutter/qr_flutter.dart';

// Écran de gestion des ressources par le responsable.
// Gérer les ressources avec des champs modifiables.
class ResourceManagementScreen extends StatefulWidget {
  const ResourceManagementScreen({super.key});

  @override
  State<ResourceManagementScreen> createState() => _ResourceManagementScreenState();
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

  // Enregistrer la ressource et sa photo dans Firestore.
  Future<void> enregistrerRessource() async {
    if (nomController.text.trim().isEmpty ||
        typeRessource == null ||
        capaciteController.text.trim().isEmpty ||
        ouvertureController.text.trim().isEmpty ||
        fermetureController.text.trim().isEmpty ||
        selectesImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs et choisir une photo.'),
        ),
      );
      return;
    }

    final int? capacite =
    int.tryParse(capaciteController.text.trim());

    if (capacite == null || capacite <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir une capacité valide.'),
        ),
      );
      return;
    }

    try {
      // Compresser la photo sélectionnée.
      final compressedImage =
      await FlutterImageCompress.compressWithFile(
        selectesImage!.path,
        minWidth: 600,
        minHeight: 400,
        quality: 60,
        format: CompressFormat.jpeg,
      );

      if (compressedImage == null ||
          compressedImage.length > 180 * 1024) {
        throw Exception('La photo est trop volumineuse.');
      }

      // Convertir la photo en Base64.
      final String photoBase64 = base64Encode(compressedImage);

      // Enregistrer les informations dans Firestore.
      final ressourceRef = await FirebaseFirestore.instance.collection('ressources').add({
        'nom': nomController.text.trim(),
        'type': typeRessource,
        'capacite': capacite,
        'equipements': equipementsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'ouverture': ouvertureController.text.trim(),
        'fermeture': fermetureController.text.trim(),
        'photoBase64': photoBase64,
        'actif': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Afficher un message de confirmation.
      if (!mounted) return;
      // Afficher le QR Code de la ressource ajoutée.
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('QR Code - ${nomController.text.trim()}'),
          content: SizedBox(
            width: 220,
            height: 220,
            child: QrImageView(
              data: 'ressource:${ressourceRef.id}',
              version: QrVersions.auto,
              size: 200,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ressource ajoutée avec succès !'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
        ),
      );
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
        child: SingleChildScrollView(
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
            // Enregistrer la ressource dans Firebase.
            ElevatedButton.icon(
              onPressed: enregistrerRessource,
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer la ressource'),
            ),
            // Afficher la liste des ressources avec leurs QR Codes.
            const SizedBox(height: 25),
            const Text(
              'Ressources enregistrées',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('ressources')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (snapshot.hasError) {
                  return const Text('Erreur de chargement des ressources');
                }

                final ressources = snapshot.data?.docs ?? [];

                if (ressources.isEmpty) {
                  return const Text('Aucune ressource enregistrée.');
                }

                return Column(
                  children: ressources.map((doc) {
                    final ressource = doc.data();

                    return Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.qr_code,
                          color: Color(0xFF2457A7),
                        ),
                        title: Text(ressource['nom'] ?? 'Ressource'),
                        subtitle: Text(ressource['type'] ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.visibility),
                          tooltip: 'Afficher QR Code',
                          onPressed: () {
                            // Afficher le QR Code de la ressource sélectionnée.
                            showDialog<void>(context: context,
                              builder: (context) => AlertDialog(title: Text('QR Code - ${ressource['nom']}'),
                                content: SizedBox(width: 220, height: 220, child: QrImageView(data: 'ressource:${doc.id}', version: QrVersions.auto, size: 200),
                                ),
                                actions: [TextButton(onPressed: () => Navigator.pop(context),child: const Text('Fermer')),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
        ),
      ),
    );
  }
}