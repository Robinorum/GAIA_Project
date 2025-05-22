import re
from flask import jsonify, Flask, request
import os
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()

key = os.getenv("GEMINI_KEY")

genai.configure(api_key=key)


app = Flask(__name__)



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




@app.route('/generate', methods=["POST"])
def create_quizz():
    try:

        artwork = request.get_json()

        title = artwork.get("title")
        artist = artwork.get("artist")
        description = artwork.get("description")
        date = artwork.get("date")
        movement = artwork.get("movement")
        techniques_used = artwork.get("techniques used")
        

        prompt = f"""J'aimerai que tu me gènères une question à choix multiples sur un tableau d'art. Je veux 4 choix de réponse, avec une seule bonne réponse à chaque fois Pour t'aider à generer les questions,

        Titre du tableau : {title}
        Description du tableau : {description}
        Peintre : {artist}
        Date : {date}
        Mouvement du tableau : {movement}
        Techniques utilisés : {techniques_used}

        Je veux que tu te base principalement sur la description, si il n'y a pas assez d'informations, utilise autre chose. N'hesite pas a user de tes connaissances, par exemple si le tableau parle d'un personnage connu.

        J'aimerai que tu me gènères ça sous cette forme. Je veux EXACTEMENT cette forme, sans phrase avant comme "voici la question généré...":

        EXEMPLE :

        Question : Question de base 

        A. Reponse A
        B. Reponse B
        C. Reponse C
        D. Reponse D

        Bonne réponse : lettre de la bonne réponse

        """

        model = genai.GenerativeModel('gemini-2.0-flash')
        response = model.generate_content(prompt)
        print("Réponse de Gemini :", response.text)

        parsed = parse_quizz_response(response.text)
        return jsonify(parsed)

    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }, 500
    
if __name__ == "__main__":
    app.run(debug=True, port=5003)

