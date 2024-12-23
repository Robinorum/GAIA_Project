import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:GAIA/model/museum.dart';
import 'package:GAIA/services/museum_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  LatLng? _currentLocation;
  bool _loading = true;
  List<Museum> _museums = []; // Liste pour stocker les musées
  final MuseumService _museumService = MuseumService(); // Instance du service

  @override
  void initState() {
    super.initState();
    _getUserLocation(); // Obtenir la position de l'utilisateur
    _loadMuseums(); // Charger les musées dynamiquement
  }

  Future<void> _loadMuseums() async {
    try {
      final museums = await _museumService.fetchMuseums();

      setState(() {
        _museums = museums;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load museums: $e")),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
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
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error getting location: $e")),
      );
    } finally {
      setState(() {
        _loading = false;
      });
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
