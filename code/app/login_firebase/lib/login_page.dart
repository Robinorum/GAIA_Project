import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:login_firebase/camera_screen.dart';
import 'registrationPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.title});

  final String title;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //création des deux variables que l'on récupere dans les champs
  final identifierController = TextEditingController();
  final passwordController = TextEditingController();
  //création des variables liées aux instances de firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            child: Column(
              children: [
                //premier input pour l'email
                TextFormField(
                  controller: identifierController,
                  decoration: const InputDecoration(hintText: "Email"),
                ),
                //deuxieme input pour le mdp
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: "Password"),
                ),
                //bouton de connexion
                ElevatedButton(
                  onPressed: () {
                    if (identifierController.text.isNotEmpty && passwordController.text.isNotEmpty) {
                      login();
                    }
                  },
                  child: const Text("Connexion"),
                ),
                //bouton pour changer de page et passer sur la page d'inscription
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const registrationPage()),
                    );
                  },
                  child: const Text("Inscription"),
                ),
                //bouton connexion avec google
                const SizedBox(height: 20),
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
        ),
      ),
    );
  }

  Future<void> login() async {
    String email;
    if (identifierController.text.contains('@')) {
      email = identifierController.text;
    } else {
      final userCollection = _firestore.collection('users');
      final snapshot = await userCollection.where('username', isEqualTo: identifierController.text).get();

      if (snapshot.docs.isNotEmpty) {
        email = snapshot.docs[0]['email'];
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nom d'utilisateur non trouvé")),
        );
        return;
      }
    }

   try {
    await _auth.signInWithEmailAndPassword(email: email, password: passwordController.text);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => CameraScreen()),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erreur de connexion: $e")),
    );
  }
  }

  Future<void> signInWithGoogle() async {
    try {
      // Authentifier avec Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // L'utilisateur a annulé la connexion

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Ajouter l'utilisateur à Firestore s'il s'agit de la première connexion
      final userDoc = await _firestore.collection('users').doc(userCredential.user?.uid).get();
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de connexion avec Google : $e")),
      );
    }
  }
}
