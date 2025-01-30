import 'dart:convert';
import 'package:GAIA/model/artwork.dart';
import 'package:GAIA/services/http_service.dart';
import 'package:GAIA/config/ip_config.dart';

class UserService {

  final HttpService _httpService = HttpService();

    Future<List<Artwork>> fetchCollection(String uid) async {
      try {
      final response = await _httpService.get('${IpConfig.fetchCol}$uid');

      if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body)['data'];
          return data.map((item) {
            return Artwork.fromJson(item);
          }).toList();
      } else {
        print("Erreur lors de la récupération de la collection: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Exception lors de la récupération de la collection: $e");
      return [];
    }
  }

}
