import 'dart:convert';
import 'package:gaia/config/ip_config.dart';
import 'package:gaia/model/artwork.dart';
import '../services/http_service.dart';
import 'dart:developer' as developer;

class RecommendationService {
  final HttpService _httpService = HttpService();

  Future<List<Artwork>> fetchRecommendations(String uid) async {
    try {
      final response = await _httpService.get(
        IpConfig.recoGet(uid),
      );

      if (response.statusCode == 200) {
        List<dynamic> recommendations = jsonDecode(response.body)['data'];
        developer.log('Fetched recommendations IDs: ${recommendations.map((r) => r['id']).toList()}');


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
    final response = await _httpService.put(
      IpConfig.recoMaj(uid),
    );
    
    if (response.statusCode == 200) {
      // Parse the response body
      Map<String, dynamic> responseData = jsonDecode(response.body);
      
      // Check if the update was successful
      if (responseData['success'] == true) {
        // After updating, fetch the new recommendations
        return await fetchRecommendations(uid);
      } else {
        throw Exception("Failed to update recommendations: ${responseData['error']}");
      }
    } else if (response.statusCode == 400) {
      throw Exception("Missing UID");
    } else {
      throw Exception("Failed to update recommendations. Status code: ${response.statusCode}");
    }
  } catch (e) {
    // Make sure to log and properly handle errors
    developer.log('Error updating recommendations: $e');
    throw Exception("Error updating recommendations: $e");
  }
}
}
