import 'dart:convert';
import 'package:http/http.dart' as http;
import 'http_service.dart';

class PredictionService {
  final HttpService _httpService = HttpService();

  Future<Map<String, dynamic>> predictArtwork(String imagePath) async {
    try {
      var uri = Uri.parse("http://127.0.0.1:5000/scan/predict");
      var request = http.MultipartRequest('POST', uri);
      
      
      String? token = await _httpService.getIdToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      
      request.files.add(await http.MultipartFile.fromPath('file', imagePath));
      
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body); //on envoie ici les données a la page de scan
        return responseData; 
      } else if (response.statusCode == 400) {
        throw Exception("Bad request");
      } else {
        throw Exception("Failed to predict artwork: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception('Error during prediction: $e');
    }
  }
}
