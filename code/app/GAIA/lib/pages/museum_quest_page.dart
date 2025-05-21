import 'package:GAIA/provider/userProvider.dart';
import 'package:flutter/material.dart';
import 'package:GAIA/model/museum.dart';
import 'package:GAIA/services/user_service.dart';
import 'package:provider/provider.dart';

class MuseumQuestPage extends StatefulWidget {
  final Museum museum;

  const MuseumQuestPage({super.key, required this.museum});

  @override
  State<MuseumQuestPage> createState() => _MuseumQuestPageState();
}

class _MuseumQuestPageState extends State<MuseumQuestPage> {
  String? questImageUrl;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadQuestImage();
  }

  Future<void> _loadQuestImage() async {
    try {
      // Récupère l'ID utilisateur depuis une méthode ou un service global
      final userId = Provider.of<UserProvider>(context, listen: false).user;
      final uid = userId?.id ?? "default_uid";



      final imageUrl = await UserService().initQuestMuseum(
        uid,
        widget.museum.officialId,
      );
      if (!mounted) return;
      setState(() {
        questImageUrl = imageUrl;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final museum = widget.museum;

    return Scaffold(
      appBar: AppBar(
        title: Text("Quête - ${museum.title}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(child: Text("Erreur : $error"))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        museum.title,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Voici votre quête actuelle :",
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      if (questImageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            questImageUrl!,
                            fit: BoxFit.cover,
                            height: 300,
                            width: double.infinity,
                          ),
                        )
                      else
                        const Text("Aucune image disponible pour cette quête."),
                    ],
                  ),
      ),
    );
  }
}
