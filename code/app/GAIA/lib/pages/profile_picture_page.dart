/*import 'package:flutter/material.dart';

class ProfilePicturePage extends StatefulWidget {
  const ProfilePicturePage({Key? key}) : super(key: key);

  @override
  _ProfilePicturePageState createState() => _ProfilePicturePageState();
}

class _ProfilePicturePageState extends State<ProfilePicturePage> {
  late Future<List<String>> _galleryImages;

  final String profilePictureUrl = "https://i.pravatar.cc/150?img=12";

  @override
  void initState() {
    super.initState();
    _galleryImages = fetchGalleryImages();
  }

  /*Future<List<String>> fetchGalleryImages() async {
    await Future.delayed(const Duration(seconds: 2));

    return List.generate(24, (index) => "https://i.pravatar.cc/150?img=$index");
  }*/

  Future<List<String<void> fetchGalleryImages() async {
    try {
      String jsonString = await rootBundle.loadString('assets/image_museums/images.json');
      Map<String, dynamic> jsonData = json.decode(jsonString);
      setState(() {
        imagePaths = List<String>.from(jsonData['images']);
      });
    } catch (e) {
      print("Erreur lors du chargement des images: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile Picture"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
    
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Image.network(
                  profilePictureUrl,
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.person, size: 80, color: Colors.grey),
                ),
              ),

            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.upload),
            label: const Text("Upload New Picture"),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: FutureBuilder<List<String>>(
              future: _galleryImages,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No profile pictures found."));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, // ⬅️ 4 images par ligne
                    crossAxisSpacing: 6.0,
                    mainAxisSpacing: 6.0,
                    childAspectRatio: 1, // Ratio carré
                  ),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {},
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          snapshot.data![index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: Colors.grey[300]),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}*/

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
      appBar: AppBar(title: const Text("Select a Profile Picture")),
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
