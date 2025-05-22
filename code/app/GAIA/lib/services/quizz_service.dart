import 'dart:convert';
import 'http_service.dart';
import 'package:gaia/config/ip_config.dart';
import "../model/quizz.dart";
import "../model/artwork.dart";
import 'dart:developer' as developer;

class QuizzService {

  HttpService httpService = HttpService();

  
  Future<Quizz> fetchQuizz(Artwork artwork) async {

    final body = {
      'title' : artwork.title,
      'artist' : artwork.artist,
      'date' : artwork.date,
      'movement' : artwork.movement,
      'description' : artwork.description,
      'techniques used' : artwork.techniquesUsed
    };
    
    final response = await httpService.post(IpConfig.genQuizz, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      developer.log("Quizz data: $data");
      return Quizz.fromJson(data);
    } else {
      throw Exception("Failed to load quizz");
    }
  }


}
