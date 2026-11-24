
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Écran de scan lié à une réservation précise.
class QrScanScreen extends StatefulWidget {
  final String bookingId;
  final String roomId;

  const QrScanScreen({
    super.key,
    required this.bookingId,
    required this.roomId,
  });

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController scannerController =
  MobileScannerController();

  // Éviter le traitement plusieurs fois du même QR Code.
  bool _isProcessing = false;

  // Vérifier le QR Code et confirmer la présence.
  Future<void> verifierQRCode(String code) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('Veuillez vous connecter.');
      }

      if (code != 'ressource:${widget.roomId}') {
        throw Exception('QR Code incorrect.');
      }

      final bookingRef = FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId);

      final bookingSnapshot = await bookingRef.get();

      if (!bookingSnapshot.exists) {
        throw Exception('Réservation introuvable.');
      }

      final booking = bookingSnapshot.data()!;

      if (booking['userId'] != user.uid ||
          booking['roomId'] != widget.roomId ||
          booking['status'] != 'confirmed') {
        throw Exception('Réservation invalide.');
      }

      final startAt = (booking['startAt'] as Timestamp).toDate();
      final now = DateTime.now();

      if (now.isBefore(startAt) ||
          now.isAfter(startAt.add(const Duration(minutes: 15)))) {
        throw Exception('Délai de confirmation dépassé ou non commencé.');
      }

      await bookingRef.update({
        'status': 'present',
        'checkedInAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Présence confirmée avec succès !'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );

      _isProcessing = false;
    }
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner QR Code'),
      ),
      body: MobileScanner(
        controller: scannerController,
        onDetect: (capture) {
          // Lire le QR Code détecté.
          if (capture.barcodes.isNotEmpty) {
            final code = capture.barcodes.first.rawValue;

            if (code != null) {
              verifierQRCode(code);
            }
          }
        },
      ),
    );
  }
}
