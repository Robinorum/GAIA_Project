import 'package:flutter/material.dart';
import 'package:GAIA/model/museum.dart';
import 'package:GAIA/model/artwork.dart';
import 'package:GAIA/services/museum_service.dart';
import 'package:GAIA/pages/detail_artwork_page.dart';
import 'dart:math'; // Ajoute cette importation pour utiliser Random

class DetailMuseumPage extends StatefulWidget {
  final Museum museum;
  final double distance;

  const DetailMuseumPage(
      {super.key, required this.museum, required this.distance});

  @override
  _DetailMuseumPageState createState() => _DetailMuseumPageState();
}

class _DetailMuseumPageState extends State<DetailMuseumPage> {
  late Future<List<Artwork>> _artworksFuture;

  @override
  void initState() {
    super.initState();
    _artworksFuture =
        MuseumService().fetchArtworksByMuseum(widget.museum.officialId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.museum.title)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: widget.museum.toImage()),
              const SizedBox(height: 16),
              Text(widget.museum.title,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("${widget.museum.city}, ${widget.museum.departement}",
                  style: const TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on),
                  const SizedBox(width: 8),
                  Text("${(widget.distance / 1000).toStringAsFixed(2)} km away",
                      style: const TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 16),
              Text("Histoire: ${widget.museum.histoire}",
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              Text("Place: ${widget.museum.place}",
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),

              // Section des tableaux du musée
              const Text("Voici un aperçu de ce que vous pourrez découvrir :",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              FutureBuilder<List<Artwork>>(
                future: _artworksFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                        child: Text("Error loading artworks: ${snapshot.error}",
                            style: const TextStyle(color: Colors.red)));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text("No artworks found in this museum."));
                  }

                  // Mélange la liste et prend les 6 premiers éléments (ou moins si < 6)
                  final artworks = snapshot.data!;
                  final random = Random();
                  artworks.shuffle(random); // Mélange aléatoirement la liste
                  final displayedArtworks =
                      artworks.take(6).toList(); // Prend les 6 premiers

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: displayedArtworks.length,
                    itemBuilder: (context, index) {
                      final artwork = displayedArtworks[index];

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetailArtworkPage(artwork: artwork),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: artwork.toImage(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(artwork.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
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
