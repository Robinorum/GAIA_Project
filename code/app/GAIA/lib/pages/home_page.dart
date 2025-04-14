import 'package:flutter/material.dart';
import 'package:GAIA/provider/userProvider.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:GAIA/pages/collection_page.dart';
import 'package:GAIA/pages/map_page.dart';
import 'package:GAIA/pages/profile_page.dart';
import 'package:GAIA/pages/quests_page.dart';
import 'package:GAIA/pages/detail_artwork_page.dart';
import '../component/custom_bottom_nav.dart';
import '../scan/camera_screen.dart';
import '../services/recommendation_service.dart';
import '../services/museum_service.dart';
import '../model/artwork.dart';
import '../model/museum.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../pages/detail_museum_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomeContent(),
    MapPage(),
    QuestsPage(),
    CollectionPage(),
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
            MaterialPageRoute(builder: (context) => CameraScreen()),
          );
        },
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  HomeContent({Key? key}) : super(key: key);

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
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      _sortAndUpdateMuseums();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error getting location: $e")),
      );
    }
  }

void _sortAndUpdateMuseums() {
  if (_currentLocation == null) return;

  _recommendedMuseums.then((museums) {
    // Filtrer les musées à une distance maximale de 50 km
    final nearbyMuseums = museums.where((museum) {
      final museumLocation = LatLng(museum.location.latitude, museum.location.longitude);
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
                    'Hi, ${user != null && user.username.isNotEmpty ? user.username : "Guest"} 👋',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Explore the museum",
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
                        MaterialPageRoute(builder: (context) => ProfilePage()),
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
          const SizedBox(height: 24),
          TextField(
            decoration: InputDecoration(
              hintText: "Search places",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[200],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Recommended Artworks",
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
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error loading artworks: ${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No artworks found."));
                }

                final artworks = snapshot.data!;
                return PageView.builder(
                  itemCount: artworks.length,
                  itemBuilder: (context, index) {
                    final artwork = artworks[index];
                    return _buildCarouselItem(artwork.toImage() as Image, artwork.title);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Recommended Museums",
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
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error loading museums: ${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No museums found."));
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
                      museum.toImage() as Image,
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
      final artworks = _recommendedArtworks as Future<List<Artwork>>;
      artworks.then((artworksList) {
        final selectedArtwork = artworksList.firstWhere(
          (artwork) => artwork.title == title,
          orElse: () => throw Exception('Artwork not found'),
        );

        Navigator.push(
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
            boxShadow: [
              BoxShadow(
                color: Colors.transparent, // Ombre invisible
                blurRadius: 6,
                offset: const Offset(0, 4),
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
                  child: Icon(Icons.error, color: Colors.red), // En cas d'erreur
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

Widget _buildCarouselItemWithDistance(Image image, String title, double? distance) {
  bool isFar = distance != null && distance > 5000;

  return InkWell(
    onTap: () {
      final museums = _recommendedMuseums as Future<List<Museum>>;
      museums.then((museumsList) {
        final selectedMuseum = museumsList.firstWhere(
          (museum) => museum.title == title,
          orElse: () => throw Exception('Museum not found'),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailMuseumPage(
              museum: selectedMuseum,
              distance: distance ?? 0,
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
            boxShadow: [
              BoxShadow(
                color: Colors.transparent, // Ombre invisible
                blurRadius: 6,
                offset: const Offset(0, 4),
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
                  child: Icon(Icons.error, color: Colors.red), // En cas d'erreur
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
              "${(distance / 1000).toStringAsFixed(2)} km away",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
      ],
    ),
  );
}
}