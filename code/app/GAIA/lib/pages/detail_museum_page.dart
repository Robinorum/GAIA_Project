import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart'; // Ajout de cette import
import '../model/artwork.dart';
import '../model/museum.dart';
import '../services/museum_service.dart';
import 'detail_artwork_page.dart';

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
              
              // Encart Contact
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.contact_phone, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        const Text(
                          "Contact",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Téléphone
                    if (widget.museum.telephone.isNotEmpty) ...[
                      InkWell(
                        onTap: () => _launchPhone(widget.museum.telephone),
                        child: Row(
                          children: [
                            Icon(Icons.phone, size: 20, color: Colors.blue.shade600),
                            const SizedBox(width: 8),
                            Text(
                              widget.museum.telephone,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue.shade700,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Site web
                    if (widget.museum.officialLink.isNotEmpty) ...[
                      InkWell(
                        onTap: () => _launchWebsite(widget.museum.officialLink),
                        child: Row(
                          children: [
                            Icon(Icons.language, size: 20, color: Colors.blue.shade600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Visiter le site web",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue.shade700,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
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
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount: displayedArtworks.length,
                    itemBuilder: (context, index) {
                      final artwork = displayedArtworks[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailArtworkPage(
                                artwork: artwork,
                              ),
                            ),
                          );
                        },
                        child: GridTile(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: artwork.toImage(),
                          ),
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

  // Nouvelle méthode pour lancer un appel téléphonique
  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Impossible d'ouvrir l'application téléphone"),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de l'ouverture du téléphone : $e"),
          ),
        );
      }
    }
  }

  // Nouvelle méthode pour lancer le site web
  Future<void> _launchWebsite(String url) async {
    // S'assurer que l'URL commence par http:// ou https://
    String formattedUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      formattedUrl = 'https://$url';
    }
    
    final Uri websiteUri = Uri.parse(formattedUrl);
    try {
      if (await canLaunchUrl(websiteUri)) {
        await launchUrl(websiteUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Impossible d'ouvrir le site web"),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de l'ouverture du site web : $e"),
          ),
        );
      }
    }
  }
}
