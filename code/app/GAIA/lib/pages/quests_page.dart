import 'dart:ui';
import 'package:gaia/model/general_quest.dart';
import 'package:gaia/model/museum.dart';
import 'package:gaia/pages/all_quest_page.dart';
import 'package:gaia/pages/museum_quest_page.dart';
import 'package:gaia/provider/user_provider.dart';
import 'package:gaia/services/general_quest_service.dart';
import 'package:gaia/services/museum_service.dart';
import 'package:gaia/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;

class QuestsPage extends StatefulWidget {
  const QuestsPage({super.key});

  @override
  State<QuestsPage> createState() => _QuestsPageState();
}

class _QuestsPageState extends State<QuestsPage> {
  final GeneralQuestService _questService = GeneralQuestService();
  final UserService _userService = UserService();

  late Future<void> _combinedFuture;
  List<GeneralQuest> _quests = [];
  List<Map<String, dynamic>> _questProgressData = [];
  LatLng? _currentLocation;
  late Future<List<Museum>> _recommendedMuseums;
  

  Museum? _currentMuseum;
  bool _isInMuseum = false;
  String? _currentQuestImageUrl;
  bool _isLoadingQuest = false;



  @override
  void initState() {
    super.initState();
    _loadRecommendations();
    _getUserLocation();
    _checkCurrentMuseum();
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

  Future<void> _checkCurrentMuseum() async {
    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      final uid = user?.id ?? "default_uid";
      
      // Récupérer le musée actuel depuis la BDD
      final currentMuseumId = await _userService.getCurrentMuseum(uid);
      
      if (currentMuseumId != null) {
        // Récupérer les détails du musée
        final museums = await MuseumService().fetchMuseums();
        final museum = museums.firstWhere(
          (m) => m.officialId == currentMuseumId,
          orElse: () => throw Exception("Musée non trouvé"),
        );
        
        setState(() {
          _currentMuseum = museum;
          _isInMuseum = true;
        });
        
        await _loadCurrentQuest();
      }
    } catch (e) {
      developer.log("Erreur lors de la vérification du musée actuel: $e");
    }
  }

  Future<void> _loadCurrentQuest() async {
    if (!_isInMuseum || _currentMuseum == null) return;
    
    setState(() {
      _isLoadingQuest = true;
    });

    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      final uid = user?.id ?? "default_uid";

      final imageUrl = await _userService.initQuestMuseum(
        uid,
        _currentMuseum!.officialId,
      );

      if (!mounted) return;

      if (imageUrl == "QUEST_ALREADY_COMPLETED") {
        // Marquer la quête comme complétée et charger la suivante
        await _loadCurrentQuest(); // Récursif pour charger la suivante
      } else if (imageUrl == "NO_QUEST") {
        setState(() {
          _currentQuestImageUrl = null;
          _isLoadingQuest = false;
        });
      } else if (!imageUrl.startsWith("Erreur")) {
        setState(() {
          _currentQuestImageUrl = imageUrl;
          _isLoadingQuest = false;
        });
      } else {
        setState(() {
          _currentQuestImageUrl = null;
          _isLoadingQuest = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentQuestImageUrl = null;
        _isLoadingQuest = false;
      });
    }
  }

