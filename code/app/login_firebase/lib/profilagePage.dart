import 'package:flutter/material.dart';

class ProfilagePage extends StatelessWidget {
  const ProfilagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Selectionnez les styles que vous aimez"),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1, // Assure que les images sont carrées
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: 14, // 2 colonnes * 7 lignes
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    // Logique de sélection de l'image
                  },
                  child: Image.asset(
                    'assets/image_$index.jpg', // Remplacez par les chemins d'images
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  // Logique de traitement des images sélectionnées
                },
                child: const Text("Envoyer"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
