import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfilageService {
  final String baseUrl = "http://127.0.0.1:5000/api/profilage/";

  // Fonction pour modifier les marques d'un utilisateur
  Future<String> modifyBrands(String artworkId, String uid) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'artworkId': artworkId,
        'uid': uid,
      }),
    );

    if (response.statusCode == 200) {
      return "Brands updated successfully";
    } else if (response.statusCode == 400) {
      throw Exception("Missing artworkId or uid");
    } else {
      throw Exception("Failed to update brands");
    }
  }

  // Ajouter d'autres méthodes si nécessaire (ex. récupérer le profil, etc.)
}
