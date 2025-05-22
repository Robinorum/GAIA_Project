import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/artwork.dart';
import '../services/user_service.dart';
import '../provider/user_provider.dart';
import 'package:gaia/pages/detail_artwork_page.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  @override
  _CollectionPageState createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  late Future<List<Artwork>> _artworks;
  List<Artwork> _allArtworks = [];
  List<Artwork> _filteredArtworks = [];
  List<String> _selectedMovements = [];
  final TextEditingController _searchController = TextEditingController();

  final List<String> _movements = [
    "Renaissance",
    "Baroque",
    "Rococo",
    "Néoclassicisme",
    "Romantisme",
    "Réalisme",
    "Impressionnisme",
    "Post-impressionnisme",
    "Symbolisme",
    "Art nouveau",
    "Fauvisme",
    "Cubisme",
    "Byzantin",
    "Expressionnisme",
    "Surréalisme",
    "Dadaïsme",
    "Abstraction",
    "Art déco",
    "Pop art",
    "Hyperréalisme"
  ];

  String _sortOrder = 'asc'; // 'asc' ou 'desc'

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final uid = user?.id ?? "default_uid";

    _artworks = UserService().fetchCollection(uid);
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
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
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
                                selected
                                    ? tempSelection.add(movement)
                                    : tempSelection.remove(movement);
                              });
                            },
                            selectedColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withAlpha((0.2 * 255).toInt()),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 10),
                      const Text(
                        "Trier les œuvres par nom",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
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
                        items: [
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
          Padding(
            padding:
                const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 24),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Rechercher une œuvre...",
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 12),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
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
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
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
                                  builder: (context) =>
                                      DetailArtworkPage(artwork: artwork),
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
          ),
        ],
      ),
    );
  }
}
