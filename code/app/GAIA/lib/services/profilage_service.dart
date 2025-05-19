import 'dart:convert';
import 'package:GAIA/model/appUser.dart';
import 'package:GAIA/model/artwork.dart';
import 'package:GAIA/services/http_service.dart';
import 'package:GAIA/config/ip_config.dart';

class ProfilageService {
  final HttpService _httpService = HttpService();

  Future<String> modifyBrands(Artwork artwork, AppUser user, String action) async {
    final body = {
      'uid': user.id,
      'artwork_id': artwork.id,
      'movement': artwork.movement,
      'previous_profile': user.preferences['movements'],
      'action' : action
    };

    final response = await _httpService.post(
      IpConfig.profilingProfilage,
      body: body,
    );

    if (response.statusCode == 200) {
      return "Profil mis à jour avec succès";
    } else {
      throw Exception("Échec de mise à jour du profil: ${response.body}");
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

  Future<List<String>> fetchTopMovements(String uid) async {
    try {
      final response = await _httpService.get('${IpConfig.topBrands}$uid');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Assurer que 'top_movements' est bien une liste de strings
        if (data['top_movements'] != null && data['top_movements'] is List) {
          return List<String>.from(data['top_movements']);
        } else {
          throw Exception("Invalid data format: top_movements is not a list");
        }
      } else if (response.statusCode == 404) {
        throw Exception(
            "User document not found or no movements data available.");
      } else {
        throw Exception(
            "Failed to fetch top movements: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching top movements: $e");
    }
  }

  // Ajouter d'autres méthodes si nécessaire
}