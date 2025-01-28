import 'dart:convert';

import 'package:GAIA/model/artwork.dart';

import '../services/http_service.dart';

class ProfilageService {
  final HttpService _httpService = HttpService();
  final String baseUrl = "http://127.0.0.1:5000/profiling/api/profilage/";

  // Fonction pour modifier les marques d'un utilisateur
  Future<String> modifyBrands(String artworkId, String uid) async {
    final response = await _httpService.post(baseUrl, body: {
      'artworkId': artworkId,
      'uid': uid,
    });

    if (response.statusCode == 200) {
      return "Brands updated successfully";
    } else if (response.statusCode == 400) {
      throw Exception("Missing artworkId or uid");
    } else {
      throw Exception("Failed to update brands");
    }
  }

  // Fonction pour récupérer les artworks d'un utilisateur
  Future<List<Artwork>> fetchArtworks() async {
    final response =
        await _httpService.get("http://127.0.0.1:5000/profiling/api/artworks");

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)['data'];

      return data.map((item) {
        return Artwork.fromJson(item);
      }).toList();
    } else {
      throw Exception("Failed to load artworks: ${response.statusCode}");
    }
  }

  // Ajouter d'autres méthodes si nécessaire
}
