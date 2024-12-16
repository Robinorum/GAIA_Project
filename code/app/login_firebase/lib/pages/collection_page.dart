import 'package:flutter/material.dart';
import 'package:login_firebase/model/artwork.dart';
import 'package:login_firebase/pages/detail_page.dart';

class CollectionPage extends StatelessWidget {
  CollectionPage({Key? key}) : super(key: key);
  final List<Artwork> artworks = [
    Artwork(
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/e/ec/Mona_Lisa%2C_by_Leonardo_da_Vinci%2C_from_C2RMF_retouched.jpg',
      title: "Mona Lisa",
      artist: "Leonardo da Vinci",
      year: 1503,
      description:
          "A portrait painting by Leonardo da Vinci, one of the most famous works of art in the world.",
    ),
    Artwork(
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/4/4c/Vincent_van_Gogh_-_Self-Portrait_-_Google_Art_Project_%28454045%29.jpg',
      title: "Self Portrait",
      artist: "Vincent van Gogh",
      year: 1889,
      description:
          "A self-portrait by the Dutch painter Vincent van Gogh, showcasing his unique style.",
    ),
    Artwork(
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/9/94/Starry_Night_Over_the_Rhone.jpg',
      title: "Starry Night Over the Rhone",
      artist: "Vincent van Gogh",
      year: 1888,
      description:
          "A famous oil painting by Vincent van Gogh depicting the Rhône River at night.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Collection"), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          itemCount: artworks.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailPage(artwork: artworks[index]),
                  ),
                );
              },
              child: GridTile(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    artworks[index].imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
