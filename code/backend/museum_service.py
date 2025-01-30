from flask import Flask, jsonify
import json
import firebase_admin
from firebase_admin import credentials, firestore

app = Flask(__name__)
cred = credentials.Certificate('logintest-3342f-firebase-adminsdk-ahw4r-a935280551.json')
firebase_admin.initialize_app(cred)

db = firestore.client()



# Chargement des données
with open("API_Tableaux/museums.json", "r") as file:
    museums = json.load(file)

@app.route("/api/museums", methods=["GET"])
def get_museums():
    try:
        db = firestore.client()
        museums_ref = db.collection('museums')
        museums = museums_ref.stream()
        
        # Conversion en liste de dictionnaires
        museums_list = []
        for museum in museums:
            museum_data = museum.to_dict()
            museum_data['id'] = museum.id  # Ajouter l'ID du document
            museums_list.append(museum_data)
        
        return jsonify(museums_list)  # Retourner en JSON
        
    except Exception as e:
        print(f"Error retrieving museums: {e}")
        return jsonify([])  # Retourner une liste vide en cas d'erreur


if __name__ == "__main__":
    app.run(debug=True, port=5004)
