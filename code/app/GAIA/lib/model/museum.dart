import 'package:flutter/material.dart';
import 'dart:convert';

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

class Museum {
  final String id; // Ajout de l'id
  final String city;
  final String country;
  final GeoPoint location;
  final String image;
  final String place;
  final String style;
  final String title;

  Museum(
      {required this.id, // Initialisation de l'id
      required this.city,
      required this.country,
      required this.location,
      required this.image,
      required this.place,
      required this.style,
      required this.title});

  factory Museum.fromJson(Map<String, dynamic> json) {
    // Utilisation de l'id passé en paramètre (clé principale)

    return Museum(
      id: json['id'],
      city: json['city'],
      country: json['country'],
      location: GeoPoint.fromJson(json['location']),
      image: json['image'],
      place: json['place'],
      style: json['style'],
      title: json['title'],
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
