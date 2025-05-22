from flask import Flask, request, jsonify
import firebase_admin
from firebase_admin import credentials, firestore

import os

import requests
os.environ['KMP_DUPLICATE_LIB_OK'] = 'TRUE'
from PIL import Image
import io
import faiss
import torch
from torchvision.models import efficientnet_b3, EfficientNet_B3_Weights

import random
import google.generativeai as genai

from functions.prediction_functions import crop_image_with_yolo, find_most_similar_image, get_link_with_id, get_by_url
from functions.recommandation_functions import get_user_preferences, get_artworks, get_previous_recommendations, get_user_collection, update
from functions.user_functions import get_artworks_by_ids, get_collection


#INITIALISATION DE FLASK

key = os.getenv("GEMINI_KEY")

genai.configure(api_key=key)

app = Flask(__name__)
cred = credentials.Certificate('testdb-5e14f-firebase-adminsdk-fbsvc-f98fa5131e.json')
firebase_admin.initialize_app(cred)

db = firestore.client()


# SETUP DES IAs


device = torch.device("cpu")
model = efficientnet_b3(weights=EfficientNet_B3_Weights.IMAGENET1K_V1)
model.classifier = torch.nn.Identity()
model.eval()
model.to(device)



index = faiss.read_index("AI_tools/index_joconde2.faiss")
faiss.omp_set_num_threads(1)







#MUSEUM_FUNCTIONS


@app.route("/museums", methods=["GET"])
def get_museums():
    try:
        museums_ref = db.collection('museums')
        museums = museums_ref.stream()
        
        museums_list = []
        for museum in museums:
            museum_data = museum.to_dict()
            museum_data['id'] = museum.id  # Ajouter l'ID du document
            museums_list.append(museum_data)
        
        return jsonify(museums_list)  
    except Exception as e:
        print(f"Error retrieving museums: {e}")
        return jsonify([])

@app.route("/museums/<museum_id>/artworks", methods=["GET"])
def get_artworks_by_museum(museum_id):
    try:
        artworks_ref = db.collection('artworks')
        artworks = artworks_ref.where("id_museum", "==", museum_id).stream()

        artworks_list = []
        for artwork in artworks:
            artwork_data = artwork.to_dict()
            artwork_data['id'] = artwork.id  # Ajouter l'ID du document
            artworks_list.append(artwork_data)

        print(f"Artworks list: {artworks_list}")

        return jsonify(artworks_list)
    except Exception as e:
        print(f"Error retrieving artworks: {e}")
        return jsonify([])
    


# PREDICTION_SERVICE


