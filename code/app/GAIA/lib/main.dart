import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
//import 'package:GAIA/login/login_page.dart';
import 'package:GAIA/provider/userProvider.dart';
import 'package:GAIA/auth_gate.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()), // Point 3 ajouté ici
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Camera Prediction App',
        theme: ThemeData.light().copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: AuthGate(),
      ),
    );
  }
}
