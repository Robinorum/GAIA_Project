import 'package:flutter/material.dart';
import 'package:GAIA/model/museum.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:GAIA/pages/detail_museum_page.dart';
import 'package:GAIA/widgets/museum_card.dart';

class MuseumListView extends StatelessWidget {
  final List<Museum> museums;
  final LatLng? currentLocation;

  const MuseumListView({
    required this.museums,
    required this.currentLocation,
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
    return ListView.builder(
      itemCount: museums.length,
      itemBuilder: (context, index) {
        final museum = museums[index];
        final dist = currentLocation != null
            ? _calculateDistance(
                currentLocation!,
                LatLng(museum.location.latitude, museum.location.longitude),
              )
            : 0.0;

        return MuseumCard(
          museum: museum,
          distance: dist,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailMuseumPage(
                  museum: museum,
                  distance: dist,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
