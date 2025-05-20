import 'dart:convert';
import 'package:GAIA/config/ip_config.dart';
import 'package:GAIA/model/artwork.dart';
import '../services/http_service.dart';

class RecommendationService {
  final HttpService _httpService = HttpService();

  Future<List<Artwork>> fetchRecommendations(String uid) async {
    try {
      final response = await _httpService.get(
        IpConfig.recoGet(uid),
      );

      if (response.statusCode == 200) {
        List<dynamic> recommendations = jsonDecode(response.body)['data'];

        print(
            'Fetched recommendations IDs: ${recommendations.map((r) => r['id']).toList()}');

        return recommendations.map((artworkJson) {
          return Artwork.fromJson(artworkJson);
        }).toList();
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
      final response = await _httpService.get(IpConfig.recoMaj(uid));

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
