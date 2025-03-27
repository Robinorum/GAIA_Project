class MuseumQuest {
  final String id;
  final String indice;
  final String image;

  MuseumQuest({
    required this.id,
    required this.indice,
    required this.image,
  });
 /// Crée un objet MuseumQuest à partir d'un JSON
  factory MuseumQuest.fromJson(Map<String, dynamic> json) {
    return MuseumQuest(
      id: json['id'],
      indice: json['indice'],
      image: json['image'],
    );
  }
}
