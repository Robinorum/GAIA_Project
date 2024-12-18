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
  final String title;
  final String artist;
  final String date;
  final String description;
  final String image;
  final GeoPoint location;
  final String place;

  Artwork({
    required this.title,
    required this.artist,
    required this.date,
    required this.description,
    required this.image,
    required this.location,
    required this.place,
  });

  factory Artwork.fromJson(Map<String, dynamic> json) {
    return Artwork(
      title: json['title'],
      artist: json['artist'],
      date: json['date'],
      description: json['description'],
      image: json['image']['bytes'],
      location: GeoPoint.fromJson(json['location']),
      place: json['place'],
    );
  }

  Image toImage() {
    final decodedBytes = base64Decode(image);
    return Image.memory(decodedBytes, fit: BoxFit.cover);
  }
}
