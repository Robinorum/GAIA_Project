import 'dart:convert';
import 'package:flutter/material.dart';

class GeoPoint {
  final double latitude;
  final double longitude;

  GeoPoint({required this.latitude, required this.longitude});

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    return GeoPoint(
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }
}

class Artwork {
  final String id; // Ajout de l'id
  final String title;
  final String artist;
  final String date;
  final String description;
  final String image;
  final GeoPoint location;
  final String place;
  final String movement;

  Artwork({
    required this.id, // Initialisation de l'id
    required this.title,
    required this.artist,
    required this.date,
    required this.description,
    required this.image,
    required this.location,
    required this.place,
    required this.movement,
  });

  factory Artwork.fromJson(Map<String, dynamic> json) {
    return Artwork(
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      date: json['date'],
      description: json['description'],
      image: json['image'] ?? '',
      location: GeoPoint.fromJson(json['location']),
      place: json['place'],
      movement: json['movement'],
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
