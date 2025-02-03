import 'package:flutter/material.dart';
import 'dart:ui';

class QuestsPage extends StatelessWidget {
  const QuestsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text("Quêtes"), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 🟢 Section 1 : Quêtes générales
          const Text(
            "Quêtes Générales",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const QuestCard(
            title: "Visite guidée du Louvre",
            description:
                "Trouvez et scannez 5 tableaux célèbres dans le Louvre.",
          ),
          const QuestCard(
            title: "Défi artistique",
            description: "Répondez correctement à 3 quiz sur des œuvres.",
          ),
          const QuestCard(
            title: "Explorateur de musées",
            description: "Visitez deux musées différents en une journée.",
          ),
          const SizedBox(height: 24),

          // 🔒 Section 2 : Quête du musée (verrouillée)
          const Text(
            "Quête du musée",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const LockedQuestCard(title: "Quête exclusive"),
        ],
      ),
    );
  }
}

// 🟢 Carte pour les quêtes générales
class QuestCard extends StatelessWidget {
  final String title;
  final String description;

  const QuestCard({
    Key? key,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(description),
        leading: const Icon(Icons.star, color: Colors.amber),
      ),
    );
  }
}

// 🔒 Carte pour la quête verrouillée du musée
class LockedQuestCard extends StatelessWidget {
  final String title;

  const LockedQuestCard({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 🖼️ Fond flou agrandi
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Effet de flou
            child: Container(
              height: 120, // 📏 Augmenter la hauteur pour bien centrer le texte
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1), // Légère opacité
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        // 🔒 Icône de cadenas + message
        Positioned.fill(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 36, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                title, // 🏆 Titre centré sous le cadenas
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Veuillez vous rapprocher d'un musée\npour débloquer les quêtes",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
