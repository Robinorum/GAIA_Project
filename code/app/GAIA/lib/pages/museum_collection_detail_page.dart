import 'package:flutter/material.dart';
import 'package:gaia/model/museum_collection.dart';
import 'package:gaia/model/artwork.dart';
import 'package:gaia/services/museum_service.dart';
import 'package:gaia/pages/detail_artwork_page.dart';
import 'dart:ui';

class MuseumCollectionDetailPage extends StatefulWidget {
  final MuseumCollection museum;

  const MuseumCollectionDetailPage({super.key, required this.museum});

  @override
  State<MuseumCollectionDetailPage> createState() => _MuseumCollectionDetailPageState();
}

class _MuseumCollectionDetailPageState extends State<MuseumCollectionDetailPage> {
  late Future<List<Artwork>> _artworksFuture;
  List<Artwork> _allArtworks = [];
  String _filterStatus = 'all'; // 'all', 'completed', 'incomplete'

  @override
  void initState() {
    super.initState();
    _artworksFuture = MuseumService().fetchArtworksByMuseum(widget.museum.officialId);
  }

  List<Artwork> get filteredArtworks {
    switch (_filterStatus) {
      case 'completed':
        return _allArtworks.where((artwork) => _isArtworkCompleted(artwork.id)).toList();
      case 'incomplete':
        return _allArtworks.where((artwork) => !_isArtworkCompleted(artwork.id)).toList();
      default:
        return _allArtworks;
    }
  }

  bool _isArtworkCompleted(String artworkId) {
    return widget.museum.artworks.any((item) => item.id == artworkId && item.completed);
  }

  Widget _buildArtworkCard(Artwork artwork, bool isCompleted) {
    return InkWell(
      onTap: isCompleted ? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailArtworkPage(artwork: artwork),
          ),
        );
      } : null,
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      artwork.toImage(),
                      if (!isCompleted) ...[
                        // Effet de flou et grisé pour les œuvres non complétées
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                          child: Container(
                            color: Colors.grey.withOpacity(0.6),
                          ),
                        ),
                        // Icône de verrouillage
                        const Center(
                          child: Icon(
                            Icons.lock,
                            size: 40,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
            ],
          ),
          // Badge de statut
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCompleted ? Icons.check : Icons.lock,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image du musée
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(widget.museum.image),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Titre du musée
              Text(
                widget.museum.title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              // Localisation
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      "${widget.museum.place}, ${widget.museum.department}",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // ID officiel
             
              const SizedBox(height: 16),
              
              // Histoire du musée
              if (widget.museum.histoire.isNotEmpty) ...[
                const Text(
                  "Histoire",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    widget.museum.histoire,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                    textAlign: TextAlign.justify,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Statistiques de progression
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Progression de votre collection",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${widget.museum.completedArtworksCount}/${widget.museum.totalArtworksCount} œuvres complétées",
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${widget.museum.completionPercentage.toStringAsFixed(0)}%",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: widget.museum.completionPercentage / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                      minHeight: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Filtre et titre des œuvres
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Collection d'œuvres",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _filterStatus,
                      underline: const SizedBox(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _filterStatus = newValue;
                          });
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('Toutes'),
                        ),
                        DropdownMenuItem(
                          value: 'completed',
                          child: Text('Complétées'),
                        ),
                        DropdownMenuItem(
                          value: 'incomplete',
                          child: Text('À découvrir'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
                      
              // Grille des œuvres
              FutureBuilder<List<Artwork>>(
                future: _artworksFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    debugPrint("Error loading artworks: ${snapshot.error}");
                    return const Center(
                      child: Text("Aucune œuvre disponible pour ce musée."),
                    );
                  }

                  _allArtworks = snapshot.data!;
                  final displayedArtworks = filteredArtworks;

                  if (displayedArtworks.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Aucune œuvre trouvée pour ce filtre",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: displayedArtworks.length,
                    itemBuilder: (context, index) {
                      final artwork = displayedArtworks[index];
                      final isCompleted = _isArtworkCompleted(artwork.id);

                      return _buildArtworkCard(artwork, isCompleted);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}