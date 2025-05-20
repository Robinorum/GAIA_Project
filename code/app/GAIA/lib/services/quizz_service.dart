import 'dart:convert';
import 'http_service.dart';
import 'package:GAIA/config/ip_config.dart';
import "../model/quizz.dart";

class QuizzService {

  
  Future<Quizz> fetchQuizz(String idArtwork) async {
    HttpService httpService = HttpService();
    final response = await httpService.get(IpConfig.genQuizz(idArtwork));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("Quizz data: $data");
      return Quizz.fromJson(data);
    } else {
      throw Exception("Failed to load quizz");
    }
  }


}
