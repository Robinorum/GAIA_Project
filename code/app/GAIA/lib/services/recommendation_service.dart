import 'dart:convert';
import 'package:GAIA/model/artwork.dart';
import '../services/http_service.dart';

class RecommendationService {
  final String baseUrl = "http://127.0.0.1:5000/reco/api";
  final HttpService _httpService = HttpService();

  Future<List<Artwork>> fetchRecommendations(String uid) async {
    try {
      final response = await _httpService.get(
        '$baseUrl/recom_get/$uid',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        List<dynamic> recommendations = jsonResponse['data'];

        return recommendations
            .map((artworkJson) => Artwork.fromJson(artworkJson))
            .toList();
      } else if (response.statusCode == 400) {
        throw Exception("Missing UID");
      } else {
        throw Exception("Failed to fetch recommendations");
      }
    } catch (e) {
      throw Exception("Error fetching recommendations: $e");
    }
  }

  Future<List<Artwork>> majRecommendations(String uid) async {
    try {
      final response = await _httpService.get('$baseUrl/recom_maj/$uid');

      if (response.statusCode == 200) {
        throw Exception("Recommendations updated successfully");
      } else if (response.statusCode == 400) {
        throw Exception("Missing UID");
      } else {
        throw Exception("Failed to fetch recommendations");
      }
    } catch (e) {
      throw Exception("Error fetching recommendations: $e");
    }
  }
}
