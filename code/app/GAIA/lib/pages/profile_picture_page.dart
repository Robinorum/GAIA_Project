import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:gaia/provider/user_provider.dart';
import 'dart:developer' as developer;

class ProfilePicturePage extends StatefulWidget {
  const ProfilePicturePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ProfilePicturePageState createState() => _ProfilePicturePageState();
}

class _ProfilePicturePageState extends State<ProfilePicturePage> {
  List<String> imagePaths = [];

  @override
  void initState() {
    super.initState();
    loadImagesFromJson();
  }

  Future<void> loadImagesFromJson() async {
    try {
      String jsonString =
          await rootBundle.loadString('assets/image_profiles/images.json');
      Map<String, dynamic> jsonData = json.decode(jsonString);

      List<String> paths = List<String>.from(jsonData['images']);
      setState(() {
        imagePaths = paths;
      });
    } catch (e) {
      developer.log("Error loading images: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choisis une icône de profil")),
      body: imagePaths.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: imagePaths.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () async {
                    // Récupère l'utilisateur actuel
                    final user =
                        Provider.of<UserProvider>(context, listen: false).user;

                    // Mets à jour la photo de profil dans Firestore
                    try {
                      await user?.updateProfilePhoto(imagePaths[index]);
                      // Une fois l'image mise à jour, notifie les autres widgets
                      // ignore: use_build_context_synchronously
                      Provider.of<UserProvider>(context, listen: false)
                          .updateProfileImage(imagePaths[index]);
                      // ignore: use_build_context_synchronously
                      Navigator.pop(context); // Retour à la page précédente
                    } catch (e) {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Erreur: $e')));
                    }
                  },
                  child: Image.asset(imagePaths[index], fit: BoxFit.cover),
                );
              },
            ),
    );
  }
}
