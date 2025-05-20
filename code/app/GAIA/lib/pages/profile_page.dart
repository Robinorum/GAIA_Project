import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:GAIA/provider/userProvider.dart';
import 'package:GAIA/pages/settings_page.dart';
import 'package:GAIA/pages/museum_completion_page.dart';
import 'package:GAIA/pages/profile_picture_page.dart';
import 'package:GAIA/services/profilage_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    // Données fictives pour tester
    List<Map<String, dynamic>> visitedMuseums = [
      {
        "name": "Museum of Modern Art",
        "city": "New York",
        "collected": 34,
        "total": 34
      },
      {"name": "Louvre Museum", "city": "Paris", "collected": 26, "total": 60},
      {"name": "The Met", "city": "New York", "collected": 7, "total": 28},
      {"name": "National Gallery", "city": "Oslo", "collected": 5, "total": 31},
      {
        "name": "Belvedere Museum",
        "city": "Vienna",
        "collected": 3,
        "total": 29
      },
      {
        "name": "Museo Reina Sofia",
        "city": "Madrid",
        "collected": 8,
        "total": 112
      },
    ];

    visitedMuseums.sort((a, b) =>
        (b["collected"] / b["total"]).compareTo(a["collected"] / a["total"]));

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 50, left: 16, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Bouton retour
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 28),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  // Icône réglages (settings)
                  IconButton(
                    icon: const Icon(Icons.settings, size: 28),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SettingsPage(onToggleTheme: (isDarkMode) {}),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Header: Couverture + Photo de profil
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      AssetImage(user!.profilePhoto), // Replace with real image
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePicturePage(),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      padding: const EdgeInsets.all(6),
                      child:
                          const Icon(Icons.edit, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),
            Text(
              user.username,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatItem("6", "Museum Visited"),
                _buildDivider(),
                _buildStatItem("27", "Artwork Collected"),
              ],
            ),
            const SizedBox(height: 20),
            _buildSectionTitle("Favourite Movement"),
            // Utilisation de FutureBuilder pour les mouvements favoris
            FutureBuilder<List<String>>(
              future: ProfilageService().fetchTopMovements(user.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator(); // Chargement
                } else if (snapshot.hasError) {
                  return const Text("Failed to load movements"); // Erreur
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text("No movements found"); // Aucune donnée
                }

                final movements = snapshot.data!;
                final favoriteMovements =
                    List.generate(movements.length, (index) {
                  Color color;
                  switch (index) {
                    case 0:
                      color = Colors.amber; // Gold
                      break;
                    case 1:
                      color = Colors.grey; // Silver
                      break;
                    default:
                      color = Colors.brown; // Bronze
                  }
                  return {"name": movements[index], "color": color};
                });

                return Column(
                  children: favoriteMovements
                      .asMap()
                      .entries
                      .map((entry) => _buildMovementTile(
                          entry.key + 1,
                          entry.value["name"] as String,
                          entry.value["color"] as Color))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildSectionTitle("Visited Museum"),
            Column(
              children: visitedMuseums
                  .take(3)
                  .map((museum) => _buildMuseumProgress(museum))
                  .toList(),
            ),
            const SizedBox(height: 10),
            // "See All" Button
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          MuseumCompletionPage(visitedMuseums: visitedMuseums)),
                );
              },
              child: const Text("See All",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(count,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      child: SizedBox(
        height: 25,
        child: VerticalDivider(color: Colors.grey, thickness: 0.5),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildMovementTile(int rank, String name, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Text("Top $rank :",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        title: Text(name, style: const TextStyle(fontSize: 16)),
        tileColor: color.withOpacity(0.3),
      ),
    );
  }

  Widget _buildMuseumProgress(Map<String, dynamic> museum) {
    double progress = museum["collected"] / museum["total"];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${museum['name']} - ${museum['city']}"),
          LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              color: Colors.amber),
          Text("${museum['collected']}/${museum['total']}"),
        ],
      ),
    );
  }
}
