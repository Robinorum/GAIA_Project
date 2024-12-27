import sys
import os


import firebase_admin
from firebase_admin import credentials, firestore, auth 
from collections import Counter

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../AI_scan')))

from flask import Flask, request, jsonify
import json
from flask_cors import CORS
from PIL import Image
import io
import torch
from torchvision import models
from torchvision.models import ResNet18_Weights
import faiss
import clip
import pickle
import os
import subprocess
cred = credentials.Certificate('logintest-3342f-firebase-adminsdk-ahw4r-a935280551.json')
firebase_admin.initialize_app(cred)

# Import des fonctions de recherche
from AI_scan.recherche import find_most_similar_image

def configure_adb_reverse():
    try:
        subprocess.run(["adb", "reverse", "tcp:5000", "tcp:5000"], check=True)
        print("Configuration adb reverse réussie : port 5000 redirigé.")
    except subprocess.CalledProcessError:
        print("Erreur lors de la configuration d'adb reverse")
    except FileNotFoundError:
        print("ADB n'est pas installé ou accessible dans le PATH.")

# Configuration de l'environnement pour éviter les problèmes liés à faiss
os.environ["KMP_DUPLICATE_LIB_OK"] = "TRUE"

# Initialisation de l'application Flask
app = Flask(__name__)
CORS(app)

# Configuration du modèle et de l'appareil
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model, preprocess = clip.load("ViT-B/32", device=device)
model.eval()

# Chargement de l'index FAISS
index = faiss.read_index("AI_scan/index.faiss")

# Chargement des métadonnées (titres et artistes)
with open("AI_scan/titles_artists.pkl", "rb") as f:
    titles, artists = pickle.load(f)

@app.route('/predict', methods=['POST'])
def predict():
    if 'file' not in request.files:
        return jsonify({"error": "Aucune image envoyée"}), 400

    # Récupération et préparation de l'image envoyée
    file = request.files['file']
    image = Image.open(io.BytesIO(file.read())).convert("RGB")

    # Recherche des images similaires
    similar_images = find_most_similar_image(image, index, titles, artists, model, device, k=1)

    # Renvoie la réponse avec les informations de l'image la plus proche
    result = {
        "prediction": similar_images[0] if similar_images else {"error": "Aucune image similaire trouvee"}
    }
    return jsonify(result)


with open("API_tableaux/artworks.json", "r") as file:
    artworks = json.load(file)

@app.route("/api/artworks", methods=["GET"])
def get_artworks():
    # Transmettre directement les données en base64
    for key, artwork in artworks.items():
        if isinstance(artwork["image"], str):
            # Charger l'objet JSON dans le champ image
            artwork["image"] = json.loads(artwork["image"])
    return jsonify({"success": True, "data": artworks})

@app.route("/api/artworks/<id>", methods=["GET"])
def get_artwork_by_id(id):
    # Récupérer une œuvre par son ID
    if id in artworks:
        artwork = artworks[id]
        if isinstance(artwork["image"], str):
            # Charger l'objet JSON dans le champ image
            artwork["image"] = json.loads(artwork["image"])
        return jsonify({"success": True, "data": artwork})
    else:
        return jsonify({"success": False, "error": "Artwork not found"}), 404
    

with open("API_tableaux/museums.json", "r") as file:
    museums = json.load(file)

@app.route("/api/museums", methods=["GET"])
def get_museums():
    # Transmettre directement les données en base64
    return jsonify({"success": True, "data": museums})

from collections import defaultdict
from firebase_admin import firestore

