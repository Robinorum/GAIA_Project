import 'package:flutter/material.dart';
import 'package:login_firebase/model/artwork.dart';

class DetailPage extends StatelessWidget {
  final Artwork artwork;

  const DetailPage({Key? key, required this.artwork}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(artwork.title), // Titre de l'œuvre
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(artwork.imageUrl), // Image de l'œuvre
            ),
            const SizedBox(height: 16),
            Text(
              artwork.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Artist: ${artwork.artist}",
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              "Year: ${artwork.year}",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              artwork.description, // Description de l'œuvre
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
