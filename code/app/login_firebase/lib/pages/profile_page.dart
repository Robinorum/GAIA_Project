import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Retourne à la page précédente
          },
        ),
      ),
      body: SingleChildScrollView(
        // Permet le défilement pour éviter le débordement
        child: Column(
          children: [
            Stack(
              children: [
                // Image de couverture
                Container(
                  height: 250,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                          "https://upload.wikimedia.org/wikipedia/commons/6/6d/Louvre_Museum_Wikimedia_Commons.jpg"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Avatar flottant
                Positioned(
                  top: 160,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 55,
                        backgroundImage:
                            NetworkImage("https://i.pravatar.cc/150?img=10"),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 80), // Espacement après l'avatar

            // Contenu de la page de profil
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Favour Isechap",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "Product Designer",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.location_on,
                            color: Colors.redAccent, size: 20),
                        SizedBox(width: 4),
                        Text("Taraba, Nigeria",
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Statistiques
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatItem("205", "Followers"),
                        _buildDivider(),
                        _buildStatItem("178", "Following"),
                        _buildDivider(),
                        _buildStatItem("68", "Points"),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Boutons d'action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildButton("Edit Profile", Colors.blue),
                        const SizedBox(width: 16),
                        _buildButton("Share Profile", Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour afficher les statistiques
  static Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  // Séparateur vertical
  static Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.0),
      child: SizedBox(
        height: 30,
        child: VerticalDivider(color: Colors.grey, thickness: 0.5),
      ),
    );
  }

  // Widget pour les boutons
  static Widget _buildButton(String label, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      onPressed: () {},
      child: Text(label),
    );
  }
}
