class Quizz {
  final String question;
  final String reponseA;
  final String reponseB;
  final String reponseC;
  final String reponseD;
  final String bonneLettre;

  Quizz({
    required this.question,
    required this.reponseA,
    required this.reponseB,
    required this.reponseC,
    required this.reponseD,
    required this.bonneLettre,
  });

  factory Quizz.fromJson(Map<String, dynamic> json) {
    return Quizz(
      question: json['question'],
      reponseA: json['reponseA'],
      reponseB: json['reponseB'],
      reponseC: json['reponseC'],
      reponseD: json['reponseD'],
      bonneLettre: json['bonneLettre'],
    );
  }
}
