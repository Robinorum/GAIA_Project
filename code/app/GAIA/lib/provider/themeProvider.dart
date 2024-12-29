import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  // Méthode pour changer le thème
  void toggleTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }

  // Récupérer le thème en fonction du mode
  ThemeData get currentTheme {
    return _isDarkMode ? ThemeData.dark() : ThemeData.light();
  }
}
