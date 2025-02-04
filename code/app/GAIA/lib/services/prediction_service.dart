import 'dart:convert';
import 'package:http/http.dart' as http;
import 'http_service.dart';
import '../config/ip_config.dart';

class PredictionService {
  final HttpService _httpService = HttpService();

  Future<Map<String, dynamic>> predictArtwork(String imagePath) async {
    try {
      var uri = Uri.parse(IpConfig.predictArtwork); // URL de l'API
      var request = http.MultipartRequest('POST', uri);

      // Récupérer le token d'authentification
      String? token = await _httpService.getIdToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Ajouter l'image au format Multipart
      request.files.add(await http.MultipartFile.fromPath('file', imagePath));

      // Envoyer la requête
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Vérifier la réponse
      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Retourner les données JSON
      } else if (response.statusCode == 400) {
        throw Exception("Bad request: L'image envoyée est peut-être invalide.");
      } else {
        throw Exception("Failed to predict artwork: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception('Error during prediction: $e');
    }
  }
}
