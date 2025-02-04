import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:GAIA/model/museum.dart';
import 'package:GAIA/services/museum_service.dart';
import 'package:GAIA/pages/detail_museum_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  LatLng? _currentLocation;
  bool _loading = true;
  List<Museum> _museums = [];
  final MuseumService _museumService = MuseumService();
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _loadMuseums();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
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
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permissions are permanently denied.");
      }

      final Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      _positionStreamSubscription =
          Geolocator.getPositionStream().listen((Position position) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
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

  double _calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
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
                    zoom: 5.0,
                    maxZoom: 17.0,
                    minZoom: 2.0,
                    interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                        // Marqueurs pour les musées avec padding: EdgeInsets.zero
                        ..._museums.map((museum) {
                          final distance = _calculateDistance(
                            _currentLocation!,
                            LatLng(museum.location.latitude, museum.location.longitude),
                          );
                          return Marker(
                            point: LatLng(museum.location.latitude, museum.location.longitude),
                            width: 40, // Taille exacte du pin pour éviter le padding
                            height: 40, // Taille exacte du pin pour éviter le padding
                            builder: (ctx) => GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailMuseumPage(
                                      museum: museum,
                                      distance: distance,
                                    ),
                                  ),
                                );
                              },
                              child: Tooltip(
                                padding: EdgeInsets.zero, // Supprime le padding du Tooltip
                                message: "${museum.title}\nDistance: ${(distance / 1000).toStringAsFixed(2)} km",
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 40,
                                ),
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
