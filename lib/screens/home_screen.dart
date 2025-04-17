// Màn hình chính (danh sách phòng họp)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:globe_cast/services/firebase_services.dart';

class HomeScreen extends StatefulWidget{
  const HomeScreen({super.key});
  @override
  _HomeScreenState createState() => _HomeScreenState();

}
 class _HomeScreenState extends State<HomeScreen>{
  final _firebaseServices = getIt<FirebaseServices>();
  final _sessionNameController = TextEditingController();

  @override
   void initState() {
    super.initState();
    _firebaseServices.signInAnonymously();
  }

  @override
   void dispose() {
    _sessionNameController.dispose();
    super.dispose();
  }

  @override
   Widget build(BuildContext context){
    return  Scaffold(
      appBar: AppBar(
        title: const Text('GlobeCast Sessions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async{
              await _firebaseServices.signOut();
          },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: _firebaseServices.getSessions(),
          builder: (context, snapshot){
            if(snapshot.hasError){
    return const Center(child: Text('Error loading sessions'));
    }
            if (!snapshot.hasData){
              return const Center(child: CircularProgressIndicator());
            }

            final sessions = snapshot.data!.docs;

            return
          }),
    );
  }
 }