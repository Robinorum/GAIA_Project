import 'package:flutter/material.dart';
import 'package:GAIA/pages/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Profilage Page',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ProfilagePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ProfilagePage extends StatefulWidget {
  const ProfilagePage({super.key});

  @override
  State<ProfilagePage> createState() => _ProfilagePageState();
}

class _ProfilagePageState extends State<ProfilagePage> with SingleTickerProviderStateMixin {
  final List<Map<String, String>> artworks = [
    {
      'imageUrl': 'https://via.placeholder.com/600x800.png?text=Image+1',
      'title': 'Oeuvre 1',
      'location': 'Musée du Louvre',
      'type': 'Cubisme',
    },
    {
      'imageUrl': 'https://via.placeholder.com/600x800.png?text=Image+2',
      'title': 'Oeuvre 2',
      'location': 'Musée d\'Orsay',
      'type': 'Impressionnisme',
    },
    {
      'imageUrl': 'https://via.placeholder.com/600x800.png?text=Image+3',
      'title': 'Oeuvre 3',
      'location': 'Tate Modern',
      'type': 'Suréalisme',
    },
    {
      'imageUrl': 'https://via.placeholder.com/600x800.png?text=Image+4',
      'title': 'Oeuvre 4',
      'location': 'Guggenheim',
      'type': 'Expressionnisme',
    },
    {
      'imageUrl': 'https://via.placeholder.com/600x800.png?text=Image+5',
      'title': 'Oeuvre 5',
      'location': 'Centre Pompidou',
      'type': 'Minimalisme',
    },
  ];

  int currentIndex = 0;
  double offset = 0;
  double angle = 0;

  void handleSwipe(String direction) {
    setState(() {
      if (direction == 'right') {
        print('Liké: ${artworks[currentIndex]['title']}');
      } else if (direction == 'left') {
        print('Pas Liké: ${artworks[currentIndex]['title']}');
      }
      currentIndex++;
      offset = 0; // Réinitialisation de l'offset
      angle = 0;  // Réinitialisation de l'angle

      if (currentIndex == artworks.length) {
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
    return Scaffold(
      body: currentIndex < artworks.length
          ? Center(
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    offset = details.localPosition.dx; // Déplacer la carte
                    angle = offset / 10; // Appliquer une rotation proportionnelle
                  });
                },
                onPanEnd: (details) {
                  if (offset > 100) {
                    handleSwipe('right'); // Swipe droite
                  } else if (offset < -100) {
                    handleSwipe('left'); // Swipe gauche
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
          : const Center(child: Text("Chargement...")),
    );
  }

  Widget buildArtworkCard(Map<String, String> artwork, double offset, double angle) {
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
                    image: NetworkImage(artwork['imageUrl']!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Informations sur l'œuvre
              Text(
                artwork['title']!,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                'Localisation: ${artwork['location']}',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                'Type: ${artwork['type']}',
                style: const TextStyle(
                    fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              // Boutons Like et Dislike
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => handleSwipe('left'),
                    icon: const Icon(Icons.close, color: Colors.red, size: 40),
                  ),
                  const SizedBox(width: 50),
                  IconButton(
                    onPressed: () => handleSwipe('right'),
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


