import 'package:flutter/material.dart';
import 'package:gaia/model/quizz.dart';
import 'package:gaia/model/artwork.dart';
import 'package:gaia/pages/home_page.dart';

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
            ElevatedButton(
              onPressed: answered
                  ? () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const HomePage()),
                        (route) => false,
                      );
                    }
                  : null,
              child: const Text("Suivant"), 
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
        if (answered) return;
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
