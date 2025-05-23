import 'package:flutter/material.dart';


class Artwork {
  final String id; // Ajout de l'id
  final String title;
  final String artist;
  final String date;
  final String description;
  final String dimensions;
  final String image;
  final String idMuseum;
  final String movement;
  final String techniquesUsed;

  Artwork({
    required this.id, // Initialisation de l'id
    required this.title,
    required this.artist,
    required this.date,
    required this.description,
    required this.dimensions,
    required this.image,
    required this.idMuseum,
    required this.movement,
    required this.techniquesUsed,
  });

  factory Artwork.fromJson(Map<String, dynamic> json) {
    return Artwork(
      id: json['id'] ?? 'Unknown ID',
      title: json['title'] ?? 'Unknown Title',
      artist: json['artist'] ?? 'Unknown Artist',
      date: json['date'] ?? 'Unknown Date',
      description: json['description'] ?? 'No description',
      dimensions: json['dimensions'] ?? 'No dimensions',
      image: json['image_url'] ?? '',
      idMuseum: json['id_museum'] ?? 'Unknown idMuseum',
      movement: json['movement'] ?? 'Unknown Movement',
      techniquesUsed: json['techniques used'] ?? 'Unknown techniques', 
    );
  }


  Image toImage() {
    if (image.isEmpty) {
      return Image.asset('assets/images/placeholder_paint.png', fit: BoxFit.cover); // Image par défaut si vide
    }

    // Image depuis une URL
    return Image.network(
      image,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
      return Image.asset('assets/images/placeholder_paint.png', fit: BoxFit.cover);
      },
    );
  }
}