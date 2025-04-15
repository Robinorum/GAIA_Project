import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:GAIA/model/museum.dart';
import 'package:GAIA/services/museum_service.dart';
import '../widgets/museum_list_view.dart';
import '../widgets/museum_map_view.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  bool _loading = true;
  LatLng? _currentLocation;
  List<Museum> _museums = [];
  List<Museum> _visibleMuseumsOnMap = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showMap = false;

  final MuseumService _museumService = MuseumService();
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStreamSubscription;
  final double _markerSize = 40;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _loadMuseums();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
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

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      _positionStreamSubscription =
          Geolocator.getPositionStream().listen((position) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur localisation : $e")),
      );
    }
  }

  Future<void> _loadMuseums() async {
    try {
      final museums = await _museumService.fetchMuseums();
      setState(() {
        _museums = museums;
      });
      _filterMapMuseums();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur chargement musées : $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _filterMapMuseums() {
    final bounds = _mapController.bounds;
    final query = _searchQuery.toLowerCase();

    if (bounds == null) return;

    setState(() {
      _visibleMuseumsOnMap = _museums.where((museum) {
        final point =
            LatLng(museum.location.latitude, museum.location.longitude);
        final inBounds = bounds.contains(point);
        final match = museum.title.toLowerCase().contains(query) ||
            museum.city.toLowerCase().contains(query);
        return inBounds && match;
      }).toList();
    });
  }

  List<Museum> _filteredMuseumsForList(List<Museum> sortedMuseums) {
    if (_searchQuery.isEmpty) return sortedMuseums;

    return sortedMuseums.where((museum) {
      return museum.title.toLowerCase().contains(_searchQuery) ||
          museum.city.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
    _filterMapMuseums();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: 'Rechercher un musée...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 16.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildToggleButton(
                label: 'Liste',
                selected: !_showMap,
                onPressed: () => setState(() => _showMap = false),
              ),
              const SizedBox(width: 12),
              _buildToggleButton(
                label: 'Carte',
                selected: _showMap,
                onPressed: () => setState(() => _showMap = true),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _showMap
                    ? MuseumMapView(
                        museums: _visibleMuseumsOnMap,
                        allMuseums: _museums,
                        mapController: _mapController,
                        currentLocation: _currentLocation,
                        markerSize: _markerSize,
                        onMapMove: _filterMapMuseums,
                      )
                    : MuseumListView(
                        museums: _filteredMuseumsForList(_museums),
                        currentLocation: _currentLocation,
                      ),
          ),
        ],
      ),
    );
  }
}

Widget _buildToggleButton({
  required String label,
  required bool selected,
  required VoidCallback onPressed,
}) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: selected ? Colors.blue : Colors.transparent,
      side: const BorderSide(color: Colors.blue),
      elevation: selected ? 4 : 0,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 16,
        color: selected ? Colors.white : Colors.blue,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
