import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:GAIA/model/museum.dart';
import 'dart:convert'; // Pour parser le JSON

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  LatLng? _currentLocation;
  bool _loading = true;
  List<Museum> _museums = []; // Liste pour stocker les musées

  @override
  void initState() {
    super.initState();
    _loadMuseums();
    _getUserLocation();
  }

  Future<void> _loadMuseums() async {
    // Simule un chargement de données JSON
    const jsonData = '''
    {
      "data": {
        "1": {
          "city": "Paris",
          "country": "France",
          "location": {
            "latitude": 48.8606,
            "longitude": 2.3376
          },
          "place": "Louvre Museum, Paris",
          "style": "Various (Renaissance, Baroque, Classical, etc.)",
          "title": "Louvre Museum"
        },
        "10": {
          "city": "Milan",
          "country": "Italy",
          "location": {
            "latitude": 45.4642,
            "longitude": 9.17
          },
          "place": "Santa Maria delle Grazie, Milan",
          "style": "Renaissance",
          "title": "Santa Maria delle Grazie"
        },
        "2": {
          "city": "New York",
          "country": "USA",
          "location": {
            "latitude": 40.7614,
            "longitude": -73.9776
          },
          "place": "Museum of Modern Art, New York",
          "style": "Modern Art",
          "title": "Museum of Modern Art"
        }
      }
    }
    ''';

    final Map<String, dynamic> json = jsonDecode(jsonData);

    final List<Museum> museums = (json['data'] as Map<String, dynamic>)
        .entries
        .map((entry) => Museum.fromJson(entry.value, entry.key))
        .toList();

    setState(() {
      _museums = museums;
    });
  }

  Future<void> _getUserLocation() async {
    try {
      // Vérification et demande des permissions de localisation
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permissions are permanently denied.");
      }

      // Obtention de la position actuelle
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error getting location: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Location Map"),
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _currentLocation == null
              ? const Center(child: Text("Could not determine location."))
              : FlutterMap(
                  options: MapOptions(
                    center: _currentLocation,
                    zoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                    ),
                    MarkerLayer(
                      markers: [
                        // Marqueur pour l'utilisateur
                        Marker(
                          point: _currentLocation!,
                          builder: (ctx) => const Icon(
                            Icons.my_location,
                            color: Colors.blue,
                            size: 40,
                          ),
                        ),
                        // Marqueurs pour les musées
                        ..._museums.map((museum) {
                          return Marker(
                            point: LatLng(
                              museum.location.latitude,
                              museum.location.longitude,
                            ),
                            builder: (ctx) => Tooltip(
                              message: museum.title,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ],
                ),
    );
  }
}
