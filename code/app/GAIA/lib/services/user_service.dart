import 'dart:convert';
import 'package:GAIA/model/artwork.dart';
import 'package:GAIA/services/http_service.dart';
import 'package:GAIA/config/ip_config.dart';
import 'dart:developer' as developer;


class UserService {
  final HttpService _httpService = HttpService();

  Future<List<Artwork>> fetchCollection(String uid) async {
    try {
      final response = await _httpService.get('${IpConfig.fetchCol}$uid');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['data'];
        return data.map((item) {
          return Artwork.fromJson(item);
        }).toList();
      } else {
        developer.log(
            "Erreur lors de la récupération de la collection: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      developer.log("Exception lors de la récupération de la collection: $e");
      return [];
    }
  }

  Future<bool> fetchStateBrand(String userId, String artworkId) async {
    try {
      final response =
          await _httpService.get('${IpConfig.stateBrand}$userId/$artworkId');

      if (response.statusCode == 200) {
        // Parsing the response body to get the 'result' field
        var jsonResponse = json.decode(response.body);
        bool result = jsonResponse['result'];
        developer.log("Récupération de l'état de la marque: $result");

        return result;
      } else {
        developer.log(
            "Erreur lors de la récupération de l'état de la marque: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      developer.log("Exception lors de la récupération de l'état de la marque: $e");
      return false;
    }
  }

  Future<bool> addArtworks(String userId, String artworkId) async {
    try {
      final response =
          await _httpService.get('${IpConfig.addArtwork}$userId/$artworkId');

      if (response.statusCode == 200) {
        developer.log("Ajout de l'oeuvre à la collection: ${response.statusCode}");
        return true;
      } else {
        developer.log(
            "Erreur lors de l'ajout de l'oeuvre à la collection: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      developer.log("Exception lors de l'ajout de l'oeuvre à la collection: $e");
      return false;
    }
  }

  Future<bool> majQuest(String userId, String arworkMovement) async {
    try {
      final response =
          await _httpService.get('${IpConfig.majQuest}$userId/$arworkMovement');

      if (response.statusCode == 200) {
        developer.log("Mise à jour des quêtes: ${response.statusCode}");
        return true;
      } else {
        developer.log(
            "Erreur lors de la mise à jour des quêtes: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      developer.log("Exception lors de la mise à jour des quêtes: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getQuests(String userId) async {
    try {
      final response = await _httpService.get('${IpConfig.getQuests}$userId');

      if (response.statusCode == 200) {
        developer.log("Réponse reçue: ${response.body}");
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> data = responseData['quests'] ?? [];
        developer.log("début");

        for (var item in data) {
          developer.log("ID: ${item['id']}, Progression: ${item['progression']}");
          developer.log("\n");
        }
        return data.map<Map<String, dynamic>>((item) {
          return {
            'id': item['id'],
            'progression': item['progression'] ?? 0,
          };
        }).toList();
      } else {
        developer.log(
            "Erreur lors de la récupération des quêtes: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      developer.log("Exception lors de la récupération des quêtes: $e");
      return [];
    }
  }
}
