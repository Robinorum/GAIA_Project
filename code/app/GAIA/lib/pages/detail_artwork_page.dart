import 'package:flutter/material.dart';
import 'package:GAIA/model/artwork.dart';

class DetailArtworkPage extends StatelessWidget {
  final Artwork artwork;

  const DetailArtworkPage({Key? key, required this.artwork}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(artwork.title),
        actions: [
          HeartIcon(), // Utilisation d'un HeartIcon pour gérer l'état du cœur
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: artwork.toImage(),
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
              "Year: ${artwork.date}",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              artwork.description,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class HeartIcon extends StatefulWidget {
  @override
  _HeartIconState createState() => _HeartIconState();
}

class _HeartIconState extends State<HeartIcon> {
  bool isLiked = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isLiked = !isLiked;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          isLiked ? Icons.favorite : Icons.favorite_border,
          color: isLiked ? Colors.pink : Colors.black,
          size: 35,
        ),
      ),
    );
  }
}
