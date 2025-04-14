import 'package:flutter/material.dart';
import '../model/appUser.dart'; // Ton fichier avec la classe AppUser

class UserProvider extends ChangeNotifier {
  AppUser? _user;

  AppUser? get user => _user;

  // Méthode pour mettre à jour la photo de profil localement
  void updateProfileImage(String newProfileImage) {
    _user?.profilePhoto = newProfileImage; // Met à jour la photo dans l'objet user
    notifyListeners(); // Notifie les widgets intéressés par cette modification
  }

  void setUser(AppUser newUser) {
    _user = newUser;
    notifyListeners();
  }

  void clearUser() {
    _user = AppUser.empty();
    notifyListeners();
  }
}
