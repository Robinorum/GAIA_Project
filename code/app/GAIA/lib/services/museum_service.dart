import 'dart:convert';
import '../model/museum.dart';
import 'http_service.dart';
import 'package:GAIA/config/ip_config.dart';

class MuseumService {
  Future<List<Museum>> fetchMuseums() async {
    HttpService httpService = HttpService();
    final response = await httpService.get(IpConfig.museumEndpoint);

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
