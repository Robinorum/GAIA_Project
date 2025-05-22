import 'dart:convert';
import 'package:GAIA/model/general_quest.dart';
import 'package:GAIA/services/http_service.dart';
import 'package:GAIA/config/ip_config.dart';
class GeneralQuestService {
  final HttpService _httpService = HttpService();

Future<List<GeneralQuest>> fetchGeneralQuests() async {
  final response = await _httpService.get(IpConfig.generalQuests);

  if (response.statusCode == 200) {
    final Map<String, dynamic> responseData = jsonDecode(response.body);
    final List<dynamic> data = responseData['data'] ?? [];
    return data.map((item) => GeneralQuest.fromJson(item)).toList();
  } else {
    throw Exception("Failed to load quests: ${response.statusCode}");
  }
}

}
