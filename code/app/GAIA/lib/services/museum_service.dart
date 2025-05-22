import 'dart:convert';
import '../model/museum.dart';
import '../model/artwork.dart';
import 'http_service.dart';
import 'package:gaia/config/ip_config.dart';

class MuseumService {
  Future<List<Museum>> fetchMuseums() async {
    HttpService httpService = HttpService();
    final response = await httpService.get(IpConfig.museumEndpoint);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Museum.fromJson(item)).toList();
    } else {
      throw Exception("Failed to load museums");
    }
  }

  Future<List<Artwork>> fetchArtworksByMuseum(String museumId) async {
    HttpService httpService = HttpService();
    final response = await httpService.get(IpConfig.museumArtworks(museumId));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Artwork.fromJson(item)).toList();
    } else {
      throw Exception("Failed to load artworks for museum $museumId");
    }
  }
}
