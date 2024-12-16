import 'package:flutter/material.dart';
import 'dart:io';

class PredictionScreen extends StatelessWidget {
  final String imagePath;
  final List<String> prediction;

  PredictionScreen({required this.imagePath, required this.prediction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prédiction'),
      ),
      body: SingleChildScrollView(
        // Pour éviter le débordement
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Affichage de l'image
              Center(
                child: Image.file(
                  File(imagePath),
                  width: 300,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 20),
              // Affichage des prédictions si disponibles
              if (prediction.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Titre: ${prediction[0]}',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Artiste: ${prediction[1]}',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              // Affichage d'un message si aucune prédiction
              if (prediction.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    'Aucune correspondance trouvée.',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
