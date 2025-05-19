import 'package:GAIA/services/profilage_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/artwork.dart';
import 'package:GAIA/provider/userProvider.dart';
import 'package:GAIA/pages/home_page.dart';
import '../services/recommendation_service.dart';

class ProfilagePage extends StatefulWidget {
  const ProfilagePage({super.key});

  @override
  State<ProfilagePage> createState() => _ProfilagePageState();
}

class _ProfilagePageState extends State<ProfilagePage> {
  late Future<List<Artwork>> _recommendedArtworks;
  int currentIndex = 0;
  double offset = 0;
  double angle = 0;

  @override
  void initState() {
    super.initState();
    _recommendedArtworks = ProfilageService().fetchArtworks();
  }

  void handleSwipe(String direction, Artwork artwork) async {
    setState(() {
      if (direction == 'right') {
        final user = Provider.of<UserProvider>(context, listen: false).user;
        ProfilageService().modifyBrands(artwork, user!, "like");
      }
      currentIndex++;
      offset = 0;
      angle = 0;

      if (currentIndex == 5) {
        final user = Provider.of<UserProvider>(context, listen: false).user;
        final uid = user?.id ?? 'Default-uid';
        RecommendationService().majRecommendations(uid);
        _recommendedArtworks.then((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profilage de ${user?.username ?? "guest"}'),
      ),
      body: FutureBuilder<List<Artwork>>(
        future: _recommendedArtworks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text("Erreur lors du chargement: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red)),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucune œuvre trouvée."));
          }

          final artworks = snapshot.data!;
          return currentIndex < artworks.length
              ? Center(
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        offset += details.delta.dx;
                        angle = offset / 10;
                      });
                    },
                    onPanEnd: (details) {
                      if (offset > 100) {
                        handleSwipe('right', artworks[currentIndex]);
                      } else if (offset < -100) {
                        handleSwipe('left', artworks[currentIndex]);
                      } else {
                        setState(() {
                          offset = 0;
                          angle = 0;
                        });
                      }
                    },
                    child:
                        buildArtworkCard(artworks[currentIndex], offset, angle),
                  ),
                )
              : const Center(child: Text("Chargement..."));
        },
      ),
    );
  }

  Widget buildArtworkCard(Artwork artwork, double offset, double angle) {
    double opacity = 1 - (offset.abs() / 300).clamp(0.0, 1.0);

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(offset, 0),
        child: Transform.rotate(
          angle: angle * 3.14 / 180,
          child: AnimatedContainer(
            key: ValueKey(artwork.id), // Ajout d’une Key unique
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: RepaintBoundary(
                    // Ajout de RepaintBoundary
                    child: Container(
                      height: 400,
                      width: 300,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: FadeInImage(
                        placeholder: const AssetImage('assets/placeholder.png'),
                        image: artwork.toImage().image,
                        fit: BoxFit.cover,
                        // Remplacement du placeholder par un CircularProgressIndicator
                        fadeInCurve: Curves.easeIn,
                        fadeInDuration: const Duration(milliseconds: 300),
                        imageErrorBuilder: (context, error, stackTrace) {
                          return const Center(
                              child: Icon(Icons.error,
                                  color: Colors.red, size: 50));
                        },
                        // Affichage du CircularProgressIndicator pendant le chargement
                        placeholderErrorBuilder: (context, error, stackTrace) {
                          return const Center(
                              child: CircularProgressIndicator());
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  artwork.title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Type: ${artwork.movement}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => handleSwipe('left', artwork),
                      icon:
                          const Icon(Icons.close, color: Colors.red, size: 40),
                    ),
                    IconButton(
                      onPressed: () => handleSwipe('right', artwork),
                      icon: const Icon(Icons.favorite,
                          color: Colors.green, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}