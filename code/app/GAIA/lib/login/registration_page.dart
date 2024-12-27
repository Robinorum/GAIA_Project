import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'profilage_page.dart';
import 'package:GAIA/services/authentification_service.dart';
import 'package:GAIA/model/appUser.dart';
import 'package:GAIA/provider/userProvider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  final AuthentificationService _registrationService = AuthentificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("sign up"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
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
              onPressed: () async {
                if (emailController.text.isNotEmpty &&
                    usernameController.text.isNotEmpty &&
                    passwordController.text.isNotEmpty) {
                  final result = await _registrationService.registerUser(
                    emailController.text,
                    passwordController.text,
                    usernameController.text,
                  );

                  if (result['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("user registered !")),
                    );

                    // Récupérer l'utilisateur et l'ajouter au UserProvider
                    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
                    final FirebaseAuth _auth = FirebaseAuth.instance;

                    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
                          email: emailController.text,
                          password: passwordController.text,
                        );

                    final User firebaseUser = userCredential.user!;
                    if (firebaseUser != null) {
                      final userDoc = await _firestore.collection('accounts').doc(firebaseUser.uid).get();

                      if (userDoc.exists) {
                        final userData = userDoc.data() as Map<String, dynamic>;

                        // Créer un objet AppUser
                        AppUser user = AppUser(
                          id: firebaseUser.uid,
                          email: userData['email'],
                          username: userData['username'],
                          googleAccount: userData['googleAccount'] ?? false,
                          liked: List<String>.from(userData['liked'] ?? []),
                          collection: List<String>.from(userData['collection'] ?? []),
                          visitedMuseum: userData['visitedMuseum'] ?? '',
                          profilePhoto: userData['profilePhoto'] ?? '',
                          preferences: userData['preferences'] ?? {},
                          movements: Map<String, double>.from(userData['preferences']?['movement'] ?? {}),
                        );

                        // Ajouter l'utilisateur au UserProvider
                        Provider.of<UserProvider>(context, listen: false).setUser(user);

                        // Redirection vers la page de profilage
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfilagePage()),
                        );
                      }
                    }
                  } else {
                    // Affichage du message d'erreur en fonction du retour de l'API
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['message'])),
                    );
                  }
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
}
