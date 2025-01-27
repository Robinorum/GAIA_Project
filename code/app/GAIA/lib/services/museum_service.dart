import 'dart:convert';
import '../model/museum.dart';
import 'http_service.dart';

class MuseumService {
  final String baseUrl = "http://127.0.0.1:5000/museum/api/museums";

  Future<List<Museum>> fetchMuseums() async {
    HttpService httpService = HttpService();
    final response = await httpService.get(baseUrl);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body)['data'];
      return data.entries.map((entry) {
        return Museum.fromJson(entry.value, entry.key);
      }).toList();
    } else {
      throw Exception("Failed to load museums");
    }
  }
}
