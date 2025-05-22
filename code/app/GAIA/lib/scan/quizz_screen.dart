import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gaia/model/quizz.dart';
import 'package:gaia/model/artwork.dart';
import 'package:gaia/pages/home_page.dart';
import 'package:gaia/services/user_service.dart';
import 'package:gaia/provider/user_provider.dart';

class QuizzScreen extends StatefulWidget {
  final Quizz quizz;
  final Artwork artwork;

  const QuizzScreen({super.key, required this.quizz, required this.artwork});

  @override
  State<QuizzScreen> createState() => _QuizzScreenState();
}

class _QuizzScreenState extends State<QuizzScreen> {
  String? selectedLetter;
  bool answered = false;

  List<String> get answers => [
        widget.quizz.reponseA,
        widget.quizz.reponseB,
        widget.quizz.reponseC,
        widget.quizz.reponseD,
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quizz")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: widget.artwork.toImage(),
            ),
            const SizedBox(height: 16),
            Text(
              widget.quizz.question,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...answers.asMap().entries.map((entry) {
              int index = entry.key;
              String answer = entry.value;
              String letter = ["A", "B", "C", "D"][index];
              return _buildAnswerButton(answer, letter);
            }),
            const SizedBox(height: 30),
            if (answered)
              ElevatedButton(
                onPressed: () async {
                  final user = Provider.of<UserProvider>(context, listen: false).user;

                  if (selectedLetter == widget.quizz.bonneLettre) {
                    bool success = await UserService().addArtworks(user!.id, widget.artwork.id);
                    await UserService().majQuest(user.id, widget.artwork.movement);

                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? "Oeuvre ajoutée à la collection !"
                            : "Erreur lors de l'ajout."),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }

                  Navigator.pushAndRemoveUntil(
                    // ignore: use_build_context_synchronously
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedLetter == widget.quizz.bonneLettre
                      ? Colors.green
                      : Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                child: Text(
                  selectedLetter == widget.quizz.bonneLettre
                      ? "Ajouter à la collection"
                      : "Retourner à l'accueil",
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerButton(String answer, String letter) {
    Color? color;

    if (answered) {
      if (letter == widget.quizz.bonneLettre) {
        color = Colors.green;
      } else if (letter == selectedLetter) {
        color = Colors.red;
      } else {
        color = Colors.grey[300];
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton(
        onPressed: () {
          if (answered) return; // Bloquer le clic logique, mais garder le style actif
          setState(() {
            selectedLetter = letter;
            answered = true;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(answer, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
