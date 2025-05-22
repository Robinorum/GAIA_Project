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

  Future<List<Museum>> fetchMuseumsInBounds({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
    String? searchQuery,
  }) async {
    final HttpService httpService = HttpService();

    final queryParameters = {
      'sw_lat': swLat.toString(),
      'sw_lng': swLng.toString(),
      'ne_lat': neLat.toString(),
      'ne_lng': neLng.toString(),
    };

    if (searchQuery != null && searchQuery.isNotEmpty) {
      queryParameters['search'] = searchQuery;
    }

    final uri = Uri.parse(IpConfig.museumInBoundsEndpoint)
        .replace(queryParameters: queryParameters);

    final response = await httpService.get(uri.toString());

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Museum.fromJson(item)).toList();
    } else {
      throw Exception(
          "Failed to load museums in bounds: ${response.statusCode}");
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
