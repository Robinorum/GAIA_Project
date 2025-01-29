import 'package:GAIA/services/profilage_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  late FirebaseAuth _auth;
  late User? _firebaseUser;
  int currentIndex = 0;
  double offset = 0;
  double angle = 0;

  @override
  void initState() {
    super.initState();
    _recommendedArtworks = ProfilageService().fetchArtworks();
    _auth = FirebaseAuth.instance;
    _firebaseUser = _auth.currentUser;
  }

  void handleSwipe(String direction, String artworkId) async {
    setState(() {
      if (direction == 'right') {
        ProfilageService().modifyBrands(artworkId, _firebaseUser!.uid);
        print("Liké (id): $artworkId");
      } else if (direction == 'left') {
        print("Pas liké (id): $artworkId");
      }
      currentIndex++;
      offset = 0;
      angle = 0;

      if (currentIndex == 5) {
        final user = Provider.of<UserProvider>(context, listen: false).user;
        final uid = user?.id ?? 'Default-uid';
        print(uid);
        RecommendationService().majRecommendations(uid);
        _recommendedArtworks.then((artworks) async {
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
              child: Text(
                "Erreur lors du chargement: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
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
                        handleSwipe('right', artworks[currentIndex].id);
                      } else if (offset < -100) {
                        handleSwipe('left', artworks[currentIndex].id);
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
    return Transform.translate(
      offset: Offset(offset, 0),
      child: Transform.rotate(
        angle: angle * 3.14 / 180,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300), // Durée de l'animation
          curve: Curves.easeInOut,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
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
                  image: DecorationImage(
                    image: artwork.toImage().image,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                artwork.title,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                    onPressed: () => handleSwipe('left', artwork.id),
                    icon: const Icon(Icons.close, color: Colors.red, size: 40),
                  ),
                  IconButton(
                    onPressed: () => handleSwipe('right', artwork.id),
                    icon: const Icon(Icons.favorite,
                        color: Colors.green, size: 40),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
