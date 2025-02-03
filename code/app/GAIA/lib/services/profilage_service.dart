import 'dart:convert';
import 'package:GAIA/model/artwork.dart';
import 'package:GAIA/services/http_service.dart';
import 'package:GAIA/config/ip_config.dart';

class ProfilageService {
  final HttpService _httpService = HttpService();

  // Fonction pour modifier les marques d'un utilisateur
  Future<String> modifyBrands(String artworkId, String uid) async {
    final response =
        await _httpService.post(IpConfig.profilingProfilage, body: {
      'artworkId': artworkId,
      'uid': uid,
    });

    print("Id TRANSMIS: $artworkId");
    print(response.statusCode);
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
    final response = await _httpService.get(IpConfig.profilingArtworks);

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
