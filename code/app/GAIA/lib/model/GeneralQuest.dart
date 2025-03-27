class GeneralQuest {
  final String id;
  final String title;
  final String description;
  final String movement; // Changement pour correspondre aux mouvements
  final List<int> goal; // Goal devient une liste d'entiers
  final Map<String, int> progression; // Progress devient une map avec id utilisateur et sa progression

  GeneralQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.movement,
    required this.goal,
    Map<String, int>? progression, // Accepter progress comme optionnel
  }) : progression = progression ?? {}; // Initialiser progress à une map vide par défaut

  int getGoalProgress(String userId) {
    // Si l'utilisateur a une progression, vérifie laquelle
    if (progression.containsKey(userId)) {
      int userProgress = progression[userId]!;
      for (int i = 0; i < goal.length; i++) {
        if (userProgress >= goal[i]) {
          return i + 1;  // Retourne 1, 2, 3 si l'objectif est atteint
        }
      }
    }
    return 0;  // Retourne 0 si aucun objectif n'est atteint
  }

  /// Convertir en JSON pour stockage ou transmission
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'movement': movement,
      'goal': goal,
      'progression': progression, // La map sera convertie en JSON directement
    };
  }

  /// Créer une instance depuis un JSON
  factory GeneralQuest.fromJson(Map<String, dynamic> json) {
    return GeneralQuest(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      movement: json['movement'], // Utiliser "movement" au lieu de "mouvement"
      goal: List<int>.from(json['goal'] ?? []), // Assurer que goal est une liste d'entiers
      progression: (json['progression'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, value as int)) ??
          {}, // Conversion de la map JSON en Map<String, int>
    );
  }

  /// Créer une copie avec des valeurs mises à jour
  GeneralQuest copyWith({
    String? id,
    String? title,
    String? description,
    String? movement,
    List<int>? goal,
    Map<String, int>? progression,
  }) {
    return GeneralQuest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      movement: movement ?? this.movement,
      goal: goal ?? this.goal,
      progression: progression ?? this.progression,
    );
  }
}
