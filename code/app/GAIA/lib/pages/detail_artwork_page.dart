import 'package:flutter/material.dart';
import 'package:GAIA/model/artwork.dart';
import '../services/profilage_service.dart';
import 'package:GAIA/provider/userProvider.dart';
import 'package:provider/provider.dart';
import 'package:GAIA/services/user_service.dart';

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
            Center(
              child: artwork.toImage(),
            ),
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
    ProfilageService().modifyBrands(widget.idArtwork, widget.uid);
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
