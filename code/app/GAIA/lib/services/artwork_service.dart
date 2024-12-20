import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/artwork.dart';

class ArtworkService {
  final String baseUrl = "http://127.0.0.1:5000/api/artworks";

  // Fonction pour récupérer toutes les œuvres
  Future<List<Artwork>> fetchArtworks() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body)['data'];

      return data.entries.map((entry) {
        return Artwork.fromJson(entry.value, entry.key);
      }).toList();
    } else {
      throw Exception("Failed to load artworks");
    }
  }

  // Fonction pour récupérer une œuvre par ID
  Future<Artwork> fetchArtworkById(String id) async {
    final String url = "$baseUrl/$id";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body)['data'];
      return Artwork.fromJson(data, id);
    } else if (response.statusCode == 404) {
      throw Exception("Artwork not found");
    } else {
      throw Exception("Failed to load artwork with ID: $id");
    }
  }
}
