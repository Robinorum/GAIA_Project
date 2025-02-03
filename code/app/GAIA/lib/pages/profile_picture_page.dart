import 'package:flutter/material.dart';

class ProfilePicturePage extends StatefulWidget {
  const ProfilePicturePage({Key? key}) : super(key: key);

  @override
  _ProfilePicturePageState createState() => _ProfilePicturePageState();
}

class _ProfilePicturePageState extends State<ProfilePicturePage> {
  late Future<List<String>> _galleryImages;

  final String profilePictureUrl = "https://i.pravatar.cc/150?img=12";

  @override
  void initState() {
    super.initState();
    _galleryImages = fetchGalleryImages();
  }

  Future<List<String>> fetchGalleryImages() async {
    await Future.delayed(const Duration(seconds: 2));

    return List.generate(24, (index) => "https://i.pravatar.cc/150?img=$index");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile Picture"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Image.network(
                  profilePictureUrl,
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.person, size: 80, color: Colors.grey),
                ),
              ),
              Positioned(
                bottom: 5,
                right: 5,
                child: GestureDetector(
                  onTap: () {},
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.edit, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.upload),
            label: const Text("Upload New Picture"),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: FutureBuilder<List<String>>(
              future: _galleryImages,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No profile pictures found."));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, // ⬅️ 4 images par ligne
                    crossAxisSpacing: 6.0,
                    mainAxisSpacing: 6.0,
                    childAspectRatio: 1, // Ratio carré
                  ),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {},
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          snapshot.data![index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: Colors.grey[300]),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
