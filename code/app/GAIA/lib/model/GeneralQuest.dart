class GeneralQuest {
  final String id;
  final String title;
  final String description;
  final String movement; // Changement pour correspondre aux mouvements
  final List<int> goal; // Goal devient une liste d'entiers

  GeneralQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.movement,
    required this.goal,
  });


  /// Créer une instance depuis un JSON
  factory GeneralQuest.fromJson(Map<String, dynamic> json) {
    return GeneralQuest(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      movement: json['movement'], // Utiliser "movement" au lieu de "mouvement"
      goal: List<int>.from(json['goal'] ?? []), // Assurer que goal est une liste d'entiers

    );
  }

}
