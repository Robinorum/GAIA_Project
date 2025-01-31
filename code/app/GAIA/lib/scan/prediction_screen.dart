import 'package:flutter/material.dart';
import 'dart:io';
import 'package:GAIA/model/artwork.dart';

class PredictionScreen extends StatefulWidget {
  final String imagePath;
  final Map<String, dynamic> artworkData;

  const PredictionScreen({required this.imagePath, required this.artworkData, Key? key}) : super(key: key);

  @override
  _PredictionScreenState createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  late Artwork _artwork;

  @override
  void initState() {
    super.initState();
    _initializeArtwork();
  }

  void _initializeArtwork() {
    _artwork = Artwork.fromJson(widget.artworkData);
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Prédiction')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image scannée
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _artwork.toImage(), // Utilisation de la méthode toImage()
              ),
            ),
          ),
            
            // Affichage des informations de l'œuvre
            Text(
              'Titre: ${_artwork.title}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Artiste: ${_artwork.artist}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Année: ${_artwork.date}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              _artwork.description,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