  Future<void> _enterMuseum(Museum museum) async {
    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      final uid = user?.id ?? "default_uid";
      
      // Mettre à jour la BDD avec le musée actuel
      await _userService.setCurrentMuseum(uid, museum.officialId);
      
      setState(() {
        _currentMuseum = museum;
        _isInMuseum = true;
      });
      
      await _loadCurrentQuest();
    } catch (e) {
      developer.log("Erreur lors de l'entrée dans le musée: $e");
    }
  }

  Future<void> _exitMuseum() async {
    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      final uid = user?.id ?? "default_uid";
      
      // Remettre à null dans la BDD
      await _userService.setCurrentMuseum(uid, null);
      
      setState(() {
        _currentMuseum = null;
        _isInMuseum = false;
        _currentQuestImageUrl = null;
      });
    } catch (e) {
      developer.log("Erreur lors de la sortie du musée: $e");
    }
  }

  void _checkDistanceFromMuseum() {
    if (!_isInMuseum || _currentMuseum == null || _currentLocation == null) return;
    
    final museumLocation = LatLng(
      _currentMuseum!.location.latitude, 
      _currentMuseum!.location.longitude
    );
    
    final distance = _calculateDistance(_currentLocation!, museumLocation);
    
    // Si l'utilisateur s'éloigne trop (plus de 2km), sortir automatiquement
    if (distance > 2000) {
      _exitMuseum();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vous vous êtes éloigné du musée. Quête interrompue."),
        ),
      );
    }
  }

  void _loadRecommendations() {
    setState(() {
      _recommendedMuseums = MuseumService().fetchMuseums().then((museums) {
        return museums;
      });
    });
  }

  Future<void> _getUserLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      _sortAndUpdateMuseums();
      _checkDistanceFromMuseum(); // Vérifier la distance si dans un musée
    } catch (e) {
      developer.log("Error getting location: $e");
    }
  }

  void _sortAndUpdateMuseums() {
    if (_currentLocation == null) return;

    _recommendedMuseums.then((museums) {
      final nearbyMuseums = museums.where((museum) {
        final museumLocation =
            LatLng(museum.location.latitude, museum.location.longitude);
        final distance = _calculateDistance(_currentLocation!, museumLocation);
        return distance <= 2000;
      }).toList();

      final sortedMuseums = _sortMuseumsByDistance(nearbyMuseums);
      final topMuseums = sortedMuseums.take(1).toList();

      setState(() {
        _recommendedMuseums = Future.value(topMuseums);
      });
    });
  }

  List<Museum> _sortMuseumsByDistance(List<Museum> museums) {
    if (_currentLocation == null) return museums;

    museums.sort((a, b) {
      double distanceA = _calculateDistance(
        _currentLocation!,
        LatLng(a.location.latitude, a.location.longitude),
      );
      double distanceB = _calculateDistance(
        _currentLocation!,
        LatLng(b.location.latitude, b.location.longitude),
      );
      return distanceA.compareTo(distanceB);
    });

    return museums;
  }

  double _calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  Widget _buildSuccessCard(GeneralQuest quest, Map<String, dynamic> progressData) {
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    level == 3 ? Icons.emoji_events : level >= 1 ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: accentColor,
                    size: 20,
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
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        quest.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
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
                        color: accentColor,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        3,
                        (i) => Icon(
                          i < level ? Icons.star : Icons.star_border,
                          color: Colors.amber.shade600,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Barre de progression
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressPercentage,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMuseumQuestSection() {
    if (_isInMuseum && _currentMuseum != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Quête du musée",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: _exitMuseum,
                icon: Image.asset(
                  'assets/icons/exit.png',
                  width: 24,
                  height: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.museum,
                        color: Colors.deepPurple.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _currentMuseum!.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.deepPurple[800],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isLoadingQuest)
                  Center(
                    child: CircularProgressIndicator(
                      color: Colors.deepPurple,
                    ),
                  )
                else if (_currentQuestImageUrl != null)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MuseumQuestPage(
                            museum: _currentMuseum!,
                          ),
                        ),
                      ).then((_) {
                        // Recharger la quête au retour
                        _loadCurrentQuest();
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurple.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                // Image principale agrandie
                                Image.network(
                                  _currentQuestImageUrl!,
                                  fit: BoxFit.cover,
                                  height: 180,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 180,
                                      width: double.infinity,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Icon(
                                          Icons.image_not_supported,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                // Effet de flou
                                BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                                  child: Container(
                                    height: 180,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.deepPurple.withOpacity(0.4),
                                          Colors.deepPurple.withOpacity(0.2),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Appuyez pour voir les détails de la quête",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.deepPurple.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade400,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Félicitations !",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade400,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Vous avez terminé toutes les quêtes du musée",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green.shade400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Quête du musée",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Museum>>(
            future: _recommendedMuseums,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              final museums = snapshot.data ?? [];

              if (museums.isNotEmpty) {
                final museum = museums.first;

                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Entrer dans le musée"),
                        content: Text(
                            "Souhaitez-vous entrer dans le musée ${museum.title} et commencer les quêtes ?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text("Annuler"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _enterMuseum(museum);
                            },
                            child: const Text("Entrer"),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.museum,
                            color: Colors.green,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Musée détecté à proximité",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.green[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Cliquez pour entrer dans ${museum.title}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.green.shade600,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha((0.1 * 255).toInt()),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const Positioned.fill(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock, size: 36, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              "Quête exclusive",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Veuillez vous rapprocher d'un musée\npour débloquer les quêtes",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Succès",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<void>(
                future: _combinedFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return ListView.builder(
                    itemCount: _quests.length < 2 ? _quests.length : 2,
                    itemBuilder: (context, index) {
                      final quest = _quests[index];

                      final progressData = _questProgressData.firstWhere(
                        (element) => element['id'] == quest.id,
                        orElse: () => {'progression': 0, 'goal': quest.goal[0]},
                      );

                      return _buildSuccessCard(quest, progressData);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AllQuestsPage()),
                  );
                },
                icon: const Icon(Icons.list),
                label: const Text("Tout voir"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildMuseumQuestSection(),
          ],
        ),
      ),
    );
  }
}

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