@app.route('/prediction', methods=['POST'])
def predict():
    if 'file' not in request.files:
        return jsonify({"error": "Aucune image envoyée"}), 400
    try:
        file = request.files['file']
        with Image.open(io.BytesIO(file.read())) as image:
            if image.mode != 'RGB':
                image = image.convert('RGB')
            cropped_image = crop_image_with_yolo(image)
            result = find_most_similar_image(cropped_image, index, model, device)
            if result:
                artwork_link = get_link_with_id(result)
                artwork_data = get_by_url(artwork_link)
                return jsonify(artwork_data)
            return jsonify({"message": "Aucune correspondance trouvée"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    

#QUIZZ_FUNCTIONS - NOT HERE ANYMORE MOUAHAHAH




#RECO_FUNCTIONS

@app.route("/users/<uid>/recommendations", methods=["PUT"])
def update_recommendations(uid):
    try:
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
        recommendations.extend([art["art"] for art in relevant_artworks[:2]])

        recommendationsid = [art["id"] for art in recommendations]
        
        new_artworks2 = [art for art in new_artworks if art["id"] not in recommendationsid]
        
        unexplored_movements = [movement for movement, score in user_preferences.items() if score <= 0.3]

        creative_artworks = [art for art in new_artworks2 if art["movement"] in unexplored_movements]

        if creative_artworks:
            creative_artwork = random.choice(creative_artworks)
            recommendations.append(creative_artwork)
        elif new_artworks2:
            random_artwork = random.choice(new_artworks2)
            recommendations.append(random_artwork)

        update(uid, previous_recommendations, recommendations)
        return {
            "success": True,
            "recommendations": [art["id"] for art in recommendations]
        }, 200
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }, 500


@app.route("/users/<uid>/recommendations", methods=["GET"])
def get_recommendations(uid):
    try:
        doc_ref = db.collection('accounts').document(uid)
        doc = doc_ref.get()

        # Vérifier si le document existe
        if doc.exists:
            print("User found:", doc.to_dict())

            data = doc.to_dict()
            collection = data.get('reco', [])
            print("Recommendations:", collection)

            # Charger les recommandations en fonction des préférences
            recommendations = []

            for artwork_id in collection:
                # Charger l'œuvre d'art à partir de la base de données (supposons qu'il existe une collection "artworks")
                artwork_ref = db.collection('artworks').document(artwork_id)
                artwork_doc = artwork_ref.get()

                if artwork_doc.exists:
                    artwork_data = artwork_doc.to_dict()
                    artwork_data["id"] = artwork_id  
                    recommendations.append(artwork_data)

            # Répondre avec les recommandations
            return jsonify({"success": True, "data": recommendations})
        else:
            return jsonify({"success": False, "message": "Utilisateur non trouvé"}), 404
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500
    


#USER_FUNCTIONS



@app.route("/users/<uid>/artworks/<artworkId>", methods=["POST"])
def add_collection(uid, artworkId):
    doc_ref = db.collection('accounts').document(uid)
    doc = doc_ref.get()
    
    if doc.exists:
        data = doc.to_dict()
        if 'collection' in data:
            collection = data['collection']
            if artworkId in collection:
                return "Already in collection", 200
            else:
                collection.append(artworkId)
            doc_ref.update({'collection': collection})
        else:
            doc_ref.update({'collection': [collection]})
        return "Artwork added successfully", 200
    return f"Document for user {uid} does not exist.", 404

@app.route("/users/<uid>/like/<artworkId>", methods=["GET"])
def get_like_state(uid, artworkId):
    doc_ref = db.collection('accounts').document(uid)
    doc = doc_ref.get()
    if doc.exists:
        data = doc.to_dict()
        brands = data.get('brands', [])
        
        if artworkId in brands:
            print("tableau liké")
            return jsonify({"result": True}), 200
    print("tableau non liké")
    return jsonify({"result": False}), 200

@app.route("/users/<uid>/like/<artworkId>", methods=["POST"])
def toggle_like(uid, artworkId):
    data = request.get_json()
    action = data.get("action")
    movement = data.get("movement")
    previous_profile = data.get("previous_profile", {})

    if action not in ["like", "dislike"]:
        return jsonify({"error": "Invalid action"}), 400

    doc_ref = db.collection('accounts').document(uid)
    doc = doc_ref.get()
    if not doc.exists:
        return jsonify({"error": "User not found"}), 404

    user_data = doc.to_dict()
    current_likes = user_data.get("brands", [])

    updated = False
    if action == "like" and artworkId not in current_likes:
        current_likes.append(artworkId)
        updated = True
    elif action == "dislike" and artworkId in current_likes:
        current_likes.remove(artworkId)
        updated = True

    if updated:
        try:
            response = requests.post(
                "http://localhost:5002/profilage",
                json={
                    "uid": uid,
                    "action": action,
                    "movement": movement,
                    "previous_profile": previous_profile
                }
            )
            response.raise_for_status()
            new_profile = response.json().get("profile")
            doc_ref.update({
                "brands": current_likes,
                "profile": new_profile
            })
        except Exception as e:
            app.logger.error(f"Error calling profiling service: {e}")
            return jsonify({"error": "Profiling failed"}), 500

    return jsonify({"likes": current_likes}), 200

@app.route("/users/<uid>/collection", methods=["GET"])
def fetch_collection(uid):
    collection_ids = get_collection(uid)
    
    if collection_ids:
        print(f"Collection for UID {uid} contains {len(collection_ids)} artworks.")
        artworks = get_artworks_by_ids(collection_ids)
        return jsonify({"success": True, "data": artworks or []}), 200

    # Même si aucune œuvre ou aucune collection
    print(f"No collection found for UID {uid}.")
    return jsonify({"success": True, "data": []}), 200

@app.route("/users/<uid>/quests", methods=["PUT"])
def update_general_quest_progress(uid):
    data = request.get_json()
    movement = data.get("movement")

    doc_ref = db.collection('accounts').document(uid)
    doc = doc_ref.get()
    
    if not doc.exists:
        return {"error": "Utilisateur non trouvé"}, 404
    
    user_data = doc.to_dict()
    
    user_quests = user_data.get('quests', {})  
    if not isinstance(user_quests, dict):  
        user_quests = {}  # Correction si c'est mal initialisé
    
    quests_data = db.collection('quests').get()
    
    for quest in quests_data:
        quest_data = quest.to_dict()
        quest_id = quest.id  

        if quest_data.get('movement') == movement or quest_data.get('movement') == "All":
            if quest_id in user_quests:
                user_quests[quest_id]['progression'] += 1  
            else:
                user_quests[quest_id] = {
                    'progression': 1,
                    'movement': quest_data.get('movement')
                }

    doc_ref.update({'quests': user_quests}) 
    return  200    
    
@app.route("/users/<uid>/quests", methods=["GET"])
def get_general_quests(uid):
    
    doc_ref = db.collection('accounts').document(uid)
    doc = doc_ref.get()
    
    if not doc.exists:
        return {"error": "Utilisateur non trouvé"}, 404
    
    user_data = doc.to_dict()
    user_quests = user_data.get('quests', {})  
    
    if not isinstance(user_quests, dict):  
        user_quests = {}  # Correction si c'est mal initialisé
    
    # Extraire uniquement quest_id et progression
    filtered_quests = [{"id": quest_id, "progression": data.get("progression", 0)} for quest_id, data in user_quests.items()]
    print(filtered_quests)
    return {"quests": filtered_quests}, 200

if __name__ == "__main__":
    app.run(debug=True, port=5001)
