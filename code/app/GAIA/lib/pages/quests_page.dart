import 'package:flutter/material.dart';

class QuestsPage extends StatelessWidget {
  const QuestsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text("Quêtes"), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          QuestCard(
            title: "Visite guidée du Louvre",
            description:
                "Trouvez et scannez 5 tableaux célèbres dans le Louvre.",
          ),
          QuestCard(
            title: "Défi artistique",
            description: "Répondez correctement à 3 quiz sur des œuvres.",
          ),
          QuestCard(
            title: "Explorateur de musées",
            description: "Visitez deux musées différents en une journée.",
          ),
        ],
      ),
    );
  }
}

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
