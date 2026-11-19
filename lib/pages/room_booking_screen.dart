import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomBookingScreen extends StatelessWidget{
  const RoomBookingScreen({super.key});
  @override
  Widget  build(BuildContext context){
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar( title:const Text('Réserver une salle'),
        backgroundColor: const Color(0xFF245A7),
      foregroundColor: Colors.white,),
    body: const Center(child: Text('liste des salles disponibles',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, ),),),
    );
  }
}