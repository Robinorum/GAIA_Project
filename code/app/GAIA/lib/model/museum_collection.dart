class MuseumCollection {
  final String title;
  final String image;
  final String officialId;
  final String department;
  final String place;
  final String histoire;
  final List<ArtworkItem> artworks;

  MuseumCollection({
    required this.title,
    required this.image,
    required this.officialId,
    required this.department,
    required this.place,
    required this.histoire,
    required this.artworks,
  });

  factory MuseumCollection.fromJson(String key, Map<String, dynamic> json) {
    return MuseumCollection(
      title: json['title'] ?? '',
      image: json['image'] ?? '',
      officialId: json['official_id'] ?? key,
      department: json['department'] ?? '',
      place: json['place'] ?? '',
      histoire: json['histoire'] ?? '',
      artworks: (json['artworks'] as List<dynamic>? ?? [])
          .map((item) => ArtworkItem.fromJson(item))
          .toList(),
    );
  }

  int get totalArtworksCount => artworks.length;

  int get completedArtworksCount => 
      artworks.where((artwork) => artwork.completed).length;

  double get completionPercentage {
    if (totalArtworksCount == 0) return 0.0;
    return (completedArtworksCount / totalArtworksCount) * 100;
  }
}

class ArtworkItem {
  final String id;
  final bool completed;

  ArtworkItem({
    required this.id,
    required this.completed,
  });

  factory ArtworkItem.fromJson(Map<String, dynamic> json) {
    return ArtworkItem(
      id: json['id']?.toString() ?? '',
      completed: json['completed'] ?? false,
    );
  }
}