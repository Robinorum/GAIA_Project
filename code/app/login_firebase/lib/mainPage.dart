import 'package:flutter/material.dart';

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre et photo de profil
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Hi, Thomas 👋",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Explore the museum",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage('https://example.com/photo.jpg'), // Remplacez par l'URL de la photo de profil
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Barre de recherche
              TextField(
                decoration: InputDecoration(
                  hintText: "Search places",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () {
                      // Action de filtrage
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              const SizedBox(height: 24),

              // Section des lieux populaires
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Popular places",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "View all",
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Filtres (Most Viewed, Nearby, Best Rate)
              Row(
                children: [
                  FilterChip(
                    label: const Text("Most Viewed"),
                    selected: true,
                    onSelected: (bool value) {},
                    selectedColor: Colors.black,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text("Nearby"),
                    selected: false,
                    onSelected: (bool value) {},
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text("Best rate"),
                    selected: false,
                    onSelected: (bool value) {},
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Liste de lieux (Carrousel horizontal)
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    PlaceCard(
                      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/e/ec/Mona_Lisa%2C_by_Leonardo_da_Vinci%2C_from_C2RMF_retouched.jpg', // URL de l'image du Louvre
                      title: "Le Louvre, Paris",
                      location: "Paris, France",
                      rating: 4.8,
                    ),
                    const SizedBox(width: 16),
                    PlaceCard(
                      imageUrl: 'https://example.com/mucem.jpg', // URL de l'image du MUCEM
                      title: "MUCEM, Marseille",
                      location: "Marseille, France",
                      rating: 4.5,
                    ),
                    // Ajoutez d'autres cartes ici
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // Bouton de navigation flottant (au centre)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action à définir
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.home),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.location_on),
                onPressed: () {},
              ),
              const SizedBox(width: 48), // Espace pour le bouton flottant
              IconButton(
                icon: const Icon(Icons.favorite),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget pour les cartes de lieux
class PlaceCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String location;
  final double rating;

  const PlaceCard({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.location,
    required this.rating,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Image.network(
              imageUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(rating.toString()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
