import 'dart:convert';
import 'package:flutter/material.dart';


class Artwork {
  final String id; // Ajout de l'id
  final String title;
  final String artist;
  final String date;
  final String description;
  final String image;
  final String idMuseum;
  final String movement;

  Artwork({
    required this.id, // Initialisation de l'id
    required this.title,
    required this.artist,
    required this.date,
    required this.description,
    required this.image,
    required this.idMuseum,
    required this.movement,
  });

  factory Artwork.fromJson(Map<String, dynamic> json) {
    return Artwork(
      id: json['id'] ?? 'Unknown ID',
      title: json['title'] ?? 'Unknown Title',
      artist: json['artist'] ?? 'Unknown Artist',
      date: json['date'] ?? 'Unknown Date',
      description: json['description'] ?? 'No description',
      image: json['image'] ?? '',
      idMuseum: json['id_museum'] ?? 'Unknown idMuseum',
      movement: json['movement'] ?? 'Unknown Movement',
    );
  }

  Image toImage() {
    if (image.isEmpty) {
      return Image.asset('assets/images/placeholder.png',
          fit: BoxFit.cover); // Image par défaut si vide
    }

    try {
      final decodedBytes = base64Decode(image);
      return Image.memory(decodedBytes, fit: BoxFit.cover);
    } catch (e) {
      return Image.asset('assets/images/placeholder.png',
          fit: BoxFit.cover); // Image par défaut en cas d'erreur de décodage
    }
  }
}
