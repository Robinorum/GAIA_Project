import 'package:GAIA/model/app_user.dart';
import 'package:GAIA/provider/user_provider.dart';
import 'package:GAIA/pages/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'registration_page.dart';

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
            TextFormField(
              controller: identifierController,
              decoration: InputDecoration(
                hintText: "Email ou Nom d'utilisateur",
                errorText: emailError,
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
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
            ElevatedButton(
              onPressed: () => login(context),
              child: const Text("Connexion"),
            ),
            const SizedBox(height: 20),
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
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text("Connexion avec Google"),
              onPressed: () async {
                await signInWithGoogle(context);
              },
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
              child: const Text("Dev Mode !!!"),
            )
          ],
        ),
      ),
    );
  }

  Future<void> login(BuildContext context) async {
    String email;
    if (identifierController.text.contains('@')) {
      email = identifierController.text;
    } else {
      final userCollection = _firestore.collection('accounts');
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
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: passwordController.text,
      );

      final User? firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        final userDoc =
            await _firestore.collection('accounts').doc(firebaseUser.uid).get();

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
            movements: Map<String, double>.from(
                userData['preferences']?['movement'] ?? {}),
          );
          
          // Ajouter l'utilisateur au UserProvider
          // ignore: use_build_context_synchronously
          Provider.of<UserProvider>(context, listen: false).setUser(user);

          // Redirection vers la page d'accueil
          Navigator.pushReplacement(
            // ignore: use_build_context_synchronously
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      }
    } catch (e) {
      setState(() {
        passwordError = "Erreur de connexion : $e";
      });
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
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

      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        final userDoc =
            await _firestore.collection('accounts').doc(firebaseUser.uid).get();

        if (!userDoc.exists) {
          await _firestore.collection('accounts').doc(firebaseUser.uid).set({
            'email': firebaseUser.email,
            'username': firebaseUser.displayName,
            'googleAccount': true,
          });
        }

        final userData = userDoc.data() as Map<String, dynamic>;

        AppUser user = AppUser(
          id: firebaseUser.uid,
          email: userData['email'],
          username: userData['username'],
          googleAccount: true,
          liked: List<String>.from(userData['liked'] ?? []),
          collection: List<String>.from(userData['collection'] ?? []),
          visitedMuseum: userData['visitedMuseum'] ?? '',
          profilePhoto: userData['profilePhoto'] ?? '',
          preferences: userData['preferences'] ?? {},
          movements: Map<String, double>.from(
              userData['preferences']?['movement'] ?? {}),
        );

        // ignore: use_build_context_synchronously
        Provider.of<UserProvider>(context, listen: false).setUser(user);

        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de connexion avec Google : $e")),
      );
    }
  }
}
