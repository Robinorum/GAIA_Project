import 'dart:convert';
import 'package:GAIA/model/GeneralQuest.dart';
import 'package:GAIA/services/http_service.dart';
import 'package:GAIA/config/ip_config.dart';
class GeneralQuestService {
  final HttpService _httpService = HttpService();

Future<List<GeneralQuest>> fetchGeneralQuests() async {
  final response = await _httpService.get(IpConfig.generalQuests);

  if (response.statusCode == 200) {
    print('Response body: ${response.body}');
    final Map<String, dynamic> responseData = jsonDecode(response.body);
    print('Decoded JSON: $responseData');
    final List<dynamic> data = responseData['data'] ?? [];
    print('Quest data: $data');
    return data.map((item) => GeneralQuest.fromJson(item)).toList();
  } else {
    throw Exception("Failed to load quests: ${response.statusCode}");
  }
}

  Future<void> updateQuestProgress(String questId, int progress) async {
    final response = await _httpService.post(
      '${IpConfig.updateQuestProgress}$questId',
      body: {'progress': progress},
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update quest progress");
    }
  }
}
