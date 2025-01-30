import 'dart:convert';
import '../model/museum.dart';
import 'http_service.dart';
import 'package:GAIA/config/ip_config.dart';

class MuseumService {
  Future<List<Museum>> fetchMuseums() async {
    HttpService httpService = HttpService();
    final response = await httpService.get("http://127.0.0.1:5000/museum/api/museums");

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) {
        return Museum.fromJson(item);
      }).toList();
    } else {
      throw Exception("Failed to load museums");
    }
  }
}
