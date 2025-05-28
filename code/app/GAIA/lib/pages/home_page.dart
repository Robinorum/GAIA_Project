import 'package:gaia/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:gaia/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:gaia/pages/collection_page.dart';
import 'package:gaia/pages/map_page.dart';
import 'package:gaia/pages/quests_page.dart';
import 'package:gaia/pages/detail_artwork_page.dart';
import '../component/custom_bottom_nav.dart';
import '../scan/camera_screen.dart';
import '../services/recommendation_service.dart';
import '../services/museum_service.dart';
import '../model/artwork.dart';
import '../model/museum.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../pages/detail_museum_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gaia/utils/dialogs.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeContent(),
    const MapPage(),
    const QuestsPage(),
    const CollectionPage(),
  ];

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        onScan: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CameraScreen()),
          );
        },
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late Future<List<Artwork>> _recommendedArtworks;
  late Future<List<Museum>> _recommendedMuseums;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
    _getUserLocation();

    final user = Provider.of<UserProvider>(context, listen: false).user;
    final uid = user?.id ?? "default_uid";


    WidgetsBinding.instance.addPostFrameCallback((_) {
    _showTutorialIfNeeded(uid);
  });
  }

  Future<void> _showTutorialIfNeeded(String uid) async {
  final prefs = await SharedPreferences.getInstance();
  final hasSeenTutorial = prefs.getBool('seen_tutorial_$uid') ?? false;

  if (!hasSeenTutorial) {
    await prefs.setBool('seen_tutorial_$uid', true);

    if (!mounted) return;

    // 1️⃣ Premier pop-up : Bouton Profile (en haut à droite)
    await showBlurryDialog(
      context: context,
      title: const Row(
        children: [
          Icon(Icons.account_circle, color: Colors.blue),
          SizedBox(width: 8),
          Text("Votre Profil"),
        ],
      ),
      content: "Cliquez sur votre avatar pour accéder à votre profil et consulter vos oevres et monvements préférés.",
      buttonText: "Suivant",
      triangleAlignment: 0.93, // Pointage vers le profil en haut à droite
      verticalAlignment: -0.5, // Positionnement pour pointer vers le profil
      pointUp: true, // Triangle pointant vers le haut
    );

    // 2️⃣ Deuxième pop-up : Onglet Accueil
    if (!mounted) return;
    await showBlurryDialog(
      context: context,
      title: const Row(
        children: [
          Icon(Icons.home, color: Colors.blue),
          SizedBox(width: 8),
          Text("Accueil"),
        ],
      ),
      content: "Vous êtes déjà sur la page d'accueil ! Ici vous trouverez vos œuvres recommandées et les musées proches de vous.",
      buttonText: "Suivant",
      triangleAlignment: 0.05, // Premier onglet de la navbar
      verticalAlignment: 0.6,
    );

    // 3️⃣ Troisième pop-up : Onglet Explorer/Carte
    if (!mounted) return;
    await showBlurryDialog(
      context: context,
      title: const Row(
        children: [
          Icon(Icons.map, color: Colors.blue),
          SizedBox(width: 8),
          Text("Explorer"),
        ],
      ),
      content: "Dans l'onglet Explorer, découvrez tous les musées sur une carte interactive pour planifiez vos visites.",
      buttonText: "Suivant",
      triangleAlignment: 0.26, // Deuxième onglet de la navbar
      verticalAlignment: 0.6,
    );

    // 4️⃣ Quatrième pop-up : Bouton Scanner (centre)
    if (!mounted) return;
    await showBlurryDialog(
      context: context,
      title: const Row(
        children: [
          Icon(Icons.camera_alt, color: Colors.blue),
          SizedBox(width: 8),
          Text("Scanner"),
        ],
      ),
      content: "Utilisez le bouton scanner pour photographier des œuvres et les ajouter automatiquement à votre collection !",
      buttonText: "Suivant",
      triangleAlignment: 0.5, // Bouton central de scan
      verticalAlignment: 0.6,
    );

    // 5️⃣ Cinquième pop-up : Onglet Quêtes
    if (!mounted) return;
    await showBlurryDialog(
      context: context,
      title: const Row(
        children: [
          Icon(Icons.assignment, color: Colors.blue),
          SizedBox(width: 8),
          Text("Quêtes"),
        ],
      ),
      content: "Relevez des défis amusants et découvrez l'art de manière ludique avec nos quêtes spécialement conçues pour vous.",
      buttonText: "Suivant",
      triangleAlignment: 0.74, // Troisième onglet de la navbar
      verticalAlignment: 0.6,
    );

    // 6️⃣ Sixième pop-up : Onglet Collection
    if (!mounted) return;
    await showBlurryDialog(
      context: context,
      title: const Row(
        children: [
          Icon(Icons.apps, color: Colors.blue),
          SizedBox(width: 8),
          Text("Ma Collection"),
        ],
      ),
      content: "Retrouvez toutes les œuvres que vous avez découvertes et ajoutées à votre collection personnelle.",
      buttonText: "Suivant",
      triangleAlignment: 0.95, // Quatrième onglet de la navbar
      verticalAlignment: 0.6,
    );

    // Pop-up de bienvenue final
    if (!mounted) return;
    await showBlurryDialog(
      context: context,
      title: const Row(
        children: [
          Icon(Icons.celebration, color: Colors.green),
          SizedBox(width: 8),
          Text("Prêt à explorer !"),
        ],
      ),
      content: "Vous êtes maintenant prêt à découvrir l'art ! Commencez par explorer les recommandations ci-dessous.",
      buttonText: "C'est parti !",
      triangleAlignment: -1,
      verticalAlignment: 0.0,
    );
  }
}


  void _loadRecommendations() {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final uid = user?.id ?? "default_uid";

    setState(() {
      _recommendedArtworks = RecommendationService().fetchRecommendations(uid);
      _recommendedMuseums = MuseumService().fetchMuseums().then((museums) {
        return museums;
      });
    });
  }

  void _updateRecommendations() {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final uid = user?.id ?? "default_uid"; // Use a default UID if user is null
    setState(() {
      RecommendationService().majRecommendations(uid);
      _recommendedArtworks = RecommendationService().fetchRecommendations(uid);
    });
  }

  Future<void> _getUserLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      _sortAndUpdateMuseums();
    } catch (e, stack) {
      debugPrint("Erreur localisation : $e\n$stack");
    }
  }

  void _sortAndUpdateMuseums() {
    if (_currentLocation == null) return;

    _recommendedMuseums.then((museums) {
      // Filtrer les musées à une distance maximale de 50 km
      final nearbyMuseums = museums.where((museum) {
        final museumLocation =
            LatLng(museum.location.latitude, museum.location.longitude);
        final distance = _calculateDistance(_currentLocation!, museumLocation);
        return distance <= 50000; // Distance maximale de 50 km
      }).toList();

      // Trier les musées restants par distance
      final sortedMuseums = _sortMuseumsByDistance(nearbyMuseums);

      // Limiter à 10 musées
      final topMuseums = sortedMuseums.take(10).toList();

      setState(() {
        _recommendedMuseums = Future.value(topMuseums);
      });
    });
  }

  double _calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
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

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Salut, ${user != null && user.username.isNotEmpty ? user.username : "Invité"} 👋',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Explore les musées !",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _updateRecommendations,
                    color: Colors.blue,
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProfilePage()),
                      );
                    },
                    child: CircleAvatar(
                      radius: 24,
                      backgroundImage: AssetImage(user!.profilePhoto),
                    ),
                  ),
                ],
              )
            ],
          ),
          // const SizedBox(height: 24),
          // TextField(
          //   decoration: InputDecoration(
          //     hintText: "Search places",
          //     prefixIcon: const Icon(Icons.search),
          //     border: OutlineInputBorder(
          //       borderRadius: BorderRadius.circular(12),
          //       borderSide: BorderSide.none,
          //     ),
          //     filled: true,
          //     fillColor: Colors.grey[200],
          //   ),
          // ),
          const SizedBox(height: 24),
          const Text(
            "Oeuvres recommandées",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 260,
            child: FutureBuilder<List<Artwork>>(
              future: _recommendedArtworks,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  debugPrint("Error or empty artworks: ${snapshot.error}");
                  return const Center(
                      child: Text("Aucune oeuvre recommandée !"));
                }

                final artworks = snapshot.data!;
                return PageView.builder(
                  itemCount: artworks.length,
                  itemBuilder: (context, index) {
                    final artwork = artworks[index];
                    return _buildCarouselItem(artwork.toImage(), artwork.title);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Musées Proches",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: FutureBuilder<List<Museum>>(
              future: _recommendedMuseums,
              builder: (context, snapshot) {
                if (_currentLocation == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  debugPrint("Error or empty artworks: ${snapshot.error}");
                  return const Center(child: Text("Aucun musée disponible."));
                }

                final museums = snapshot.data!;
                return PageView.builder(
                  itemCount: museums.length,
                  itemBuilder: (context, index) {
                    final museum = museums[index];
                    final distance = _currentLocation != null
                        ? _calculateDistance(
                            _currentLocation!,
                            LatLng(
                              museum.location.latitude,
                              museum.location.longitude,
                            ),
                          )
                        : null;
                    return _buildCarouselItemWithDistance(
                      museum.toImage(),
                      museum.title,
                      distance,
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

  Widget _buildCarouselItem(Image image, String title) {
    return InkWell(
      onTap: () {
        final artworks = _recommendedArtworks;
        artworks.then((artworksList) {
          final selectedArtwork = artworksList.firstWhere(
            (artwork) => artwork.title == title,
            orElse: () => throw Exception('Oeuvre non trouvée'),
          );

          Navigator.push(
            // ignore: use_build_context_synchronously
            context,
            MaterialPageRoute(
              builder: (context) => DetailArtworkPage(
                artwork: selectedArtwork,
              ),
            ),
          );
        });
      },
      child: Column(
        children: [
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.transparent, // Ombre invisible
                  blurRadius: 6,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image(
                image: image.image, // Récupère le provider d'image
                fit: BoxFit.contain, // Préserve le ratio d'aspect
                width: double.infinity,
                height: 200,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child; // Image chargée
                  }
                  return const Center(
                    child: CircularProgressIndicator(), // Rond de chargement
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child:
                        Icon(Icons.error, color: Colors.red), // En cas d'erreur
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselItemWithDistance(
      Image image, String title, double? distance) {
    bool isFar = distance != null && distance > 5000;

    return InkWell(
      onTap: () {
        final museums = _recommendedMuseums;
        museums.then((museumsList) {
          final selectedMuseum = museumsList.firstWhere(
            (museum) => museum.title == title,
            orElse: () => throw Exception('Musée non trouvé'),
          );

          Navigator.push(
            // ignore: use_build_context_synchronously
            context,
            MaterialPageRoute(
              builder: (context) => DetailMuseumPage(
                museum: selectedMuseum,
              ),
            ),
          );
        });
      },
      child: Column(
        children: [
          Container(
            height: 180,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.transparent, // Ombre invisible
                  blurRadius: 6,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image(
                image: image.image, // Récupère le provider d'image
                fit: BoxFit.contain, // Préserve le ratio d'aspect
                width: double.infinity,
                height: 180,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return isFar
                        ? ColorFiltered(
                            colorFilter: const ColorFilter.matrix([
                              0.3, 0.3, 0.3, 0, 0, // Rouge
                              0.3, 0.3, 0.3, 0, 0, // Vert
                              0.3, 0.3, 0.3, 0, 0, // Bleu
                              0, 0, 0, 1, 0, // Alpha
                            ]),
                            child: child,
                          )
                        : child; // Image chargée, avec ou sans filtre
                  }
                  return const Center(
                    child: CircularProgressIndicator(), // Rond de chargement
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child:
                        Icon(Icons.error, color: Colors.red), // En cas d'erreur
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (distance != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                "À ${(distance / 1000).toStringAsFixed(2)} km", 
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}
