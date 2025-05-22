import 'package:flutter/material.dart';
import 'package:GAIA/model/artwork.dart';
import 'package:GAIA/scan/quizz_screen.dart';
import 'package:GAIA/services/user_service.dart';
import 'package:GAIA/provider/userProvider.dart';
import 'package:provider/provider.dart';
import 'package:GAIA/services/quizz_service.dart';

class PredictionScreen extends StatefulWidget {
  final Map<String, dynamic> artworkData;

  const PredictionScreen({required this.artworkData, super.key});

  @override
  _PredictionScreenState createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  late Artwork _artwork;
  late Future<List<Artwork>> _collectionFuture;

  @override
  void initState() {
    super.initState();
    _initializeArtwork();

    final user = Provider.of<UserProvider>(context, listen: false).user;
    _collectionFuture = UserService().fetchCollection(user!.id);
  }

  void _initializeArtwork() {
    _artwork = Artwork.fromJson(widget.artworkData);
  }

  bool isArtworkAlreadyInCollection(List<Artwork> collection) {
    return collection.any((artwork) => artwork.id == _artwork.id);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text('Prédiction')),
      body: FutureBuilder<List<Artwork>>(
        future: _collectionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          } else {
            final collection = snapshot.data!;
            final alreadyCollected = isArtworkAlreadyInCollection(collection);

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      Text(
                        'Titre: ${_artwork.title}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
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
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: alreadyCollected
                        ? ElevatedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.check),
                            label: const Text("Œuvre déjà collectée"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade400,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                          )
                        : FloatingActionButton.extended(
                            onPressed: () async {
                              try {
                                final quizz = await QuizzService().fetchQuizz(_artwork);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QuizzScreen(
                                      quizz: quizz,
                                      artwork: _artwork,
                                    ),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Erreur : $e"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            label: const Text("Lancer le quizz pour valider le tableau"),
                            icon: const Icon(Icons.quiz),
                            backgroundColor: Colors.orange,
                          ),
                  ),
                )
              ],
            );
          }
        },
      ),
    );
  }
}
