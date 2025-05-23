import 'package:flutter/material.dart';
import 'package:gaia/provider/theme_provider.dart';
import 'package:gaia/settings/change_email_page.dart';
import 'package:gaia/settings/change_password_page.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gaia/login/login_page.dart';
import 'package:gaia/provider/user_provider.dart';

class SettingsPage extends StatefulWidget {
  final Function(bool isDarkMode) onToggleTheme;

  const SettingsPage({super.key, required this.onToggleTheme});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isNotificationsEnabled = true;
  String _selectedLanguage = 'Français';

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Paramètres"),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 4.0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Section Apparence
            _buildSectionTitle("Thème"),
            _buildListTile(
              title: "Thème sombre",
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme(value);
                  widget.onToggleTheme(value); // Passer le changement de thème
                },
              ),
            ),
            const Divider(),

            // Section Notifications
            _buildSectionTitle("Notifications"),
            _buildListTile(
              title: "Activer les notifications",
              trailing: Switch(
                value: _isNotificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _isNotificationsEnabled = value;
                  });
                },
              ),
            ),
            const Divider(),

            // Section Langue
            _buildSectionTitle("Langue"),
            ListTile(
              title: const Text("Langue", style: TextStyle(fontSize: 18)),
              subtitle:
                  Text(_selectedLanguage, style: const TextStyle(fontSize: 16)),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showLanguageDialog();
              },
            ),
            const Divider(),

            // Section Compte
            _buildSectionTitle("Compte"),
            _buildListTile(
              title: "Changer l'adresse mail",
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ChangeEmailPage(),
                  ),
                );
              },
            ),
            _buildListTile(
              title: "Changer le nom d'utilisateur",
              onTap: () {
                // Navigation vers une page de modification du mot de passe
              },
            ),
            _buildListTile(
              title: "Change le mot de passe",
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ChangePasswordPage(),
                  ),
                );
              },
            ),
            const Divider(),

            // Bouton Log Out
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                // ignore: use_build_context_synchronously
                Provider.of<UserProvider>(context, listen: false).clearUser();
                // ignore: use_build_context_synchronously
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) =>
                        const LoginPage(title: "Page d'authentification"),
                  ),
                  (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Red background
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                "Se déconnecter",
                style:
                    TextStyle(fontSize: 16, color: Colors.white), // White text
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fonction pour construire un titre de section
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Fonction pour construire une liste de tuiles
  Widget _buildListTile({
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 18)),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      tileColor: Theme.of(context).cardColor,
      subtitle: trailing == null
          ? null
          : const Text("Appuyez pour changer", style: TextStyle(fontSize: 14)),
    );
  }

  // Afficher une boîte de dialogue pour changer la langue
  Future<void> _showLanguageDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Sélectionner une langue"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ListTile(
                  title: const Text("Français"),
                  onTap: () {
                    setState(() {
                      _selectedLanguage = 'Français';
                    });
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text("English"),
                  onTap: () {
                    setState(() {
                      _selectedLanguage = 'English';
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
