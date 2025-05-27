import 'package:flutter/material.dart';
import 'package:gaia/model/museum_collection.dart';
import 'package:provider/provider.dart';
import '../model/artwork.dart';
import '../services/user_service.dart';
import '../provider/user_provider.dart';
import 'package:gaia/pages/detail_artwork_page.dart';
import 'package:gaia/pages/museum_collection_detail_page.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  @override
  CollectionPageState createState() => CollectionPageState();
}

class CollectionPageState extends State<CollectionPage> {
  late Future<List<Artwork>> _artworks;
  List<Artwork> _allArtworks = [];
  List<Artwork> _filteredArtworks = [];
  List<String> _selectedMovements = [];
  final TextEditingController _searchController = TextEditingController();

  final List<String> _movements = [
    "Renaissance", "Baroque", "Rococo", "Néoclassicisme", "Romantisme",
    "Réalisme", "Impressionnisme", "Post-impressionnisme", "Symbolisme",
    "Art nouveau", "Fauvisme", "Cubisme", "Byzantin", "Expressionnisme",
    "Surréalisme", "Dadaïsme", "Abstraction", "Art déco", "Pop art", "Hyperréalisme"
  ];

  String _sortOrder = 'asc';
  String _viewMode = 'artwork'; // 'artwork' ou 'museum'

  // Données des musées (vous pouvez les déplacer dans un service plus tard)

  late Future<Map<String, dynamic>?> _museumsDataFuture;


  List<MuseumCollection> _getMuseums(Map<String, dynamic> museumsData) {
    return museumsData.entries
        .map((entry) => MuseumCollection.fromJson(entry.key, entry.value))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final uid = user?.id ?? "default_uid";
    _artworks = UserService().fetchCollection(uid);
    _museumsDataFuture = UserService().fetchMuseumCollection(uid);
    _searchController.addListener(_filterArtworks);
  }

  void _filterArtworks() {
    String query = _searchController.text.toLowerCase();

    setState(() {
      _filteredArtworks = _allArtworks.where((artwork) {
        final matchesSearch = artwork.title.toLowerCase().contains(query) ||
            artwork.artist.toLowerCase().contains(query);
        final matchesMovement = _selectedMovements.isEmpty ||
            _selectedMovements.contains(artwork.movement);
        return matchesSearch && matchesMovement;
      }).toList();

      _sortArtworks();
    });
  }

  void _sortArtworks() {
    _filteredArtworks.sort((a, b) {
      int comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      return _sortOrder == 'asc' ? comparison : -comparison;
    });
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        List<String> tempSelection = List.from(_selectedMovements);
        String tempSortOrder = _sortOrder;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    controller: controller,
                    children: [
                      const Text(
                        "Filtrer par mouvements",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _movements.map((movement) {
                          final isSelected = tempSelection.contains(movement);
                          return FilterChip(
                            label: Text(movement),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              setModalState(() {
                                selected ? tempSelection.add(movement) : tempSelection.remove(movement);
                              });
                            },
                            selectedColor: Theme.of(context).colorScheme.primary.withAlpha((0.2 * 255).toInt()),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 10),
                      const Text(
                        "Trier les œuvres par nom",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      DropdownButton<String>(
                        value: tempSortOrder,
                        isExpanded: true,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setModalState(() => tempSortOrder = newValue);
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: 'asc',
                            child: Text('Ordre alphabétique (A → Z)'),
                          ),
                          DropdownMenuItem(
                            value: 'desc',
                            child: Text('Ordre alphabétique inverse (Z → A)'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedMovements.clear();
                                _sortOrder = 'asc';
                                _filterArtworks();
                              });
                              Navigator.pop(context);
                            },
                            child: const Text("Réinitialiser"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedMovements = tempSelection;
                                _sortOrder = tempSortOrder;
                                _filterArtworks();
                              });
                              Navigator.pop(context);
                            },
                            child: const Text("Appliquer"),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ToggleButtons(
              borderRadius: BorderRadius.circular(12),
              isSelected: [_viewMode == 'artwork', _viewMode == 'museum'],
              onPressed: (int index) {
                setState(() {
                  _viewMode = index == 0 ? 'artwork' : 'museum';
                });
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Vos œuvres"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Musées visités"),
                ),
              ],
            ),
          ),
          if (_viewMode == 'artwork') ...[
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 24),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Rechercher une œuvre...",
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showFilterSheet(context),
                    icon: const Icon(Icons.tune, size: 20),
                    label: Text(
                      _selectedMovements.isEmpty
                          ? "Filtres"
                          : "Filtres (${_selectedMovements.length})",
                      style: const TextStyle(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Artwork>>(
                future: _artworks,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Erreur : ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("Aucune œuvre trouvée."));
                  }

                  if (_allArtworks.isEmpty) {
                    _allArtworks = snapshot.data!;
                    _filteredArtworks = _allArtworks;
                    _sortArtworks();
                  }

                  return _filteredArtworks.isEmpty
                      ? const Center(child: Text("Aucune œuvre trouvée."))
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                          ),
                          itemCount: _filteredArtworks.length,
                          itemBuilder: (context, index) {
                            final artwork = _filteredArtworks[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailArtworkPage(artwork: artwork),
                                  ),
                                );
                              },
                              child: GridTile(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: artwork.toImage(),
                                ),
                              ),
                            );
                          },
                        );
                },
              ),
            )
          ] else ...[
            // Vue des musées
            Expanded(
              child: FutureBuilder<Map<String, dynamic>?>(
                future: _museumsDataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Erreur : ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data == null) {
                    return const Center(child: Text("Aucune donnée musée trouvée."));
                  }
                  final museums = _getMuseums(snapshot.data!);
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: museums.length,
                    itemBuilder: (context, index) {
                      final museum = museums[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MuseumCollectionDetailPage(museum: museum),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image du musée
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: Container(
                                  height: 200,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: NetworkImage(museum.image),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              
                              // Informations du musée
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      museum.title,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                   
                                    const SizedBox(height: 12),
                                    
                                    // Barre de progression
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${museum.completedArtworksCount}/${museum.totalArtworksCount} œuvres complétées',
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                              const SizedBox(height: 4),
                                              LinearProgressIndicator(
                                                value: museum.completionPercentage / 100,
                                                backgroundColor: Colors.grey[300],
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  Theme.of(context).colorScheme.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '${museum.completionPercentage.toStringAsFixed(0)}%',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
          ],
      ),
    );
    
  }
}