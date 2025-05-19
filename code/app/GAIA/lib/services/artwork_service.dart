import 'dart:convert';
import '../model/artwork.dart';
import '../model/museum.dart';
import 'http_service.dart';
import 'museum_service.dart';

class ArtworkService {
  final String baseUrl = "http://127.0.0.1:5000/reco/api/recom_get";
  final HttpService _httpService = HttpService();
  final MuseumService _museumService = MuseumService();

  // Fonction pour récupérer toutes les œuvres d'art
  Future<List<Artwork>> fetchArtworks() async {
    final response = await _httpService.get(baseUrl);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)['data'];

      return data.map((item) {
        return Artwork.fromJson(item);
      }).toList();
    } else {
      throw Exception("Failed to load artworks: ${response.statusCode}");
    }
  }

  // Fonction pour récupérer les recommandations d'un utilisateur par son UID
  Future<List<Artwork>> fetchRecommendations(String uid) async {
    final response = await _httpService.get("$baseUrl/$uid");

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)['data'];

      return data.map((item) {
        return Artwork.fromJson(
            item); // Conversion des données de chaque artwork en objet Artwork
      }).toList();
    } else {
      throw Exception("Failed to load recommendations: ${response.statusCode}");
    }
  }



  Future<Artwork?> getArtworkById(String id) async {
    final artworks = await fetchArtworks();
    return artworks.firstWhere(
      (artwork) => artwork.id == id,
      
    );
  }

  Future<Museum?> getMuseumById(String id) async{
    final museums = await _museumService.fetchMuseums();
    return museums.firstWhere(
      (museum) => museum.officialId == id,
    );
  }
  
}
