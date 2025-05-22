import 'package:flutter/material.dart';
import 'package:gaia/model/artwork.dart';
import 'package:gaia/model/museum.dart';
import 'package:gaia/services/artwork_service.dart';
import 'package:gaia/services/profilage_service.dart';
import 'package:gaia/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:gaia/services/user_service.dart';
import 'package:gaia/pages/detail_museum_page.dart';

class DetailArtworkPage extends StatelessWidget {
  final Artwork artwork;

  const DetailArtworkPage({super.key, required this.artwork});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final uid = user?.id ?? "default_uid";
    final idArtwork = artwork.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(artwork.title),
        actions: [
          HeartIcon(
            artwork: artwork,
            idArtwork: idArtwork,
            uid: uid,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: artwork.toImage()),
            const SizedBox(height: 16),
            Text(
              artwork.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Artist: ${artwork.artist}",
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              "Year: ${artwork.date}",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              artwork.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),

            /// ----- Section Musée -----
            FutureBuilder<Museum?>(
              future: ArtworkService().getMuseumById(artwork.idMuseum),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text(
                    "Erreur lors du chargement du musée : ${snapshot.error}",
                    style: const TextStyle(color: Colors.red),
                  );
                } else if (!snapshot.hasData || snapshot.data == null) {
                  return const Text("Musée inconnu.");
                }

                final museum = snapshot.data!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 40),
                    const Text(
                      "Exposé à :",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailMuseumPage(
                              museum: museum,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(child: museum.toImage()),
                            const SizedBox(height: 12),
                            Text(
                              museum.title,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "${museum.city}, ${museum.departement}",
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class HeartIcon extends StatefulWidget {
  final Artwork artwork;
  final String idArtwork;
  final String uid;

  const HeartIcon({
    super.key,
    required this.artwork,
    required this.idArtwork,
    required this.uid,
  });

  @override
  // ignore: library_private_types_in_public_api
  _HeartIconState createState() => _HeartIconState();
}

class _HeartIconState extends State<HeartIcon> {
  late Future<bool> isLikedFuture;
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    isLikedFuture = fetchLikeStatus();
  }

  Future<bool> fetchLikeStatus() async {
    bool liked =
        await UserService().fetchStateBrand(widget.uid, widget.idArtwork);
    setState(() {
      isLiked = liked;
    });
    return liked;
  }

  void toggleLike() {
    setState(() {
      isLiked = !isLiked;
    });

    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (isLiked) {
      ProfilageService().modifyBrands(widget.artwork, user!, "like");
    } else {
      ProfilageService().modifyBrands(widget.artwork, user!, "dislike");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isLikedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        return GestureDetector(
          onTap: toggleLike,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Colors.pink : Colors.black,
              size: 35,
            ),
          ),
        );
      },
    );
  }
}
