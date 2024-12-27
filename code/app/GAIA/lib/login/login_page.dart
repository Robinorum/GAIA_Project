import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:GAIA/login/registration_page.dart';
import 'package:provider/provider.dart';
import '../pages/home_page.dart';
import 'package:GAIA/model/appUser.dart'; // Modèle AppUser
import 'package:GAIA/provider/userProvider.dart';
import 'package:GAIA/services/authentification_service.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.title});

  final String title;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final AuthentificationService _loginService = AuthentificationService();

  String? emailError;
  String? passwordError;
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
            // Champ Email/Identifiant
            TextFormField(
              controller: identifierController,
              decoration: InputDecoration(
                hintText: "Email ou Nom d'utilisateur",
                errorText: emailError,
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            // Champ Mot de passe
            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Mot de passe",
                errorText: passwordError,
                prefixIcon: const Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 20),
            // Bouton de connexion
            ElevatedButton(
              onPressed: () async {
                if (identifierController.text.isNotEmpty &&
                    passwordController.text.isNotEmpty) {
                  final result = await _loginService.loginUser(
                    identifierController.text,
                    passwordController.text,
                  );

                  if (result['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("user connected !")),
                    );

                    // Récupérer l'utilisateur et l'ajouter au UserProvider
                    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
                    final FirebaseAuth _auth = FirebaseAuth.instance;

                    final String IdUser = result['uid']; // Récupérer l'UID depuis le résultat de l'API

                    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
                          email: identifierController.text,
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
                          MaterialPageRoute(builder: (context) => const HomePage()),
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
              child: const Text("Se connecter"),
            ),
            const SizedBox(height: 20),
            // Lien vers l'inscription
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RegistrationPage()),
                );
              },
              child: const Text("Créer un compte"),
            ),
            const SizedBox(height: 20),
            // Connexion avec Google
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text("Se connecter avec Google"),
              onPressed: () async {
             //   await signInWithGoogle();
              },
            ),
            const SizedBox(height: 10),
            // Mode "développeur"
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
              child: const Text("Mode Développeur"),
            ),
          ],
        ),
      ),
    );
  }
/*

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user?.uid)
          .get();
      if (!userDoc.exists) {
        await _firestore.collection('users').doc(userCredential.user?.uid).set({
          'email': userCredential.user?.email,
          'username': userCredential.user?.displayName,
          'googleAccount': true,
          'brands': [],
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connexion réussie avec Google !")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de connexion avec Google : $e")),
      );
    }
  }*/
}
