import sys
import os


import firebase_admin
from firebase_admin import credentials, firestore, auth 
from collections import Counter
import random


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

    file = request.files['file']
    image = Image.open(io.BytesIO(file.read())).convert("RGB")

    similar_images = find_most_similar_image(image, index, titles, artists, model, device, k=1)

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
                artwork = get_artwork_by_id(brand).get_json() 
                if 'data' in artwork and 'movement' in artwork['data']:
                    movements.append(artwork['data']['movement'])

            movement_counts = Counter(movements)
            total_movements = len(movements)
            ratios = {movement: count / total_movements for movement, count in movement_counts.items()}
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
                'movements': {}
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
    
def get_user_preferences(uid):
    try:
        db = firestore.client()
        doc_ref = db.collection('accounts').document(uid)
        doc = doc_ref.get()

        if doc.exists:
            data = doc.to_dict()
            movements = data.get('preferences', {}).get('movements', {})
            for movement, score in movements.items():
                print(f"User {uid} likes {movement} with score {score}")
            return movements  # Retourne un dictionnaire des mouvements et scores
        else:
            print(f"Document for UID {uid} does not exist.")
            return {}
    except Exception as e:
        print(f"Error retrieving user preferences for UID {uid}: {e}")
        return {}

    
def get_previous_recommendations(uid):

    try:
        db = firestore.client()
        doc_ref = db.collection('accounts').document(uid)
        doc = doc_ref.get()

        if doc.exists:
            data = doc.to_dict()
            collection = data.get('previous_reco', [])
            if isinstance(collection, list):
                print(f"Previous recommendations for user {uid}: {collection}")
                return collection
            else:
                print(f"'collection' field for UID {uid} is not a list.")
                return []
        else:
            print(f"Document for UID {uid} does not exist.")
            return []
    except Exception as e:
        print(f"Error retrieving previous recommendations for UID {uid}: {e}")
        return []

def get_user_collection(uid):
    try:
        db = firestore.client()
        doc_ref = db.collection('accounts').document(uid)
        doc = doc_ref.get()

        if doc.exists:
            data = doc.to_dict()
            collection = data.get('collection', [])
            if isinstance(collection, list):
                print(f"collection for user {uid}: {collection}")
                return collection
            else:
                print(f"'collection' field for UID {uid} is not a list.")
                return []
        else:
            print(f"Document for UID {uid} does not exist.")
            return []
    except Exception as e:
        print(f"Error retrieving previous recommendations for UID {uid}: {e}")
        return []


def get_artworks():
    try:
        db = firestore.client()
        artworks_ref = db.collection('artworks')
        artworks = artworks_ref.stream()  # Récupère tous les documents de la collection

        result = []
        for artwork in artworks:
            artwork_data = artwork.to_dict()
            artwork_data['id'] = artwork.id  # Inclure l'ID du document si nécessaire
            result.append(artwork_data)

        print(f"Successfully retrieved {len(result)} artworks.")
        return result
    except Exception as e:
        print(f"Error retrieving artworks: {e}")
        return []


def maj_recommendation(uid, previous_recommendations, new_recommendations):

    # Ajouter les nouvelles recommandations aux anciennes
    updated_reco = previous_recommendations[-2:] + [art['id'] for art in new_recommendations]
    
    
    # Limiter à un nombre raisonnable de recommandations (par exemple 20)
    # plus tard on mettra 20 
    
    # Mettre à jour Firestore avec les nouvelles recommandations
    db = firestore.client()
    doc_ref = db.collection('accounts').document(uid)
    doc_ref.update({'previous_reco': updated_reco})
    
    return updated_reco


def get_recommendations():
    uid = "FG0cnXK99MNiIXSKdFOmToDVxym1"
    
    user_preferences = get_user_preferences(uid)
    previous_recommendations = get_previous_recommendations(uid)
    user_collection = get_user_collection(uid)
    artworks = get_artworks()

    new_artworks = [art for art in artworks if art["id"] not in previous_recommendations and art["id"] not in user_collection]
    
    
    scored_artworks = []
    for art in new_artworks:
        style = art["movement"]  
        score = user_preferences.get(style, 0) 
        scored_artworks.append({"art": art, "score": score})
     

    recommendations = []

    relevant_artworks = sorted(scored_artworks, key=lambda x: x["score"], reverse=True)
    recommendations.extend([art["art"] for art in relevant_artworks[:2]])  # 2 œuvres pertinentes
    print("new_artworks")
    for art in new_artworks:
        print(art["id"])
    
    print("Recommandations pertinentes")
    for art in recommendations:
        print(art["id"])

    recommendationsid = [art["id"] for art in recommendations]  # Liste des IDs des recommandations
    
    new_artworks2 = [art for art in new_artworks if art["id"] not in recommendationsid]
    
    # Recommandations créatives (exploration de nouveaux styles)
    unexplored_movements = [movement for movement, score in user_preferences.items() if score <= 0.3]
    print("Mouvements peu explorés")
    for movement in unexplored_movements:
        print(movement)
    for art in new_artworks2:
        print(art["movement"])
    creative_artworks = [art for art in new_artworks2 if art["movement"] in unexplored_movements]
    if creative_artworks:
        recommendations.append(random.choice(creative_artworks))  # 1 œuvre aléatoire d'un mouvement peu exploré

    print("new_artworks2")
    for art in new_artworks2:  
        print(art["id"])

    print("Recommandations all")
    for art in recommendations:
        print(art["id"])
        

    maj_recommendation(uid, previous_recommendations, recommendations)

    return 0

if __name__ == '__main__':
    configure_adb_reverse()
    app.run(debug=True, host='127.0.0.1')