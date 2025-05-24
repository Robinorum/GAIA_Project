import 'package:flutter/material.dart';
import 'package:gaia/model/artwork.dart';
import 'package:gaia/model/museum.dart';
import 'package:gaia/scan/quizz_screen.dart';
import 'package:gaia/services/museum_service.dart';
import 'package:gaia/services/user_service.dart';
import 'package:gaia/provider/user_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:gaia/services/quizz_service.dart';

class PredictionScreen extends StatefulWidget {
  final Map<String, dynamic> artworkData;

  const PredictionScreen({required this.artworkData, super.key});

  @override
  PredictionScreenState createState() => PredictionScreenState();
}

class PredictionScreenState extends State<PredictionScreen> {
  late Artwork _artwork;
  late Future<List<Artwork>> _collectionFuture;
  LatLng? _currentLocation;
  late Future<List<Museum>> _recommendedMuseums;
  String? _verifResult;
  Museum? topMuseums;

  @override
  void initState() {
    super.initState();
    _initializeArtwork();
    _loadRecommendations();
    _getUserLocation();

    final user = Provider.of<UserProvider>(context, listen: false).user;
    _collectionFuture = UserService().fetchCollection(user!.id);
  }

  void _initializeArtwork() {
    _artwork = Artwork.fromJson(widget.artworkData);
  }

  bool isArtworkAlreadyInCollection(List<Artwork> collection) {
    return collection.any((artwork) => artwork.id == _artwork.id);
  }

  void _loadRecommendations() {
    setState(() {
      _recommendedMuseums = MuseumService().fetchMuseums();
    });
  }

  Future<void> _getUserLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      _sortAndUpdateMuseums();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error getting location: $e")),
      );
    }
  }

  void _sortAndUpdateMuseums() {
    if (_currentLocation == null) return;

    _recommendedMuseums.then((museums) {
      final nearbyMuseums = museums.where((museum) {
        final museumLocation =
            LatLng(museum.location.latitude, museum.location.longitude);
        final distance = _calculateDistance(_currentLocation!, museumLocation);
        return distance <= 2000;
      }).toList();

      final sortedMuseums = _sortMuseumsByDistance(nearbyMuseums);

      if (sortedMuseums.isNotEmpty) {
        setState(() {
          topMuseums = sortedMuseums.first;
        });
        _verifyArtworkWithTopMuseum(); // Appel après topMuseums défini
      }
    });
  }

  Future<void> _verifyArtworkWithTopMuseum() async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null || topMuseums == null) return;

    final result = await UserService().verifQuestMuseum(
      user.id,
      topMuseums!.officialId,
      _artwork.id,
    );

    if (!mounted) return;

    setState(() {
      _verifResult = result;
    });
  }

  List<Museum> _sortMuseumsByDistance(List<Museum> museums) {
    if (_currentLocation == null) return museums;
    museums.sort((a, b) {
      double distanceA = _calculateDistance(
        _currentLocation!,
        LatLng(a.location.latitude, a.location.longitude),
      );
      double distanceB = _calculateDistance(
        _currentLocation!,
        LatLng(b.location.latitude, b.location.longitude),
      );
      return distanceA.compareTo(distanceB);
    });
    return museums;
  }

  double _calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
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
                                color:
                                    Colors.grey.withAlpha((0.3 * 255).toInt()),
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
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey),
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
                        : _verifResult == "QUEST_FINISHED"
                            ? ElevatedButton.icon(
                                onPressed: null,
                                icon: const Icon(Icons.block),
                                label: const Text("Aucune œuvre à valider"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey.shade400,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                ),
                              )
                            : _verifResult == "INCORRECT"
                                ? ElevatedButton.icon(
                                    onPressed: null,
                                    icon: const Icon(Icons.warning),
                                    label: const Text(
                                        "Mauvaise œuvre pour la quête"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade300,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor:
                                          Colors.red.shade200,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                    ),
                                  )
                                : _verifResult == "CORRECT"
                                    ? FloatingActionButton.extended(
                                        onPressed: () async {
                                          final currentContext =
                                              context; // capture du context
                                          try {
                                            final quizz = await QuizzService()
                                                .fetchQuizz(_artwork);
                                            if (!mounted) return;
                                            Navigator.push(
                                              currentContext,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    QuizzScreen(
                                                  quizz: quizz,
                                                  artwork: _artwork,
                                                ),
                                              ),
                                            );
                                          } catch (e) {
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(currentContext)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text("Erreur : $e"),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                        label: const Text(
                                            "Lancer le quizz pour valider le tableau"),
                                        icon: const Icon(Icons.quiz),
                                        backgroundColor: Colors.orange,
                                      )
                                    : _verifResult ==
                                            "MUSEUM_NOT_FOUND_IN_QUESTS"
                                        ? ElevatedButton.icon(
                                            onPressed: null,
                                            icon:
                                                const Icon(Icons.error_outline),
                                            label: const Text(
                                                "Les quêtes de ce musée n'ont pas été activées"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.orange.shade200,
                                              foregroundColor: Colors.black87,
                                              disabledBackgroundColor:
                                                  Colors.orange.shade100,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 24,
                                                      vertical: 12),
                                            ),
                                          )
                                        : Container(), // Rien si autre cas (ou loader)
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
