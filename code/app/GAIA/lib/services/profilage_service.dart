import '../services/http_service.dart';

class ProfilageService {
  final HttpService _httpService = HttpService();
  final String baseUrl = "http://127.0.0.1:5000/profiling/api/profilage/";

  // Fonction pour modifier les marques d'un utilisateur
  Future<String> modifyBrands(String artworkId, String uid) async {
    final response = await _httpService.post(baseUrl, body: {
      'artworkId': artworkId,
      'uid': uid,
    });

    if (response.statusCode == 200) {
      return "Brands updated successfully";
    } else if (response.statusCode == 400) {
      throw Exception("Missing artworkId or uid");
    } else {
      throw Exception("Failed to update brands");
    }
  }

  // Ajouter d'autres méthodes si nécessaire
}
