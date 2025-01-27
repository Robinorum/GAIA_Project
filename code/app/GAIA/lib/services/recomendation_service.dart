import 'dart:convert';
import 'package:http/http.dart' as http;

class RecommendationService {
  final String baseUrl = "http://127.0.0.1:5000/api/recommendations/";

  /// Récupérer les recommandations pour un utilisateur
  Future<List<String>> getRecommendations(String uid) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'uid': uid,
      }),
    );

    if (response.statusCode == 200) {
      // On suppose que le backend renvoie une liste de titres
      List<dynamic> recommendations = jsonDecode(response.body);
      return recommendations.cast<String>();
    } else if (response.statusCode == 400) {
      throw Exception("Missing UID");
    } else {
      throw Exception("Failed to fetch recommendations");
    }
  }
}
