import 'package:flutter/material.dart';
import 'dart:io';
import 'package:GAIA/services/artwork_service.dart';
import 'package:GAIA/model/artwork.dart';

class PredictionScreen extends StatefulWidget {
  final String imagePath;
  final List<String> index;

  const PredictionScreen({required this.imagePath, required this.index, Key? key}) : super(key: key);

  @override
  _PredictionScreenState createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final ArtworkService _artworkService = ArtworkService();
  Artwork? _artwork;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchArtwork();
  }

  Future<void> _fetchArtwork() async {
    if (widget.index.isNotEmpty) {
      final artwork = await _artworkService.getArtworkById(widget.index[0]);
      setState(() {
        _artwork = artwork;
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
      });
    }
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
            // Affichage de l'image scannée
            Center(
              child: Image.file(
                File(widget.imagePath),
                width: 300,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            
            // Affichage en cours de chargement
            if (_loading) const Center(child: CircularProgressIndicator()),

            // Si l'œuvre est trouvée, on l'affiche
            if (_artwork != null) ...[
              Text(
                'Titre: ${_artwork!.title}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Artiste: ${_artwork!.artist}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Année: ${_artwork!.date}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Text(
                _artwork!.description,
                style: const TextStyle(fontSize: 16),
              ),
            ],
            
            // Si aucune œuvre n'est trouvée
            if (!_loading && _artwork == null)
              const Center(
                child: Text(
                  'Aucune correspondance trouvée.',
                  style: TextStyle(fontSize: 18, color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
