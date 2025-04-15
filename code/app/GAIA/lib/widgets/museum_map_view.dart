import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:GAIA/model/museum.dart';
import 'package:GAIA/pages/detail_museum_page.dart';

class MuseumMapView extends StatelessWidget {
  final List<Museum> museums;
  final List<Museum> allMuseums;
  final LatLng? currentLocation;
  final MapController mapController;
  final double markerSize;
  final VoidCallback onMapMove;

  const MuseumMapView({
    required this.museums,
    required this.allMuseums,
    required this.mapController,
    required this.currentLocation,
    required this.markerSize,
    required this.onMapMove,
    super.key,
  });

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
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              center: currentLocation,
              zoom: 5.0,
              maxZoom: 17.0,
              minZoom: 2.0,
              onPositionChanged: (pos, _) => onMapMove(),
              interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 45,
                  size: const Size(50, 50),
                  fitBoundsOptions:
                      const FitBoundsOptions(padding: EdgeInsets.all(50)),
                  markers: museums.map((museum) {
                    final point = LatLng(
                      museum.location.latitude,
                      museum.location.longitude,
                    );
                    final distance = currentLocation != null
                        ? _calculateDistance(currentLocation!, point)
                        : 0.0;

                    return Marker(
                      point: point,
                      width: markerSize,
                      height: markerSize,
                      builder: (_) => GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailMuseumPage(
                                  museum: museum, distance: distance),
                            ),
                          );
                        },
                        child: Tooltip(
                          message:
                              '${museum.title}\n${(distance / 1000).toStringAsFixed(2)} km',
                          child: Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: markerSize,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  builder: (context, markers) => Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Text('${markers.length}',
                        style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ),
              if (currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentLocation!,
                      width: markerSize,
                      height: markerSize,
                      builder: (_) => Transform.translate(
                        offset: Offset(0, -markerSize / 2),
                        child: Icon(Icons.person_pin_circle,
                            size: markerSize, color: Colors.blue),
                      ),
                    )
                  ],
                ),
            ],
          ),
          if (currentLocation != null)
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: () {
                  mapController.move(currentLocation!, 12.0);
                },
                backgroundColor: Colors.blue,
                child: const Icon(Icons.my_location),
              ),
            ),
        ],
      ),
    );
  }
}
