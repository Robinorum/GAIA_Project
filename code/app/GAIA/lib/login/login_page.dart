import 'package:GAIA/pages/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'registration_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.title});

  final String title;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Contrôleurs pour les champs de saisie
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Gestion des erreurs d'affichage
  String? emailError;
  String? passwordError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
            // Champ pour l'email ou le nom d'utilisateur
            TextFormField(
              controller: identifierController,
              decoration: InputDecoration(
                hintText: "Email ou Nom d'utilisateur",
                errorText: emailError,
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            // Champ pour le mot de passe
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
              onPressed: () => login(),
              child: const Text("Connexion"),
            ),
            const SizedBox(height: 20),
            // Lien vers la page d'inscription
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
              label: const Text("Connexion avec Google"),
              onPressed: () async {
                await signInWithGoogle();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Fonction de connexion avec email ou nom d'utilisateur
  Future<void> login() async {
    String email;
    if (identifierController.text.contains('@')) {
      email = identifierController.text;
    } else {
      final userCollection = _firestore.collection('users');
      final snapshot = await userCollection
          .where('username', isEqualTo: identifierController.text)
          .get();

      if (snapshot.docs.isNotEmpty) {
        email = snapshot.docs[0]['email'];
      } else {
        setState(() {
          emailError = "Nom d'utilisateur non trouvé";
        });
        return;
      }
    }

    try {
      // Authentification Firebase
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: passwordController.text,
      );

      // Navigation vers la page d'accueil
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      setState(() {
        passwordError = "Erreur de connexion : $e";
      });
    }
  }

  /// Fonction de connexion avec Google
  Future<void> signInWithGoogle() async {
    try {
      // Authentification Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // L'utilisateur a annulé la connexion

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Ajouter l'utilisateur à Firestore s'il s'agit de la première connexion
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user?.uid)
          .get();

      if (!userDoc.exists) {
        await _firestore.collection('users').doc(userCredential.user?.uid).set({
          'email': userCredential.user?.email,
          'username': userCredential.user?.displayName,
          'googleAccount': true,
        });
      }

      // Redirection vers la page d'accueil
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de connexion avec Google : $e")),
      );
    }
  }
}
