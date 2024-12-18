import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:GAIA/pages/home_page.dart';
import 'package:GAIA/login/login_page.dart';

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Something went wrong!')),
          );
        } else if (snapshot.hasData) {
          return HomePage();
        } else {
          return const LoginPage(title: 'Login Page');
        }
      },
    );
  }
}