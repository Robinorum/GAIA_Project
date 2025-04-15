import 'package:flutter/material.dart';

class MuseumCompletionPage extends StatefulWidget {
  final List<Map<String, dynamic>> visitedMuseums;

  const MuseumCompletionPage({super.key, required this.visitedMuseums});

  @override
  _MuseumCompletionPageState createState() => _MuseumCompletionPageState();
}

class _MuseumCompletionPageState extends State<MuseumCompletionPage> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredMuseums = widget.visitedMuseums
        .where((museum) =>
            museum["name"].toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Museum Completion"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search museum...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),

          // Liste des musées
          Expanded(
            child: ListView.builder(
              itemCount: filteredMuseums.length,
              itemBuilder: (context, index) {
                final museum = filteredMuseums[index];
                double progress = museum["collected"] / museum["total"];

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  child: ListTile(
                    title: Text("${museum['name']} - ${museum['city']}"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[300],
                          color: Colors.amber,
                        ),
                        Text(
                            "${museum['collected']}/${museum['total']} collected"),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
