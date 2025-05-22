import 'dart:convert';
import 'package:gaia/model/app_user.dart';
import 'package:gaia/model/artwork.dart';
import 'package:gaia/services/http_service.dart';
import 'package:gaia/config/ip_config.dart';
import 'dart:developer' as developer;

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
          await _httpService.get(IpConfig.stateBrand(userId, artworkId));

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

  Future<String> toggleLike(
      Artwork artwork, AppUser user, String action) async {
    try {
      final body = {
        'uid': user.id,
        'artwork_id': artwork.id,
        'movement': artwork.movement,
        'previous_profile': user.preferences['movements'],
        'action': action
      };
      final response = await _httpService
          .post(IpConfig.toggleLike(user.id, artwork.id), body: body);

      if (response.statusCode == 200) {
        return "Ok";
      } else {
        return "Nok";
      }
    } catch (e) {
      return "$e";
    }
  }

  Future<bool> addArtworks(String userId, String artworkId) async {
    try {
      final response = await _httpService.post(
          IpConfig.addArtwork(userId, artworkId),
          body: {"message": "Added to collection"});

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

  Future<bool> majQuest(String userId, String artworkMovement) async {
    try {
      final url = IpConfig.majQuest(userId);
      final response = await _httpService.put(
        url,
        body: {'movement': artworkMovement},
      );

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
      final response = await _httpService.get(IpConfig.getQuests(userId));

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
  Future<String> initQuestMuseum(String userId, String museumId) async 
  {
    try {
      final body = {
        'museum_id': museumId
      };
      final response = await _httpService.post(
        IpConfig.museumQuest(userId),
        body: body,
      );
      if (response.statusCode == 200) {
        developer.log("Réponse reçue: ${response.body}");
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          final String data = responseData['image_url'] ?? [];
          return data;
        } 
        else if (response.statusCode == 204){
          return "NO_QUEST";
        }  
        else {
        throw Exception("Échec de mise à jour du profil: ${response.body}");
      }
       
    }
    catch (e) {
      return "Erreur lors de l'initialisation de la quête: $e";
    }
  }
  Future<bool> majQuestMuseum(String userId, String museumId, String artworkId) async 
  {

    return false;
  }

}
