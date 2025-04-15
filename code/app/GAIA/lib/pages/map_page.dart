import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
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
  List<Museum> _allMuseums = [];
  List<Museum> _museums = [];

  final MuseumService _museumService = MuseumService();
  StreamSubscription<Position>? _positionStreamSubscription;
  final MapController _mapController = MapController();
  double _markerSize = 40; // Default size for markers

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _loadAllMuseums(); // Renommé
    _mapController.mapEventStream.listen(_onMapMove);
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAllMuseums() async {
    try {
      final museums =
          await _museumService.fetchMuseums(); // 1 seul appel Firebase ici
      setState(() {
        _allMuseums = museums;
      });

      final bounds = _mapController.bounds;
      if (bounds != null) {
        _loadMuseumsInBounds(bounds);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur chargement musées initiaux : $e")),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadMuseumsInBounds(LatLngBounds bounds) async {
    try {
      final visibleMuseums = _allMuseums.where((museum) {
        final point =
            LatLng(museum.location.latitude, museum.location.longitude);
        return bounds.contains(point);
      }).toList();

      setState(() {
        _museums = visibleMuseums;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur filtrage musées dans la zone : $e")),
      );
    }
  }

  Timer? _debounce;

  void _onMapMove(MapEvent event) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      final bounds = _mapController.bounds;
      if (bounds != null) {
        _updateMarkerSize(_mapController.zoom);
        _loadMuseumsInBounds(bounds);
      }
    });
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

  void _updateMarkerSize(double zoom) {
    // Adjust size dynamically based on zoom level
    _markerSize = (zoom * 3).clamp(20, 50); // Min 20px, Max 50px
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
                  mapController: _mapController,
                  options: MapOptions(
                    center: _currentLocation,
                    zoom: 5.0,
                    maxZoom: 17.0,
                    minZoom: 2.0,
                    interactiveFlags:
                        InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                    ),
                    MarkerClusterLayerWidget(
                      options: MarkerClusterLayerOptions(
                        maxClusterRadius: 45,
                        size: Size(50, 50),
                        fitBoundsOptions:
                            FitBoundsOptions(padding: EdgeInsets.all(50)),
                        markers: _museums.map((museum) {
                          final distance = _calculateDistance(
                            _currentLocation!,
                            LatLng(museum.location.latitude,
                                museum.location.longitude),
                          );
                          return Marker(
                            point: LatLng(museum.location.latitude,
                                museum.location.longitude),
                            width: _markerSize,
                            height: _markerSize,
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
                                message:
                                    "${museum.title}\nDistance: ${(distance / 1000).toStringAsFixed(2)} km",
                                child: Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: _markerSize,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        builder: (context, markers) {
                          return Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.5),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.red,
                                width: 3.0,
                              ),
                            ),
                            child: Text('${markers.length}'),
                          );
                        },
                      ),
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentLocation!,
                          width: _markerSize,
                          height: _markerSize,
                          builder: (ctx) => Transform.translate(
                            offset: Offset(0, -_markerSize / 2),
                            child: Icon(
                              Icons.man_rounded,
                              color: Colors.blue,
                              size: _markerSize,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }
}
