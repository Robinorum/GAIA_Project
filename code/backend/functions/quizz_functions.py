import re

def parse_quizz_response(text):
    lines = text.strip().split('\n')
    

    question_line = next((line for line in lines if "question" in line.lower()), "")
    question = re.sub(r"^[Qq]uestion\s*:?\s*", "", question_line).strip()

    reponses = {"A": "", "B": "", "C": "", "D": ""}
    

    for line in lines:
        match = re.match(r"^([A-D])\.\s*(.*)", line.strip())
        if match:
            lettre = match.group(1)
            contenu = match.group(2).strip()
            reponses[lettre] = contenu

    bonne_lettre_line = next((line for line in lines if line.lower().startswith("bonne réponse")), "")
    bonne_lettre = re.sub(r"^bonne réponse\s*:\s*", "", bonne_lettre_line, flags=re.IGNORECASE).strip()

    

    return {
        "question": question,
        "reponseA": reponses["A"],
        "reponseB": reponses["B"],
        "reponseC": reponses["C"],
        "reponseD": reponses["D"],
        "bonneLettre": bonne_lettre
    }
