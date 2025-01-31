import 'package:flutter/material.dart';
import 'package:GAIA/model/museum.dart';

class DetailMuseumPage extends StatelessWidget {
  final Museum museum;
  final double distance; // Distance calculée depuis l'accueil

  const DetailMuseumPage({Key? key, required this.museum, required this.distance}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(museum.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder Image
            Center(
              child: museum.toImage(),
            ),
            const SizedBox(height: 16),
            // Museum Name
            Text(
              museum.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Location Information
            Text(
              "${museum.city}, ${museum.country}",
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            // Distance
            Row(
              children: [
                const Icon(Icons.location_on),
                const SizedBox(width: 8),
                Text(
                  "${(distance / 1000).toStringAsFixed(2)} km away",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Museum Style
            Text(
              "Style: ${museum.style}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            // Museum Place
            Text(
              "Place: ${museum.place}",
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
