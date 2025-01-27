import 'dart:convert';
import '../model/artwork.dart';
import 'http_service.dart';

class ArtworkService {
  final String baseUrl = "http://127.0.0.1:5000/reco/api/artworks";
  final HttpService _httpService = HttpService();

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
}
