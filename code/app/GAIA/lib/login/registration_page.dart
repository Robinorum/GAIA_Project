import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'profilage_page.dart';
import 'package:GAIA/model/appUser.dart'; // Modèle AppUser
import 'package:GAIA/provider/userProvider.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  // Contrôleurs pour les champs
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  // Instances Firebase
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
              decoration: const InputDecoration(hintText: "Mot de passe"),
            ),
            ElevatedButton(
              onPressed: () {
                // Validation des champs avant de lancer l'inscription
                if (emailController.text.isNotEmpty &&
                    usernameController.text.isNotEmpty &&
                    passwordController.text.isNotEmpty) {
                  signUp();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Veuillez remplir tous les champs.")),
                  );
                }
              },
              child: const Text("S'inscrire"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> signUp() async {
    try {
      // 1. **Vérification de l'email dans Firestore**
      final emailSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: emailController.text)
          .get();

      if (emailSnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cet email est déjà utilisé !")),
        );
        return;
      }

      // 2. **Vérification du nom d'utilisateur dans Firestore**
      final usernameSnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: usernameController.text)
          .get();

      if (usernameSnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ce nom d'utilisateur est déjà utilisé")),
        );
        return;
      }

      // 3. **Vérification des exigences du mot de passe**
      if (passwordController.text.length < 14 ||
          !RegExp(r'[A-Z]').hasMatch(passwordController.text) ||
          !RegExp(r'[a-z]').hasMatch(passwordController.text) ||
          !RegExp(r'\d').hasMatch(passwordController.text) ||
          !RegExp(r'[@\$!%*?&]').hasMatch(passwordController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Mot de passe trop faible")),
        );
        return;
      }

      // 4. **Création de l'utilisateur avec FirebaseAuth**
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // 5. **Ajout des informations utilisateur dans Firestore**
      await _firestore.collection('accounts').doc(userCredential.user?.uid).set({
        'email': emailController.text,
        'username': usernameController.text,
        'googleAccount': false,
        'brands': [],
        'collection': [],
        'preferences': {
          'movement': {
            // Ajoute ici d'autres mouvements et leurs valeurs
          },
        },
      });

      // 6. **Message de succès et redirection**
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vous avez été inscrit !")),
      );

      final User firebaseUser = userCredential.user!;

      // Récupération des informations utilisateur depuis Firestore
      final userDoc = await _firestore.collection('accounts').doc(firebaseUser.uid).get();

      if (!userDoc.exists) {
        throw Exception("L'utilisateur n'existe pas dans Firestore");
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Création d'un objet AppUser
      AppUser user = AppUser(
        id: firebaseUser.uid,
        email: userData['email'],
        username: userData['username'],
        googleAccount: userData['googleAccount'] ?? false,
        liked: List<String>.from(userData['liked'] ?? []),
        collection: List<String>.from(userData['collection'] ?? []),
        visitedMuseum: userData['visitedMuseum'] ?? '',
        profilePhoto: userData['profilePhoto'] ?? '',
        preferences: userData['preferences'] ?? {}, // Ajout des préférences
        movements: Map<String, double>.from(userData['preferences']?['movement'] ?? {}), // Ajout des préférences liées aux mouvements
      );

      // Mettre l'utilisateur dans le provider
      Provider.of<UserProvider>(context, listen: false).setUser(user);

      // Redirection vers la page de profilage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfilagePage()),
      );
    } on FirebaseAuthException catch (e) {
      // Gestion des erreurs FirebaseAuth
      if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cet email est déjà enregistré.")),
        );
      } else if (e.code == 'weak-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Le mot de passe est trop faible.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: ${e.message}")),
        );
      }
    } catch (e) {
      // Gestion des autres erreurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur inattendue: $e")),
      );
    }
  }
}
