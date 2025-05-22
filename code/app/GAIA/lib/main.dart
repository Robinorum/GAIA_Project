import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gaia/provider/user_provider.dart';
import 'package:gaia/widgets/auth_gate.dart';
import 'package:provider/provider.dart';
import 'package:gaia/provider/theme_provider.dart'; // Import du ThemeProvider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(
            create: (_) => ThemeProvider()), // Ajout du ThemeProvider ici
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Accéder au provider pour obtenir le thème actuel
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Camera Prediction App',
      theme: themeProvider.currentTheme, // Utilisation du thème dynamique
      home: const AuthGate(),
    );
  }
}
