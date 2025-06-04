import 'package:gaia/services/artwork_service.dart';
import 'package:flutter/material.dart';
import 'package:gaia/services/user_service.dart';
import 'package:provider/provider.dart';
import '../model/artwork.dart';
import 'package:gaia/provider/user_provider.dart';
import 'package:gaia/pages/home_page.dart';
import '../services/recommendation_service.dart';

class ProfilagePage extends StatefulWidget {
  const ProfilagePage({super.key});

  @override
  State<ProfilagePage> createState() => _ProfilagePageState();
}

class _ProfilagePageState extends State<ProfilagePage>
    with TickerProviderStateMixin {
  late Future<List<Artwork>> _recommendedArtworks;
  int currentIndex = 0;
  double offset = 0;
  double angle = 0;
  
  late AnimationController _museumController;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    _recommendedArtworks = ArtworkService().fetchArtworks();
    
    // Animation pour le musée
    _museumController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fillAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _museumController,
      curve: Curves.easeInOut,
    ));
    
    // Démarre l'animation en boucle
    _museumController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _museumController.dispose();
    super.dispose();
  }

  void handleSwipe(String direction, Artwork artwork) async {
    setState(() {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      if (direction == 'right') {
        UserService().toggleLike(artwork, user!, "like");
      } else {
        UserService().toggleLike(artwork, user!, "dislike");
      }
      currentIndex++;
      offset = 0;
      angle = 0;
    });

    if (currentIndex == 5) {
      _handleProfilageCompleted();
    }
  }

  Future<void> _handleProfilageCompleted() async {
    // Affiche une roue de chargement avec animation musée
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildMuseumLoadingDialog(),
    );

    final user = Provider.of<UserProvider>(context, listen: false).user;
    final uid = user?.id ?? 'Default-uid';

    // Met à jour les recommandations
    final newArtworks = await RecommendationService().majRecommendations(uid);

    // Ferme le loader
    if (mounted) Navigator.of(context).pop();

    // Redirige vers la HomePage si recommandations disponibles
    if (newArtworks.isNotEmpty) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Aucune recommandation trouvée."),
        ));
      }
    }
  }

  Widget _buildMuseumLoadingDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animation du musée
            AnimatedBuilder(
              animation: _fillAnimation,
              builder: (context, child) {
                return _buildMuseumAnimation(_fillAnimation.value);
              },
            ),
            const SizedBox(height: 20),
            const Text(
              "Chargement de votre profil",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const LinearProgressIndicator(
              backgroundColor: Colors.grey,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMuseumAnimation(double fillValue) {
    return SizedBox(
      width: 120,
      height: 80,
      child: CustomPaint(
        painter: MuseumPainter(fillValue),
        child: Container(),
      ),
    );
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animation du musée pour le chargement initial
                  AnimatedBuilder(
                    animation: _fillAnimation,
                    builder: (context, child) {
                      return _buildMuseumAnimation(_fillAnimation.value);
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Chargement de votre profil",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                ],
              ),
            );
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
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _fillAnimation,
                        builder: (context, child) {
                          return _buildMuseumAnimation(_fillAnimation.value);
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Chargement de votre profil",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
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
            key: ValueKey(artwork.id),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: RepaintBoundary(
                    child: Container(
                      height: 400,
                      width: 300,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.2 * 255).toInt()),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: FadeInImage(
                        placeholder: const AssetImage('assets/placeholder.png'),
                        image: artwork.toImage().image,
                        fit: BoxFit.cover,
                        fadeInCurve: Curves.easeIn,
                        fadeInDuration: const Duration(milliseconds: 300),
                        imageErrorBuilder: (context, error, stackTrace) {
                          return const Center(
                              child: Icon(Icons.error,
                                  color: Colors.red, size: 50));
                        },
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
                    artwork.title.length > 40 
                      ? '${artwork.title.substring(0, 40)}...' 
                      : artwork.title,
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

// CustomPainter pour dessiner le musée avec animation de remplissage
class MuseumPainter extends CustomPainter {
  final double fillValue;

  MuseumPainter(this.fillValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

  

    // Dessine la structure du musée
    final path = Path();
    
    // Base du musée
    path.moveTo(10, size.height - 10);
    path.lineTo(size.width - 10, size.height - 10);
    path.lineTo(size.width - 10, size.height * 0.4);
    path.lineTo(size.width * 0.8, size.height * 0.4);
    path.lineTo(size.width * 0.5, size.height * 0.1);
    path.lineTo(size.width * 0.2, size.height * 0.4);
    path.lineTo(10, size.height * 0.4);
    path.close();

    // Dessine le remplissage animé
    if (fillValue > 0) {
      final fillPath = Path();
      final fillHeight = (size.height - 20) * fillValue;
      
      fillPath.moveTo(12, size.height - 10);
      fillPath.lineTo(size.width - 12, size.height - 10);
      fillPath.lineTo(size.width - 12, size.height - 10 - fillHeight);
      fillPath.lineTo(12, size.height - 10 - fillHeight);
      fillPath.close();
      
     
    }

    // Dessine le contour du musée
    canvas.drawPath(path, paint);

    // Dessine les colonnes
    for (int i = 0; i < 3; i++) {
      final x = size.width * (0.25 + i * 0.25);
      canvas.drawLine(
        Offset(x, size.height * 0.4),
        Offset(x, size.height - 10),
        paint,
      );
    }

    // Dessine la porte
    final doorRect = Rect.fromLTWH(
      size.width * 0.45,
      size.height * 0.6,
      size.width * 0.1,
      size.height * 0.3,
    );
    canvas.drawRect(doorRect, paint);

    // Dessine quelques œuvres d'art flottantes si le musée se remplit
    if (fillValue > 0.3) {
     
      
   
    }
  }

  @override
  bool shouldRepaint(MuseumPainter oldDelegate) {
    return oldDelegate.fillValue != fillValue;
  }
}