@app.route("/api/profilage/", methods=["POST"])
def modify_brands_by_id():
    data = request.get_json()
    
    if 'artworkId' not in data or 'uid' not in data:
        return "Missing artworkId or uid", 400 

    artworkId = data['artworkId']
    uid = data['uid']
    
    db = firestore.client()
    doc_ref = db.collection('accounts').document(uid)
    doc = doc_ref.get()
    
    if doc.exists:
        data = doc.to_dict()
        if 'brands' in data:
            brands = data['brands']
            if artworkId in brands:
                brands.remove(artworkId)
            else:
                brands.append(artworkId)
            doc_ref.update({'brands': brands})
        else:
            doc_ref.update({'brands': [artworkId]})
        profilage(uid)
    else:
        return f"Le document pour l'utilisateur {uid} n'existe pas.", 404
    return "Brands updated successfully", 200


def profilage(uid):
    db = firestore.client()
    doc_ref = db.collection('accounts').document(uid)
    doc = doc_ref.get()

    if doc.exists:
        data = doc.to_dict()
        if 'brands' in data:
            brands = data['brands']
            movements = []

            for brand in brands:
                artwork = get_artwork_by_id(brand).get_json()  # Récupération des mouvements des œuvres
                if 'data' in artwork and 'movement' in artwork['data']:
                    movements.append(artwork['data']['movement'])

            # Comptage des occurrences de chaque mouvement
            movement_counts = Counter(movements)

            # Calcul du total des mouvements
            total_movements = len(movements)

            # Création du dictionnaire des ratios
            ratios = {movement: count / total_movements for movement, count in movement_counts.items()}

            # Mise à jour dans Firestore
            doc_ref.update({'preferences.movements': ratios})
            print(f"Ratios {ratios} mis à jour pour l'utilisateur {uid}")
        else:
            print(f"Aucune marque trouvée pour l'utilisateur {uid}")
    else:
        print(f"Le document pour l'utilisateur {uid} n'existe pas.")


@app.route("/api/registration/", methods=["POST"])
def register_user():
    data = request.get_json()

    email = data['email']
    password = data['password']
    username = data['username']

    db = firestore.client()
    users_ref = db.collection('accounts')
    email_query = users_ref.where('email', '==', email).get()

    if email_query:
        return jsonify({"error": "Cet email est déjà utilisé !"}), 400  

    if len(password) < 14 or not any(c.isupper() for c in password) or not any(c.islower() for c in password) or not any(c.isdigit() for c in password) or not any(c in '@$!%*?&' for c in password):
        return jsonify({"error": "Mot de passe trop faible. Il doit avoir au moins 14 caractères, inclure une majuscule, une minuscule, un chiffre et un caractère spécial."}), 400

    try:
        user = auth.create_user(
            email=email,
            password=password,
            display_name=username
        )

        user_data = {
            'email': email,
            'username': username,
            'googleAccount': False,
            'brands': [],
            'collection': [],
            'preferences': {
                'movement': {}
            }
        }

        user_doc = users_ref.document(user.uid)
        user_doc.set(user_data)

        return jsonify({
            "success": True,
            "message": "Utilisateur enregistré avec succès",
        }), 201
    except Exception as e:
        return jsonify({"error": f"Erreur inattendue: {str(e)}"}), 500
    
@app.route("/api/login/", methods=["POST"])
def login_user():
    data = request.get_json()

    email = data.get('email')
    password = data.get('password')

    if not email or not password:
        return jsonify({"error": "Email ou mot de passe manquant"}), 400

    try:
        user = auth.get_user_by_email(email)

        firebase_auth = firebase_admin.auth
        token = firebase_auth.create_custom_token(user.uid)
        db = firestore.client()
        user_doc = db.collection('accounts').document(user.uid).get()

        if user_doc.exists:
            user_data = user_doc.to_dict()
            return jsonify({
                "success": True,
                "message": "Connexion réussie",
            }), 200
        else:
            return jsonify({"error": "Utilisateur non trouvé dans la base de données"}), 404
    except Exception as e:
        return jsonify({"error": f"Erreur lors de la connexion : {str(e)}"}), 500




if __name__ == '__main__':
    configure_adb_reverse()
    app.run(debug=True, host='127.0.0.1')