import 'package:flutter/material.dart';
import '../model/appUser.dart'; // Ton fichier avec la classe AppUser

class UserProvider extends ChangeNotifier {
  AppUser? _user;

  AppUser? get user => _user;

  void setUser(AppUser newUser) {
    _user = newUser;
    notifyListeners();
  }
}
