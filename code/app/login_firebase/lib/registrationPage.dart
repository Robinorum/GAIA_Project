import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profilagePage.dart';

class registrationPage extends StatefulWidget {
  const registrationPage({super.key});

  @override
  State<registrationPage> createState() => _registrationPageState();
}

class _registrationPageState extends State<registrationPage> {
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inscription"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Champs d'inscription
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(hintText: "Email"),
            ),
            TextFormField(
              controller: usernameController,
              decoration: const InputDecoration(hintText: "Nom d'utilisateur"),
            ),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: "Mot de passe "),
            ),
            ElevatedButton(
              onPressed: () {
                if (emailController.text.isNotEmpty && usernameController.text.isNotEmpty && passwordController.text.isNotEmpty) {
                  signUp();
                }
              },
              child: const Text("Register"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> signUp() async {
    try {
      // Vérification de l'existence de l'email dans Firestore
      final emailSnapshot = await _firestore.collection('users').where('email', isEqualTo: emailController.text).get();
      if (emailSnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cet email est déjà utilisé !")),
        );
        return;
      }

      // Vérification de l'existence du nom d'utilisateur dans Firestore
      final usernameSnapshot = await _firestore.collection('users').where('username', isEqualTo: usernameController.text).get();
      if (usernameSnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ce nom d'utilisateur est déjà utilisé")),
        );
        return;
      }

      // Vérification des exigences du mot de passe
      if (passwordController.text.length < 14 || 
          !RegExp(r'[A-Z]').hasMatch(passwordController.text) || 
          !RegExp(r'[a-z]').hasMatch(passwordController.text) || 
          !RegExp(r'\d').hasMatch(passwordController.text) || 
          !RegExp(r'[@$!%*?&]').hasMatch(passwordController.text)) { 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Le mot de passe doit contenir au moins 14 caractères, une majuscule, une minuscule, un chiffre, et un caractère spécial.")),
        );
        return;
      }

      // Création de l'utilisateur avec FirebaseAuth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // Sauvegarde des informations dans Firestore
      await _firestore.collection('accounts').doc(userCredential.user?.uid).set({
        'email': emailController.text,
        'username': usernameController.text,
        'googleAccount': false,
        'brands': [],
        'collection': [], // Ajout d'une collection vide
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vous avez été inscrit !")),
      );

      // Redirection vers la page de profilage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfilagePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur d'inscription : $e")),
      );
    }
  }
}
