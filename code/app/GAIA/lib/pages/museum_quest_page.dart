import 'package:gaia/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:gaia/model/museum.dart';
import 'package:gaia/services/user_service.dart';
import 'package:provider/provider.dart';

class MuseumQuestPage extends StatefulWidget {
  final Museum museum;

  const MuseumQuestPage({super.key, required this.museum});

  @override
  State<MuseumQuestPage> createState() => _MuseumQuestPageState();
}class _MuseumQuestPageState extends State<MuseumQuestPage> {
  String? questImageUrl;
  bool isLoading = true;
  String? error;
  bool noQuest = false;
  bool questCompleted = false; // 👈 nouvel état

  @override
  void initState() {
    super.initState();
    _loadQuestImage();
  }

  Future<void> _loadQuestImage() async {
    try {
      final userId = Provider.of<UserProvider>(context, listen: false).user;
      final uid = userId?.id ?? "default_uid";

      final imageUrl = await UserService().initQuestMuseum(
        uid,
        widget.museum.officialId,
      );

      if (!mounted) return;

      if (imageUrl == "QUEST_ALREADY_COMPLETED") {
        setState(() {
          questCompleted = true;
          isLoading = false;
        });
      } else if (imageUrl == "NO_QUEST") {
        setState(() {
          noQuest = true;
          isLoading = false;
        });
      } else if (imageUrl.startsWith("Erreur")) {
        setState(() {
          error = imageUrl;
          isLoading = false;
        });
      } else {
        setState(() {
          questImageUrl = imageUrl;
          isLoading = false;
        });
      }
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
                : questCompleted
                    ? _buildCompletedQuestView()
                    : noQuest
                        ? _buildNoQuestView()
                        : _buildQuestView(),
      ),
    );
  }

  Widget _buildQuestView() {
    final museum = widget.museum;

    return Column(
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
    );
  }

  Widget _buildNoQuestView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            "Aucune quête disponible pour ce musée pour le moment.",
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedQuestView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 100, color: Colors.amber),
          const SizedBox(height: 20),
          const Text(
            "🎉 Félicitations ! 🎉",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            "Vous avez terminé toutes les quêtes pour ce musée !",
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
