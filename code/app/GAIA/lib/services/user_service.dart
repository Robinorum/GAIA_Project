import 'dart:convert';
import 'package:GAIA/model/artwork.dart';
import 'package:GAIA/services/http_service.dart';
import 'package:GAIA/config/ip_config.dart';

class UserService {
  final HttpService _httpService = HttpService();

  Future<List<Artwork>> fetchCollection(String uid) async {
    try {
      final response = await _httpService.get(IpConfig.fetchCol(uid));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['data'];
        return data.map((item) {
          return Artwork.fromJson(item);
        }).toList();
      } else {
        print(
            "Erreur lors de la récupération de la collection: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Exception lors de la récupération de la collection: $e");
      return [];
    }
  }

  Future<bool> fetchStateBrand(String userId, String artworkId) async {
    try {
      final response =
          await _httpService.get(IpConfig.stateBrand(userId, artworkId));

      if (response.statusCode == 200) {
        // Parsing the response body to get the 'result' field
        var jsonResponse = json.decode(response.body);
        bool result = jsonResponse['result'];
        print("Récupération de l'état de la marque: $result");

        return result;
      } else {
        print(
            "Erreur lors de la récupération de l'état de la marque: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Exception lors de la récupération de l'état de la marque: $e");
      return false;
    }
  }

  Future<bool> addArtworks(String userId, String artworkId) async {
    try {
      final response = await _httpService.post(
          IpConfig.addArtwork(userId, artworkId),
          body: {"message": "Added to collection"});

      if (response.statusCode == 200) {
        print("Ajout de l'oeuvre à la collection: ${response.statusCode}");
        return true;
      } else {
        print(
            "Erreur lors de l'ajout de l'oeuvre à la collection: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Exception lors de l'ajout de l'oeuvre à la collection: $e");
      return false;
    }
  }

  Future<bool> majQuest(String userId, String artworkMovement) async {
    try {
      final url = IpConfig.majQuest(userId);
      final response = await _httpService.put(
        url,
        body: {'movement': artworkMovement},
      );

      if (response.statusCode == 200) {
        print("Mise à jour des quêtes: ${response.statusCode}");
        return true;
      } else {
        print(
            "Erreur lors de la mise à jour des quêtes: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Exception lors de la mise à jour des quêtes: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getQuests(String userId) async {
    try {
      final response = await _httpService.get(IpConfig.getQuests(userId));

      if (response.statusCode == 200) {
        print("Réponse reçue: ${response.body}");
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> data = responseData['quests'] ?? [];
        print("début");

        for (var item in data) {
          print("ID: ${item['id']}, Progression: ${item['progression']}");
          print("\n");
        }
        return data.map<Map<String, dynamic>>((item) {
          return {
            'id': item['id'],
            'progression': item['progression'] ?? 0,
          };
        }).toList();
      } else {
        print(
            "Erreur lors de la récupération des quêtes: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Exception lors de la récupération des quêtes: $e");
      return [];
    }
  }
}
