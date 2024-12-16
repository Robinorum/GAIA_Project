import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _currentIndex = 0; // Gère l'état de la navigation

  // Liste des pages à afficher
  final List<Widget> _pages = [
    const ProfilePageContent(),
    // Ajoute ici d'autres pages que tu veux gérer (par exemple, une page "Settings")
  ];

  // Gestion du tap sur la barre de navigation
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
    ));
  }
}

class ProfilePageContent extends StatelessWidget {
  const ProfilePageContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Couverture (cover image)
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
        // Découpe pour l'image de profil et contenu principal
        Column(
          children: [
            const SizedBox(height: 180), // Espace pour le header
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(
                          height: 70), // Décalage sous l'image de profil
                      // Nom et Infos utilisateur
                      const Text(
                        "Favour Isechap",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Product Designer",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_on,
                              color: Colors.redAccent, size: 16),
                          SizedBox(width: 4),
                          Text(
                            "Taraba, Nigeria",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 16),
                      // Boutons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildButton("Edit Profile", Colors.blue),
                          const SizedBox(width: 16),
                          _buildButton("Share Profile", Colors.blue),
                        ],
                      ),
                    ],
                  ),
                ),
                // Image de profil
                Positioned(
                  top: -60,
                  left: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 55,
                      backgroundImage: NetworkImage(
                          "https://i.pravatar.cc/150?img=10"), // Image de profil
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Widget pour afficher les statistiques
  static Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  // Séparateur vertical
  static Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.0),
      child: SizedBox(
        height: 30,
        child: VerticalDivider(
          color: Colors.grey,
          thickness: 0.5,
        ),
      ),
    );
  }

  // Widget pour les boutons
  static Widget _buildButton(String label, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      onPressed: () {},
      child: Text(label),
    );
  }
}
