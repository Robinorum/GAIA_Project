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
  final String officialId;
  final String themes;
  final String city;
  final String region;
  final String departement;
  final String codePostal;
  final GeoPoint location;
  final String image;
  final String place;
  final String title;
  final String officialLink;
  final String telephone;
  final String histoire;
  final String atout;
  final String interet;

  Museum(
      {required this.id, // Initialisation de l'id
      required this.officialId,
      required this.themes,
      required this.city,
      required this.region,
      required this.departement,
      required this.codePostal,
      required this.location,
      required this.image,
      required this.place,
      required this.title,
      required this.officialLink,
      required this.telephone,
      required this.histoire,
      required this.atout,
      required this.interet});

  factory Museum.fromJson(Map<String, dynamic> json) {
    return Museum(
      id: json['id'] ?? 'Unknown',
      officialId: json['official_id'] ?? 'Unknown',
      themes: json['themes'] ?? 'Unknown',
      city: json['city'] ?? 'Unknown',
      region: json['region'],
      departement: json['departement'] ?? 'Unknown',
      codePostal: json['code_postal'] ?? 'Unknown',
      location: GeoPoint.fromJson(json['location']),
      image: json['image'] ?? '',
      place: json['place'] ?? 'Unknown',
      title: json['title'] ?? 'Unknown',
      officialLink: json['official_link'] ?? 'Unknown',
      telephone: json['telephone'] ?? 'Unknown',
      histoire: json['histoire'] ?? 'Unknown',
      atout: json['atout'] ?? 'Unknown',
      interet: json['interet'] ?? 'Unknown',
    );
  }

  // Récupère l'image via un lien URL
  Image toImage() {
    if (image.isEmpty) {
      return Image.asset('assets/images/placeholder.png', fit: BoxFit.cover); // Image par défaut si vide
    }

    // Image depuis une URL
    return Image.network(image, fit: BoxFit.cover);
  }
}
