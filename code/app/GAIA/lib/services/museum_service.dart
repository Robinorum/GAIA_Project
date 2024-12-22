import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/museum.dart';

class MuseumService {
  final String baseUrl = "http://127.0.0.1:5000/api/museum";

  // Fonction pour récupérer toutes les œuvres
  Future<List<Museum>> fetchMuseums() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body)['data'];

      return data.entries.map((entry) {
        return Museum.fromJson(entry.value, entry.key);
      }).toList();
    } else {
      throw Exception("Failed to load artworks");
    }
  }


}
