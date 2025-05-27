import 'dart:convert';
import '../model/artwork.dart';
import '../model/museum.dart';
import 'http_service.dart';
import 'museum_service.dart';
import '../config/ip_config.dart';
import 'dart:developer' as developer;

class ArtworkService {
  final HttpService _httpService = HttpService();
  final MuseumService _museumService = MuseumService();


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


  Future<List<Artwork>> fetchArtworks() async {
    try {
      developer.log('Fetching artworks from: ${IpConfig.profilingArtworks}');
      
      final response = await _httpService.get(
        IpConfig.profilingArtworks,
      );

      developer.log('Response status code: ${response.statusCode}');
      developer.log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['data'];
        return data.map((item) => Artwork.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load artworks: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      developer.log('Error in fetchArtworks: $e');
      rethrow;
    }
  }
  
}
