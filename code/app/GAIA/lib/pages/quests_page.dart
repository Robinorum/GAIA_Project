// import 'package:flutter/material.dart';
// import 'dart:ui';

// class QuestsPage extends StatelessWidget {
//   const QuestsPage({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar:
//           AppBar(title: const Text("Quêtes"), automaticallyImplyLeading: false),
//       body: ListView(
//         padding: const EdgeInsets.all(16.0),
//         children: [
//           // 🟢 Section 1 : Quêtes générales
//           const Text(
//             "Quêtes Générales",
//             style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 12),
//           const QuestCard(
//             title: "Visite guidée du Louvre",
//             description:
//                 "Trouvez et scannez 5 tableaux célèbres dans le Louvre.",
//           ),
//           const QuestCard(
//             title: "Défi artistique",
//             description: "Répondez correctement à 3 quiz sur des œuvres.",
//           ),
//           const QuestCard(
//             title: "Explorateur de musées",
//             description: "Visitez deux musées différents en une journée.",
//           ),
//           const SizedBox(height: 24),

//           // 🔒 Section 2 : Quête du musée (verrouillée)
//           const Text(
//             "Quête du musée",
//             style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 12),
//           const LockedQuestCard(title: "Quête exclusive"),
//         ],
//       ),
//     );
//   }
// }

// class QuestCard extends StatelessWidget {
//   final String title;
//   final String description;

//   const QuestCard({
//     Key? key,
//     required this.title,
//     required this.description,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 16.0),
//       child: ListTile(
//         title: Text(
//           title,
//           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//         ),
//         subtitle: Text(description),
//         leading: const Icon(Icons.star, color: Colors.amber),
//       ),
//     );
//   }
// }


// class LockedQuestCard extends StatelessWidget {
//   final String title;

//   const LockedQuestCard({Key? key, required this.title}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         // 🖼️ Fond flou agrandi
//         ClipRRect(
//           borderRadius: BorderRadius.circular(12),
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Effet de flou
//             child: Container(
//               height: 120, // 📏 Augmenter la hauteur pour bien centrer le texte
//               decoration: BoxDecoration(
//                 color: Colors.black.withOpacity(0.1), // Légère opacité
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//           ),
//         ),
//         // 🔒 Icône de cadenas + message
//         Positioned.fill(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.lock, size: 36, color: Colors.grey),
//               const SizedBox(height: 8),
//               Text(
//                 title, // 🏆 Titre centré sous le cadenas
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black54,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               const Text(
//                 "Veuillez vous rapprocher d'un musée\npour débloquer les quêtes",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 12, color: Colors.grey),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }import 'dart:ui';

import 'dart:ui';

import 'package:GAIA/model/GeneralQuest.dart';
import 'package:GAIA/pages/all_quest_page.dart';
import 'package:GAIA/provider/userProvider.dart';
import 'package:GAIA/services/GeneralQuestService.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class QuestsPage extends StatefulWidget {
  const QuestsPage({Key? key}) : super(key: key);

  @override
  State<QuestsPage> createState() => _QuestsPageState();
}

class _QuestsPageState extends State<QuestsPage> {
  final GeneralQuestService _questService = GeneralQuestService();
  late Future<List<GeneralQuest>> _questsFuture;

  @override
  void initState() {
    super.initState();
    _questsFuture = _questService.fetchGeneralQuests();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final uid = user?.id ?? "default_uid";

    return Scaffold(
      appBar: AppBar(title: const Text("Quêtes"), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Quêtes Générales", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Chargement des quêtes
            Expanded(
              child: FutureBuilder<List<GeneralQuest>>(
                future: _questsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Erreur: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("Aucune quête disponible."));
                  }

                  final quests = snapshot.data!;
                  return ListView.builder(
                    itemCount: quests.length,
                    itemBuilder: (context, index) {
                      final quest = quests[index];
                      int goalProgress = quest.getGoalProgress(uid);

                      // Détermination des étoiles
                      List<Widget> stars = List.generate(
                        3,
                        (i) => Icon(
                          i < goalProgress ? Icons.star : Icons.star_border, // Étoile remplie ou vide
                          color: Colors.amber,
                        ),
                      );

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200], // Fond neutre
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            quest.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(quest.description),
                              Row(children: stars), // Affichage des étoiles
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Bouton "Tout voir"
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AllQuestsPage()),
                  );
                },
                child: const Text("Tout voir"),
              ),
            ),

            const SizedBox(height: 24),

            // 🔒 Quête verrouillée
            const Text("Quête du musée", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock, size: 36, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text(
                        "Quête exclusive",
                        style: TextStyle(
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
            ),
          ],
        ),
      ),
    );
  }
}
