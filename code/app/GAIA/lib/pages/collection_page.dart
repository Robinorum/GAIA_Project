import 'package:GAIA/pages/detail_artwork_page.dart';
import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../model/artwork.dart';
import 'package:GAIA/provider/userProvider.dart';
import 'package:provider/provider.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({Key? key}) : super(key: key);

  @override
  _CollectionPageState createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  late Future<List<Artwork>> _artworks;
  List<Artwork> _allArtworks = [];
  List<Artwork> _filteredArtworks = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedMovement = "All";

  // To modify after
  final List<String> _movements = [
    "All",
    "Impressionism",
    "Renaissance",
    "Baroque",
    "Cubism",
    "Surrealism",
    "Modern Art",
  ];

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
        bool matchesSearch = artwork.title.toLowerCase().contains(query) ||
            artwork.artist.toLowerCase().contains(query);

        bool matchesMovement =
            _selectedMovement == "All" || artwork.movement == _selectedMovement;

        return matchesSearch && matchesMovement;
      }).toList();
    });
  }

  void _filterByMovement(String? movement) {
    setState(() {
      _selectedMovement = movement ?? "All";
      _filterArtworks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Collection"),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search an artwork...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              value: _selectedMovement,
              isExpanded: true,
              items: _movements.map((movement) {
                return DropdownMenuItem<String>(
                  value: movement,
                  child: Text(movement),
                );
              }).toList(),
              onChanged: _filterByMovement,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Artwork>>(
              future: _artworks,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error : ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No artworks found."));
                }

                if (_allArtworks.isEmpty) {
                  _allArtworks = snapshot.data!;
                  _filteredArtworks = _allArtworks;
                }

                return _filteredArtworks.isEmpty
                    ? const Center(child: Text("No artworks found."))
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
