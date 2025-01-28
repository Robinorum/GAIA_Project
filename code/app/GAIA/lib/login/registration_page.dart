import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'profilage_page.dart';
import 'package:GAIA/provider/userProvider.dart';
import 'package:GAIA/model/appUser.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign Up"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Text fields for email, username, and password
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(hintText: "Email"),
            ),
            TextFormField(
              controller: usernameController,
              decoration: const InputDecoration(hintText: "Username"),
            ),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: "Password"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (emailController.text.isNotEmpty &&
                    usernameController.text.isNotEmpty &&
                    passwordController.text.isNotEmpty) {
                  signUp();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Please fill in all the fields.")),
                  );
                }
              },
              child: const Text("Sign Up"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> signUp() async {
    try {
      // Check if the email already exists
      final emailSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: emailController.text)
          .get();
      if (emailSnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("This email is already in use.")),
        );
        return;
      }

      // Check if the username already exists
      final usernameSnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: usernameController.text)
          .get();
      if (usernameSnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("This username is already in use.")),
        );
        return;
      }

      // Validate password
      if (passwordController.text.length < 14 ||
          !RegExp(r'[A-Z]').hasMatch(passwordController.text) ||
          !RegExp(r'[a-z]').hasMatch(passwordController.text) ||
          !RegExp(r'\d').hasMatch(passwordController.text) ||
          !RegExp(r'[@$!%*?&]').hasMatch(passwordController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Password must be at least 14 characters, include an uppercase letter, a lowercase letter, a number, and a special character.",
            ),
          ),
        );
        return;
      }

      // Create user with FirebaseAuth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // Save user data to Firestore
      await _firestore
          .collection('accounts')
          .doc(userCredential.user?.uid)
          .set({
        'email': emailController.text,
        'username': usernameController.text,
        'googleAccount': false,
        'brands': [],
        'reco': [],
        'previous_reco': [],
        'collection': [],
        'visitedMuseum': '',
        'profilePhoto': '',
        'preferences': {'movements': {}},
      });

      // Fetch the created user's data
      final userDoc = await _firestore
          .collection('accounts')
          .doc(userCredential.user?.uid)
          .get();
      final userData = userDoc.data() as Map<String, dynamic>;

      // Create AppUser object
      AppUser user = AppUser(
        id: userCredential.user!.uid,
        email: userData['email'],
        username: userData['username'],
        googleAccount: userData['googleAccount'] ?? false,
        liked: List<String>.from(userData['liked'] ?? []),
        collection: List<String>.from(userData['collection'] ?? []),
        visitedMuseum: userData['visitedMuseum'] ?? '',
        profilePhoto: userData['profilePhoto'] ?? '',
        preferences: userData['preferences'] ?? {},
        movements: Map<String, double>.from(
            userData['preferences']?['movements'] ?? {}),
      );

      // Add the user to the UserProvider
      Provider.of<UserProvider>(context, listen: false).setUser(user);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User registered successfully!")),
      );

      // Navigate to ProfilagePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfilagePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration error: $e")),
      );
    }
  }
}
