import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/ip_config.dart';
import 'http_service.dart';

class PredictionService {
  final HttpService _httpService = HttpService();

  Future<Map<String, dynamic>> predictArtwork(String imagePath) async {
    try {
      var uri = Uri.parse("http://127.0.0.1:5000/scan/predict");
      var request = http.MultipartRequest('POST', uri);
      
      // Add auth token from HttpService
      String? token = await _httpService.getIdToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add image file
      request.files.add(await http.MultipartFile.fromPath('file', imagePath));
      
      // Send request and handle response
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        return responseData; // Retourne directement le dictionnaire JSON
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
