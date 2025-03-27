import 'package:GAIA/model/GeneralQuest.dart';
import 'package:GAIA/services/GeneralQuestService.dart';
import 'package:flutter/material.dart';


class AllQuestsPage extends StatefulWidget {
  const AllQuestsPage({Key? key}) : super(key: key);

  @override
  State<AllQuestsPage> createState() => _AllQuestsPageState();
}

class _AllQuestsPageState extends State<AllQuestsPage> {
  final GeneralQuestService _questService = GeneralQuestService();
  late Future<List<GeneralQuest>> _questsFuture;

  @override
  void initState() {
    super.initState();
    _questsFuture = _questService.fetchGeneralQuests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Toutes les quêtes")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<GeneralQuest>>(
          future: _questsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Erreur: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Aucune quête disponible."));
            }

            final quests = snapshot.data!;
            return ListView.builder(
              itemCount: quests.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    quests[index].title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text(quests[index].description),
                  leading: const Icon(Icons.star, color: Colors.amber),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
