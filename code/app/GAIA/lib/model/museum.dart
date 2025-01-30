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

class Museum {
  final String id; // Ajout de l'id
  final String city;
  final String country;
  final GeoPoint location;
  final String place;
  final String style;
  final String title;

  Museum(
      {required this.id, // Initialisation de l'id
      required this.city,
      required this.country,
      required this.location,
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
      place: json['place'],
      style: json['style'],
      title: json['title'],
    );
  }

  Image toImage() {
    return Image.asset('assets/images/placeholder.png', fit: BoxFit.cover);
  }
}
