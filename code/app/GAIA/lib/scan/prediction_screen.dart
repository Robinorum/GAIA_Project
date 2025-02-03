import 'package:flutter/material.dart';
import 'package:GAIA/model/artwork.dart';
import 'package:GAIA/pages/home_page.dart';
import 'package:GAIA/services/user_service.dart';
import 'package:GAIA/provider/userProvider.dart';
import 'package:provider/provider.dart';
import 'package:GAIA/services/user_service.dart';


class PredictionScreen extends StatefulWidget {
  final Map<String, dynamic> artworkData;

  const PredictionScreen({required this.artworkData, Key? key}) : super(key: key);

  @override
  _PredictionScreenState createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  late Artwork _artwork;

  @override
  void initState() {
    super.initState();
    _initializeArtwork();
  }

  void _initializeArtwork() {
    _artwork = Artwork.fromJson(widget.artworkData);
    print("Artwork ID : ${_artwork.id}");
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Prédiction')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image scannée
            Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _artwork.toImage(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Affichage des informations de l'œuvre
            Text(
              'Titre: ${_artwork.title}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Artiste: ${_artwork.artist}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Année: ${_artwork.date}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              _artwork.description,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          print(user!.id);
          bool success = await UserService().addArtworks(user!.id, _artwork.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? "Oeuvre ajoutée à la collection !" : "Erreur lors de l'ajout."),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
          if (success) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
            );
          }
        },
        label: const Text("Ajouter à la collection"),
        icon: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
