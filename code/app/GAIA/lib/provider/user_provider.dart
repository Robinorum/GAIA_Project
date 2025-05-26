import 'package:flutter/material.dart';
import '../model/app_user.dart'; // Ton fichier avec la classe AppUser
import '../services/user_service.dart';

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

  Future<void> updateProfile() async {
    final updatedUser = await UserService().fetchProfile(_user!.id);
    if (updatedUser != null) {
      _user = updatedUser;
      notifyListeners();
    }
  }
}
