import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfilageService {
  final String baseUrl=  "http://127.0.0.1:5000/api/profilage";

  ProfilageService();

  /// Aime une œuvre d'art pour un utilisateur donné
  Future<void> likeArtwork(String userId, String artworkId) async {
    final url = Uri.parse('$baseUrl/user/$userId/like');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'artwork_id': artworkId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to like artwork: ${response.body}');
    }
  }

  /// Récupère les scores des mouvements artistiques pour un utilisateur donné
  Future<Map<String, double>> getMovementScores(String userId) async {
    final url = Uri.parse('$baseUrl/user/$userId/movements');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch movements: ${response.body}');
    }

    return Map<String, double>.from(jsonDecode(response.body));
  }
}
