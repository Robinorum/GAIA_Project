import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:GAIA/pages/home_page.dart';
import 'package:GAIA/login/login_page.dart';
import 'package:provider/provider.dart';
import 'package:GAIA/provider/user_provider.dart';
import 'package:GAIA/model/app_user.dart'; // Modèle AppUser

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Something went wrong!')),
          );
        } else if (snapshot.hasData) {
          return FutureBuilder<AppUser>(
            future: AppUser.fromAuth(snapshot.data!),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              } else if (userSnapshot.hasError) {
                return const Scaffold(
                  body: Center(child: Text('Something went wrong!')),
                );
              } else if (userSnapshot.hasData) {
                Provider.of<UserProvider>(context, listen: false)
                    .setUser(userSnapshot.data!);
                return const HomePage();
              } else {
                return const LoginPage(title: 'Login Page');
              }
            },
          );
        } else {
          return const LoginPage(title: 'Login Page');
        }
      },
    );
  }
}
