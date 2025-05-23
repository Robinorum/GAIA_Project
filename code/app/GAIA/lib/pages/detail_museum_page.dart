import 'package:flutter/material.dart';
import 'package:gaia/model/museum.dart';
import 'package:gaia/model/artwork.dart';
import 'package:gaia/services/museum_service.dart';
import 'package:gaia/pages/detail_artwork_page.dart';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class DetailMuseumPage extends StatefulWidget {
  final Museum museum;

  const DetailMuseumPage({super.key, required this.museum});

  @override
  // ignore: library_private_types_in_public_api
  _DetailMuseumPageState createState() => _DetailMuseumPageState();
}

class _DetailMuseumPageState extends State<DetailMuseumPage> {
  late Future<List<Artwork>> _artworksFuture;
  double? _distance;

  @override
  void initState() {
    super.initState();
    _artworksFuture =
        MuseumService().fetchArtworksByMuseum(widget.museum.officialId);
    _getUserLocationAndDistance();
  }

  Future<void> _getUserLocationAndDistance() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final userLoc = LatLng(position.latitude, position.longitude);
      final museumLoc = LatLng(
        widget.museum.location.latitude,
        widget.museum.location.longitude,
      );

      final distance = Geolocator.distanceBetween(
        userLoc.latitude,
        userLoc.longitude,
        museumLoc.latitude,
        museumLoc.longitude,
      );

      setState(() {
        _distance = distance;
      });
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de localisation : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.museum.title)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: widget.museum.toImage()),
              const SizedBox(height: 16),
              Text(widget.museum.title,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("${widget.museum.city}, ${widget.museum.departement}",
                  style: const TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on),
                  const SizedBox(width: 8),
                  _distance != null
                      ? Text("À ${(_distance! / 1000).toStringAsFixed(2)} km",
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey))
                      : const CircularProgressIndicator(),
                ],
              ),
              const SizedBox(height: 16),
              Text("Histoire: ${widget.museum.histoire}",
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              Text("Place: ${widget.museum.place}",
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              const Text("Voici un aperçu de ce que vous pourrez découvrir :",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              FutureBuilder<List<Artwork>>(
                future: _artworksFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    debugPrint("Error loading artworks: ${snapshot.error}");

                    return const Center(
                        child: Text("Aucune oeuvre disponible pour ce musée."));
                  }

                  final artworks = snapshot.data!;
                  final random = Random();
                  artworks.shuffle(random);
                  final displayedArtworks = artworks.take(6).toList();

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: displayedArtworks.length,
                    itemBuilder: (context, index) {
                      final artwork = displayedArtworks[index];

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetailArtworkPage(artwork: artwork),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: artwork.toImage(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(artwork.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
