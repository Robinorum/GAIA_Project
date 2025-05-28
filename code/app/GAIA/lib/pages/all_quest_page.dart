import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gaia/model/general_quest.dart';
import 'package:gaia/provider/user_provider.dart';
import 'package:gaia/services/general_quest_service.dart';
import 'package:gaia/services/user_service.dart';
import 'dart:developer' as developer;

class AllQuestsPage extends StatefulWidget {
  const AllQuestsPage({super.key});

  @override
  State<AllQuestsPage> createState() => _AllQuestsPageState();
}

class _AllQuestsPageState extends State<AllQuestsPage> {
  final GeneralQuestService _questService = GeneralQuestService();
  final UserService _userService = UserService();

  late Future<void> _combinedFuture;
  List<GeneralQuest> _quests = [];
  List<Map<String, dynamic>> _questProgressData = [];


  @override
  void initState() {
    super.initState();
    _loadQuests();
  }

  void _loadQuests() {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final uid = user?.id ?? "default_uid";

    _combinedFuture = _questService.fetchGeneralQuests().then((quests) async {
      final progress = await _userService.getQuests(uid);
      final progressData = getProgressionAndGoal(quests, progress);

      setState(() {
        _quests = quests;
        _questProgressData = progressData;
      });
    });
  }



  Widget _buildQuestCard(GeneralQuest quest, Map<String, dynamic> progressData) {
    final int progression = progressData['progression'];
    final int goal = progressData['goal'];
    
    // Détermine le niveau d'étoiles
    int level = 0;
    if (progression >= quest.goal[2]) {
      level = 3;
    } else if (progression >= quest.goal[1]) {
      level = 2;
    } else if (progression >= quest.goal[0]) {
      level = 1;
    }

    // Calcul du pourcentage de progression
    double progressPercentage = goal > 0 ? (progression / goal).clamp(0.0, 1.0) : 0.0;
    
    // Couleur basée sur le niveau
    Color cardColor = level == 3 
        ? Colors.amber[50]! 
        : level >= 1 
            ? Colors.green[50]! 
            : Colors.grey[50]!;
    
    Color accentColor = level == 3 
        ? Colors.amber 
        : level >= 1 
            ? Colors.green 
            : Colors.grey;

    // Icône basée sur le type de quête
    IconData questIcon = Icons.assignment;
    if (quest.movement.toLowerCase().contains('visit')) {
      questIcon = Icons.location_on;
    } else if (quest.movement.toLowerCase().contains('discover')) {
      questIcon = Icons.explore;
    } else if (quest.movement.toLowerCase().contains('collect')) {
      questIcon = Icons.collections;
    } else if (quest.movement.toLowerCase().contains('interact')) {
      questIcon = Icons.touch_app;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    questIcon,
                    color: accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        quest.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "$progression/$goal",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        3,
                        (i) => Icon(
                          i < level ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Objectifs par niveau
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Objectifs:",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: quest.goal.asMap().entries.map((entry) {
                          int index = entry.key;
                          int goalValue = entry.value;
                          bool isAchieved = progression >= goalValue;
                          
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isAchieved 
                                  ? Colors.amber.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isAchieved 
                                    ? Colors.amber
                                    : Colors.grey,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isAchieved ? Icons.star : Icons.star_border,
                                  size: 12,
                                  color: isAchieved 
                                      ? Colors.amber 
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  goalValue.toString(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isAchieved 
                                        ? Colors.black87 
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Barre de progression
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Progression",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      "${(progressPercentage * 100).toInt()}%",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressPercentage,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    if (_questProgressData.isEmpty) return const SizedBox();
    
    int totalQuests = _questProgressData.length;
    int completedQuests = _questProgressData.where((data) {
      final quest = _quests.firstWhere((q) => q.id == data['id']);
      return data['progression'] >= quest.goal[0];
    }).length;
    
    int perfectQuests = _questProgressData.where((data) {
      final quest = _quests.firstWhere((q) => q.id == data['id']);
      return data['progression'] >= quest.goal[2];
    }).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple[50]!, Colors.deepPurple[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              "Total",
              totalQuests.toString(),
              Icons.assignment,
              Colors.deepPurple,
            ),
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.deepPurple.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              "Complétées",
              completedQuests.toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.deepPurple.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              "Parfaites",
              perfectQuests.toString(),
              Icons.emoji_events,
              Colors.amber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Toutes les quêtes",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<void>(
              future: _combinedFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(50.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                return Column(
                  children: [
                    _buildStatsHeader(),
                  ],
                );
              },
            ),
            
            Expanded(
              child: FutureBuilder<void>(
                future: _combinedFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final quests = _quests;
                  
                  if (quests.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Aucune quête disponible",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Les quêtes se chargeront bientôt",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: quests.length,
                    itemBuilder: (context, index) {
                      final quest = quests[index];
                      final progressData = _questProgressData.firstWhere(
                        (element) => element['id'] == quest.id,
                        orElse: () => {'progression': 0, 'goal': quest.goal[0]},
                      );

                      return _buildQuestCard(quest, progressData);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Fonction utilitaire réutilisée de la page principale
List<Map<String, dynamic>> getProgressionAndGoal(
  List<GeneralQuest> questList,
  List<Map<String, dynamic>> progressList,
) {
  List<Map<String, dynamic>> result = [];

  for (var progress in progressList) {
    final String questId = progress['id'].toString();
    final int currentProgress = progress['progression'];

    final matchingQuest = questList.firstWhere(
      (quest) => quest.id == questId,
      orElse: () => GeneralQuest(
        id: questId,
        title: '',
        description: '',
        movement: '',
        goal: [0, 0, 0],
      ),
    );

    int goalToReach = matchingQuest.goal.firstWhere(
      (goal) => currentProgress < goal,
      orElse: () => matchingQuest.goal.last,
    );

    result.add({
      'id': questId,
      'progression': currentProgress,
      'goal': goalToReach,
    });
  }

  return result;
}