import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/artwork_service.dart';
import '../model/artwork.dart';
import 'package:GAIA/provider/userProvider.dart';
import 'package:GAIA/pages/home_page.dart';

class ProfilagePage extends StatefulWidget {
  const ProfilagePage({super.key});

  @override
  State<ProfilagePage> createState() => _ProfilagePageState();
}

class _ProfilagePageState extends State<ProfilagePage> {
  late Future<List<Artwork>> _recommendedArtworks;
  late FirebaseFirestore _firestore;
  late FirebaseAuth _auth;
  late User? _firebaseUser;
  int currentIndex = 0;
  double offset = 0;
  double angle = 0;

  @override
  void initState() {
    super.initState();
    _recommendedArtworks = ArtworkService().fetchArtworks(); // Récupération via l'API
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
    _firebaseUser = _auth.currentUser;
  }

  Future<void> _addToBrands(String artworkId) async {
    if (_firebaseUser != null) {
      // Vérification de l'existence de l'utilisateur
      final docSnapshot = await _firestore.collection('accounts').doc(_firebaseUser!.uid).get();
      if (docSnapshot.exists) {
        // Ajouter l'ID de l'œuvre au tableau 'brands' de l'utilisateur
        await _firestore.collection('accounts').doc(_firebaseUser!.uid).update({
          'brands': FieldValue.arrayUnion([artworkId]), // Ajouter l'ID de l'œuvre au tableau
        });
        // Log pour vérifier la valeur ajoutée
        print("Ajouté à 'brands' : $artworkId");
      }
    }
  }

  void handleSwipe(String direction, String artworkId) {
    setState(() {
      if (direction == 'right') {
        // Log pour vérifier le ID avant d'ajouter
        print("Liké (id): $artworkId");
        _addToBrands(artworkId); // Ajouter l'ID de l'œuvre au tableau 'brands'
      } else if (direction == 'left') {
        // Log pour vérifier l'ID du non-liker
        print("Pas liké (id): $artworkId");
      }
      currentIndex++;
      offset = 0; // Réinitialisation de l'offset
      angle = 0; // Réinitialisation de l'angle

      if (currentIndex == 5) {
        // Redirection vers MainPage une fois que toutes les cartes sont traitées
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Récupérer l'utilisateur à partir du UserProvider
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profilage de ${user?.username ?? "guest"}'), // Afficher le nom de l'utilisateur
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
                        offset += details.delta.dx; // Déplacer la carte
                        angle = offset / 10; // Appliquer une rotation proportionnelle
                      });
                    },
                    onPanEnd: (details) {
                      if (offset > 100) {
                        handleSwipe('right', artworks[currentIndex].id); // Swipe droite
                      } else if (offset < -100) {
                        handleSwipe('left', artworks[currentIndex].id); // Swipe gauche
                      } else {
                        setState(() {
                          offset = 0; // Réinitialiser la position si le swipe est insuffisant
                          angle = 0; // Réinitialiser la rotation
                        });
                      }
                    },
                    child: buildArtworkCard(artworks[currentIndex], offset, angle),
                  ),
                )
              : const Center(child: Text("Chargement..."));
        },
      ),
    );
  }

  Widget buildArtworkCard(Artwork artwork, double offset, double angle) {
    return Transform.translate(
      offset: Offset(offset, 0), // Déplacer la carte horizontalement
      child: Transform.rotate(
        angle: angle * 3.14 / 180, // Appliquer une rotation à la carte en fonction du swipe
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300), // Durée de l'animation
          curve: Curves.easeInOut,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image
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
              // Informations sur l'œuvre
              Text(
                artwork.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                'Type: ${artwork.movement}',
                style: const TextStyle(
                    fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              // Boutons Like et Dislike
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => handleSwipe('left', artwork.id),
                    icon: const Icon(Icons.close, color: Colors.red, size: 40),
                  ),
                  const SizedBox(width: 50),
                  IconButton(
                    onPressed: () => handleSwipe('right', artwork.id),
                    icon: const Icon(Icons.favorite, color: Colors.green, size: 40),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
