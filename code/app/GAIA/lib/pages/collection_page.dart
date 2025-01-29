import 'package:GAIA/pages/detail_artwork_page.dart';
import 'package:flutter/material.dart';
import '../services/artwork_service.dart';
import '../model/artwork.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({Key? key}) : super(key: key);

  @override
  _CollectionPageState createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  late Future<List<Artwork>> _artworks;

  @override
  void initState() {
    super.initState();
    _artworks = ArtworkService().fetchArtworks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Collection"),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<Artwork>>(
        future: _artworks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No artworks found."));
          }

          final artworks = snapshot.data!;
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: artworks.length,
            itemBuilder: (context, index) {
              final artwork = artworks[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DetailArtworkPage(artwork: artworks[index]),
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
    );
  }
}
